import Foundation
import Network
import Combine
import UIKit

// MARK: - Enhanced Network Manager
final class EnhancedNetworkManager: NSObject, ObservableObject {
    static let shared = EnhancedNetworkManager()
    
    @Published var isConnected: Bool = true
    @Published var connectionType: NetworkConnectionType = .wifi
    
    private let session: URLSession
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var cancellables = Set<AnyCancellable>()
    
    // Configuration
    private let timeoutInterval: TimeInterval = 30
    private let maxRetryAttempts = 3
    
    override init() {
        // Configure URL session
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeoutInterval
        config.timeoutIntervalForResource = timeoutInterval * 2
        config.waitsForConnectivity = true
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        self.session = URLSession(configuration: config)
        
        super.init()
        
        startNetworkMonitoring()
    }
    
    // MARK: - Public Methods
    
    func request<T: Decodable>(endpoint: APIEndpoint, body: Data? = nil) async throws -> T {
        return try await performRequest(endpoint: endpoint, body: body, retryCount: 0)
    }
    
    func upload<T: Decodable>(endpoint: APIEndpoint, data: Data) async throws -> T {
        guard isConnected else {
            throw NetworkError.noInternetConnection
        }
        
        var request = try createURLRequest(for: endpoint)
        request.httpBody = data
        request.setValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
        
        return try await executeRequest(request)
    }
    
    func download(from url: URL, to destinationURL: URL) async throws {
        guard isConnected else {
            throw NetworkError.noInternetConnection
        }
        
        let (tempURL, response) = try await session.download(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw NetworkError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        try FileManager.default.moveItem(at: tempURL, to: destinationURL)
    }
    
    // MARK: - Private Methods
    
    private func performRequest<T: Decodable>(endpoint: APIEndpoint, body: Data?, retryCount: Int) async throws -> T {
        guard isConnected else {
            throw NetworkError.noInternetConnection
        }
        
        do {
            let request = try createURLRequest(for: endpoint, body: body)
            return try await executeRequest(request)
        } catch let error as NetworkError {
            // Retry logic for certain errors
            if shouldRetry(error: error) && retryCount < maxRetryAttempts {
                let delay = calculateRetryDelay(attempt: retryCount + 1)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await performRequest(endpoint: endpoint, body: body, retryCount: retryCount + 1)
            }
            throw error
        }
    }
    
    private func createURLRequest(for endpoint: APIEndpoint, body: Data? = nil) throws -> URLRequest {
        let config = ConfigurationManager.shared
        let baseURL = config.apiBaseURL
        
        guard let url = URL(string: baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = timeoutInterval
        
        // Set default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(Bundle.main.appVersion, forHTTPHeaderField: "X-App-Version")
        request.setValue("iOS", forHTTPHeaderField: "X-Platform")
        
        // Add authentication header if available
        if let token = KeychainHelper.shared.retrieve(for: "access_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add custom headers
        for (key, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add body if present
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
    
    private func executeRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.networkError("Invalid response type")
            }
            
            try validateResponse(httpResponse, data: data)
            
            // Handle empty responses
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
            
            // Decode response
            return try decodeResponse(data)
            
        } catch let error as NetworkError {
            throw error
        } catch {
            if error.localizedDescription.contains("The Internet connection appears to be offline") {
                throw NetworkError.noInternetConnection
            } else if error.localizedDescription.contains("timed out") {
                throw NetworkError.timeout
            } else {
                throw NetworkError.networkError(error.localizedDescription)
            }
        }
    }
    
    private func validateResponse(_ response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
        case 200...299:
            return // Success
        case 400:
            throw NetworkError.networkError("Bad Request")
        case 401:
            // Token might be expired, try to refresh
            NotificationCenter.default.post(name: .tokenExpired, object: nil)
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 429:
            let retryAfter = response.value(forHTTPHeaderField: "Retry-After")
            throw NetworkError.rateLimitExceeded
        case 500...599:
            throw NetworkError.serverError(response.statusCode)
        default:
            throw NetworkError.networkError("HTTP \(response.statusCode)")
        }
    }
    
    private func decodeResponse<T: Decodable>(_ data: Data) throws -> T {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch {
            print("❌ Decoding error: \(error)")
            print("📄 Response data: \(String(data: data, encoding: .utf8) ?? "Invalid UTF-8")")
            throw NetworkError.decodingError(error.localizedDescription)
        }
    }
    
    private func shouldRetry(error: NetworkError) -> Bool {
        switch error {
        case .timeout, .networkError, .serverError:
            return true
        default:
            return false
        }
    }
    
    private func calculateRetryDelay(attempt: Int) -> TimeInterval {
        // Exponential backoff: 1s, 2s, 4s
        return TimeInterval(pow(2.0, Double(attempt - 1)))
    }
    
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(from: path) ?? .none
            }
        }
        
        monitor.start(queue: queue)
    }
    
    private func getConnectionType(from path: NWPath) -> NetworkConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular  
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .none
        }
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - URLSessionDelegate
extension EnhancedNetworkManager: URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Handle SSL certificate validation
        completionHandler(.performDefaultHandling, nil)
    }
}

// MARK: - Supporting Types
enum NetworkConnectionType {
    case wifi
    case cellular
    case ethernet
    case none
}

// MARK: - Notification Names
extension Notification.Name {
    static let tokenExpired = Notification.Name("tokenExpired")
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}
