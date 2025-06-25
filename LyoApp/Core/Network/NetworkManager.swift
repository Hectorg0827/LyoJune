import Foundation
import Combine

// MARK: - Network Error Types
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case serverError(Int)
    case networkError(Error)
    case unauthorized
    case forbidden
    case notFound
    case timeout
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let code):
            return "Server error with code: \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized access"
        case .forbidden:
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        case .timeout:
            return "Request timed out"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}

// MARK: - HTTP Methods
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - API Response
struct APIResponse<T: Codable>: Codable {
    let data: T?
    let message: String?
    let success: Bool
    let error: String?
    let code: Int?
}

// MARK: - Network Manager
@MainActor
class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    private let session: URLSession
    private let baseURL: String
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isOnline = true
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Constants.API.timeout
        config.timeoutIntervalForResource = Constants.API.timeout * 2
        config.waitsForConnectivity = true
        
        self.session = URLSession(configuration: config)
        self.baseURL = Constants.API.baseURL
        
        setupNetworkMonitoring()
    }
    
    // MARK: - Generic Request Method
    func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        headers: [String: String]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Add default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add custom headers
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add authentication if required
        if requiresAuth {
            if let token = await AuthService.shared.getAccessToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                throw NetworkError.unauthorized
            }
        }
        
        // Perform request with retry logic
        return try await performRequestWithRetry(request: request)
    }
    
    // MARK: - Request with Retry Logic
    private func performRequestWithRetry<T: Codable>(
        request: URLRequest,
        retryCount: Int = 0
    ) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown
            }
            
            // Handle HTTP status codes
            switch httpResponse.statusCode {
            case 200...299:
                break
            case 401:
                // Try to refresh token and retry once
                if retryCount == 0 {
                    try await AuthService.shared.refreshToken()
                    var newRequest = request
                    if let token = await AuthService.shared.getAccessToken() {
                        newRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                        return try await performRequestWithRetry(request: newRequest, retryCount: retryCount + 1)
                    }
                }
                throw NetworkError.unauthorized
            case 403:
                throw NetworkError.forbidden
            case 404:
                throw NetworkError.notFound
            case 500...599:
                throw NetworkError.serverError(httpResponse.statusCode)
            default:
                throw NetworkError.serverError(httpResponse.statusCode)
            }
            
            // Try to decode as APIResponse first, then fallback to direct type
            if let apiResponse = try? JSONDecoder().decode(APIResponse<T>.self, from: data) {
                if apiResponse.success, let result = apiResponse.data {
                    return result
                } else {
                    throw NetworkError.serverError(apiResponse.code ?? 500)
                }
            } else {
                // Fallback to direct decoding
                do {
                    return try JSONDecoder().decode(T.self, from: data)
                } catch {
                    throw NetworkError.decodingError(error)
                }
            }
            
        } catch let error as NetworkError {
            throw error
        } catch {
            // Retry logic for network errors
            if retryCount < Constants.API.maxRetryAttempts {
                try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(retryCount)) * 1_000_000_000))
                return try await performRequestWithRetry(request: request, retryCount: retryCount + 1)
            } else {
                throw NetworkError.networkError(error)
            }
        }
    }
    
    // MARK: - Convenience Methods
    func get<T: Codable>(endpoint: String, requiresAuth: Bool = true) async throws -> T {
        return try await request(endpoint: endpoint, method: .GET, requiresAuth: requiresAuth)
    }
    
    func post<T: Codable, U: Codable>(endpoint: String, body: U, requiresAuth: Bool = true) async throws -> T {
        let data = try JSONEncoder().encode(body)
        return try await request(endpoint: endpoint, method: .POST, body: data, requiresAuth: requiresAuth)
    }
    
    func put<T: Codable, U: Codable>(endpoint: String, body: U, requiresAuth: Bool = true) async throws -> T {
        let data = try JSONEncoder().encode(body)
        return try await request(endpoint: endpoint, method: .PUT, body: data, requiresAuth: requiresAuth)
    }
    
    func delete<T: Codable>(endpoint: String, requiresAuth: Bool = true) async throws -> T {
        return try await request(endpoint: endpoint, method: .DELETE, requiresAuth: requiresAuth)
    }
    
    // MARK: - File Upload
    func uploadFile<T: Codable>(
        endpoint: String,
        fileData: Data,
        fileName: String,
        mimeType: String,
        additionalFields: [String: String] = [:]
    ) async throws -> T {
        
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if let token = await AuthService.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        var body = Data()
        
        // Add additional fields
        for (key, value) in additionalFields {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
    
    // MARK: - Network Monitoring
    private func setupNetworkMonitoring() {
        // This would typically use Network framework for real monitoring
        // For now, we'll use a simple reachability check
        Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkNetworkStatus()
            }
            .store(in: &cancellables)
    }
    
    private func checkNetworkStatus() {
        // Simple network check - in production, use proper network monitoring
        Task {
            do {
                let url = URL(string: "https://www.google.com")!
                let (_, response) = try await URLSession.shared.data(from: url)
                if let httpResponse = response as? HTTPURLResponse {
                    await MainActor.run {
                        self.isOnline = httpResponse.statusCode == 200
                    }
                }
            } catch {
                await MainActor.run {
                    self.isOnline = false
                }
            }
        }
    }
}
