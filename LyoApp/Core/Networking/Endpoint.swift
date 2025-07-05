
import Foundation

// MARK: - Endpoint
public struct Endpoint {
    let path: String
    var method: HTTPMethod = .GET
    var body: Encodable? = nil
    var headers: [String: String] = [:]
    var queryParameters: [String: String] = [:]
    
    public init(path: String, method: HTTPMethod = .GET, body: Encodable? = nil, headers: [String: String] = [:], queryParameters: [String: String] = [:]) {
        self.path = path
        self.method = method
        self.body = body
        self.headers = headers
        self.queryParameters = queryParameters
    }

    func asURLRequest() throws -> URLRequest {
        let baseURL = ConfigurationManager.shared.apiBaseURL
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        
        // Add query parameters
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if !queryParameters.isEmpty {
            urlComponents?.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let finalURL = urlComponents?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = method.rawValue
        
        // Set default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add custom headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Add body if present
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                throw APIError.encodingError(error)
            }
        }

        return request
    }
}
