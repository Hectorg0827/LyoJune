import Foundation
import Network
import Combine
import UIKit

/// Enhanced Network Manager for Phase 3 with real backend integration
class EnhancedNetworkManager: NSObject, ObservableObject {
    static let shared = EnhancedNetworkManager()
    
    @Published var isOnline: Bool = true
    @Published var connectionType: ConnectionType = .unknown
    @Published var apiHealthStatus: APIHealthStatus = .unknown
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var cancellables = Set<AnyCancellable>()
    
    // Configuration
    private let configManager = ConfigurationManager.shared
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    // Rate limiting
    private var requestCounts: [String: Int] = [:]
    private var requestTimestamps: [String: Date] = [:]
    private let rateLimitWindow: TimeInterval = 60 // 1 minute
    private let maxRequestsPerWindow = 100
    
    override init() {
        // Setup URLSession configuration
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.httpMaximumConnectionsPerHost = 5
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        // Add custom headers
        config.httpAdditionalHeaders = [
            "User-Agent": "LyoApp/\(Bundle.main.appVersion) iOS/\(UIDevice.current.systemVersion)",
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        
        self.session = URLSession(configuration: config)
        
        // Setup JSON coders
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        super.init()
        
        setupNetworkMonitoring()
        checkAPIHealth()
    }
    
    deinit {
        monitor.cancel()
        cancellables.removeAll()
    }
    
    // MARK: - Network Monitoring
    
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(from: path) ?? .unknown
                
                if path.status == .satisfied {
                    self?.checkAPIHealth()
                }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    private func getConnectionType(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .unknown
        }
    }
    
    // MARK: - API Health Monitoring
    
    private func scheduleHealthCheck() {
        Timer.publish(every: 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkAPIHealth()
            }
            .store(in: &cancellables)
    }
    
    private func checkAPIHealth() {
        guard isOnline else {
            apiHealthStatus = .offline
            return
        }
        
        let healthURL = URL(string: "\(configManager.backendBaseURL)/health")!
        var request = URLRequest(url: healthURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 10.0
        
        urlSession.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.apiHealthStatus = .error(error.localizedDescription)
                } else if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200...299:
                        self?.apiHealthStatus = .healthy
                    case 500...599:
                        self?.apiHealthStatus = .serverError
                    default:
                        self?.apiHealthStatus = .degraded
                    }
                }
            }
        }.resume()
    }
    
    // MARK: - Request Building
    
    func buildRequest(
        for endpoint: APIEndpoint,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        additionalHeaders: [String: String] = [:]
    ) -> URLRequest {
        let url = URL(string: "\(configManager.backendBaseURL)\(endpoint.path)")!
        var request = URLRequest(url: url)
        
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Add authentication if available
        if let token = AuthService.shared.currentToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add API key if available
        if let apiKey = configManager.string(for: .apiKey) {
            request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        }
        
        // Add additional headers
        for (key, value) in additionalHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
    
    // MARK: - Network Requests with Retry Logic
    
    func performRequest<T: Codable>(
        _ request: URLRequest,
        responseType: T.Type,
        retryCount: Int = 3
    ) -> Future<T, NetworkError> {
        return Future<T, NetworkError> { promise in
            self.performRequestWithRetry(request, responseType: responseType, retryCount: retryCount, promise: promise)
        }
    }
    
    private func performRequestWithRetry<T: Codable>(
        _ request: URLRequest,
        responseType: T.Type,
        retryCount: Int,
        promise: @escaping (Result<T, NetworkError>) -> Void
    ) {
        urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                // Handle network errors with retry logic
                if retryCount > 0 && self.shouldRetry(error: error) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.retryDelay(for: 3 - retryCount)) {
                        self.performRequestWithRetry(request, responseType: responseType, retryCount: retryCount - 1, promise: promise)
                    }
                    return
                }
                
                promise(.failure(.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                promise(.failure(.invalidResponse))
                return
            }
            
            // Handle HTTP status codes
            switch httpResponse.statusCode {
            case 200...299:
                // Success - parse response
                guard let data = data else {
                    promise(.failure(.noData))
                    return
                }
                
                do {
                    let decodedResponse = try JSONDecoder().decode(responseType, from: data)
                    promise(.success(decodedResponse))
                } catch {
                    promise(.failure(.decodingError(error)))
                }
                
            case 401:
                // Unauthorized - refresh token and retry
                AuthService.shared.refreshToken { success in
                    if success && retryCount > 0 {
                        // Update request with new token
                        var newRequest = request
                        if let token = AuthService.shared.currentToken {
                            newRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                        }
                        self.performRequestWithRetry(newRequest, responseType: responseType, retryCount: retryCount - 1, promise: promise)
                    } else {
                        promise(.failure(.unauthorized))
                    }
                }
                
            case 429:
                // Rate limited - retry with exponential backoff
                if retryCount > 0 {
                    let delay = self.retryDelay(for: 3 - retryCount) * 2 // Exponential backoff
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self.performRequestWithRetry(request, responseType: responseType, retryCount: retryCount - 1, promise: promise)
                    }
                } else {
                    promise(.failure(.rateLimited))
                }
                
            case 500...599:
                // Server error - retry with backoff
                if retryCount > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.retryDelay(for: 3 - retryCount)) {
                        self.performRequestWithRetry(request, responseType: responseType, retryCount: retryCount - 1, promise: promise)
                    }
                } else {
                    promise(.failure(.serverError(httpResponse.statusCode)))
                }
                
            default:
                promise(.failure(.httpError(httpResponse.statusCode)))
            }
        }.resume()
    }
    
    // MARK: - Retry Logic Helpers
    
    private func shouldRetry(error: Error) -> Bool {
        let nsError = error as NSError
        
        // Retry on network connectivity issues
        return nsError.domain == NSURLErrorDomain && [
            NSURLErrorTimedOut,
            NSURLErrorCannotFindHost,
            NSURLErrorCannotConnectToHost,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorNotConnectedToInternet
        ].contains(nsError.code)
    }
    
    private func retryDelay(for attempt: Int) -> TimeInterval {
        // Exponential backoff: 1s, 2s, 4s
        return pow(2.0, Double(attempt))
    }
    
    // MARK: - Upload/Download Support
    
    func uploadFile(
        to endpoint: APIEndpoint,
        fileData: Data,
        fileName: String,
        mimeType: String,
        progressHandler: @escaping (Double) -> Void = { _ in }
    ) -> Future<UploadResponse, NetworkError> {
        return Future<UploadResponse, NetworkError> { promise in
            let url = URL(string: "\(self.configManager.backendBaseURL)\(endpoint.path)")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            // Add authentication
            if let token = AuthService.shared.currentToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            // Create multipart form data
            let boundary = UUID().uuidString
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            var body = Data()
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            
            let task = self.urlSession.uploadTask(with: request, from: body) { data, response, error in
                if let error = error {
                    promise(.failure(.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200,
                      let data = data else {
                    promise(.failure(.invalidResponse))
                    return
                }
                
                do {
                    let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: data)
                    promise(.success(uploadResponse))
                } catch {
                    promise(.failure(.decodingError(error)))
                }
            }
            
            // Monitor upload progress
            task.progress.observe(\.fractionCompleted) { progress, _ in
                DispatchQueue.main.async {
                    progressHandler(progress.fractionCompleted)
                }
            }
            
            task.resume()
        }
    }
}

// MARK: - URLSessionDelegate

extension EnhancedNetworkManager: URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        // Implement certificate pinning for production
        #if !DEBUG
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Add your certificate pinning logic here
        // For now, we'll use the default handling
        completionHandler(.performDefaultHandling, nil)
        #else
        // In debug mode, use default handling
        completionHandler(.performDefaultHandling, nil)
        #endif
    }
}

// MARK: - Supporting Types

enum ConnectionType {
    case wifi
    case cellular
    case ethernet
    case unknown
    
    var description: String {
        switch self {
        case .wifi: return "Wi-Fi"
        case .cellular: return "Cellular"
        case .ethernet: return "Ethernet"
        case .unknown: return "Unknown"
        }
    }
}

enum APIHealthStatus {
    case unknown
    case healthy
    case degraded
    case serverError
    case offline
    case error(String)
    
    var description: String {
        switch self {
        case .unknown: return "Unknown"
        case .healthy: return "Healthy"
        case .degraded: return "Degraded"
        case .serverError: return "Server Error"
        case .offline: return "Offline"
        case .error(let message): return "Error: \(message)"
        }
    }
    
    var isHealthy: Bool {
        if case .healthy = self {
            return true
        }
        return false
    }
}

// MARK: - Response Types

struct UploadResponse: Codable {
    let id: String
    let url: String
    let filename: String
    let size: Int
    let uploadedAt: Date
}
