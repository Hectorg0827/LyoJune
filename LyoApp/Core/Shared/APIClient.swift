import Foundation
import Combine

// MARK: - Production API Client
public final class APIClient: BaseAPIClient {
    public static let shared = APIClient()
    
    private let authTokenProvider: () async -> String?
    private let configManager = ConfigurationManager.shared
    
    private override init() {
        // Get auth token from keychain
        self.authTokenProvider = {
            guard let tokenData = KeychainHelper.shared.load(for: "auth_token"),
                  let token = String(data: tokenData, encoding: .utf8) else {
                return nil
            }
            return token
        }
        
        let baseURL = ConfigurationManager.shared.backendBaseURL
        super.init(baseURL: baseURL)
    }
    
    public convenience init(authTokenProvider: @escaping () async -> String?) {
        self.init()
        // Note: Cannot reassign in convenience init, but keeping for protocol compatibility
    }
    
    // MARK: - Authenticated Requests
    
    public override func request<T: Codable>(_ endpoint: APIEndpoint, responseType: T.Type) async throws -> T {
        let authenticatedEndpoint = try await addAuthenticationIfNeeded(to: endpoint)
        return try await super.request(authenticatedEndpoint, responseType: responseType)
    }
    
    public override func performRequest<T: Codable>(_ request: URLRequest, responseType: T.Type) -> Future<T, NetworkError> {
        return Future { [weak self] promise in
            Task {
                do {
                    let authenticatedRequest = try await self?.addAuthenticationIfNeeded(to: request) ?? request
                    
                    self?.session.dataTask(with: authenticatedRequest) { data, response, error in
                        if let error = error {
                            promise(.failure(.networkError(error)))
                            return
                        }
                        
                        guard let httpResponse = response as? HTTPURLResponse else {
                            promise(.failure(.invalidResponse))
                            return
                        }
                        
                        guard 200...299 ~= httpResponse.statusCode else {
                            promise(.failure(.serverError(httpResponse.statusCode)))
                            return
                        }
                        
                        guard let data = data else {
                            promise(.failure(.noData))
                            return
                        }
                        
                        do {
                            let decoder = JSONDecoder()
                            decoder.dateDecodingStrategy = .iso8601
                            let result = try decoder.decode(T.self, from: data)
                            promise(.success(result))
                        } catch {
                            promise(.failure(.decodingError(error)))
                        }
                    }.resume()
                } catch {
                    promise(.failure(.networkError(error)))
                }
            }
        }
    }
    
    // MARK: - Authentication Helper
    
    private func addAuthenticationIfNeeded(to endpoint: APIEndpoint) async throws -> APIEndpoint {
        // Skip auth for login/register endpoints
        if endpoint.path.contains("/auth/login") || endpoint.path.contains("/auth/register") {
            return endpoint
        }
        
        guard let token = await authTokenProvider() else {
            throw NetworkError.unauthorized
        }
        
        var headers = endpoint.headers ?? [:]
        headers["Authorization"] = "Bearer \(token)"
        
        return APIEndpoint(
            path: endpoint.path,
            method: endpoint.method,
            headers: headers,
            body: endpoint.body
        )
    }
    
    private func addAuthenticationIfNeeded(to request: URLRequest) async throws -> URLRequest {
        var authenticatedRequest = request
        
        // Skip auth for login/register endpoints
        if let url = request.url, url.path.contains("/auth/login") || url.path.contains("/auth/register") {
            return request
        }
        
        guard let token = await authTokenProvider() else {
            throw NetworkError.unauthorized
        }
        
        authenticatedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return authenticatedRequest
    }
}
