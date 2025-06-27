import Foundation

// MARK: - Centralized Network Types

// MARK: - HTTP Method
public enum HTTPMethod: String, CaseIterable {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - API Endpoint
public struct APIEndpoint {
    public let path: String
    public let method: HTTPMethod
    public let headers: [String: String]
    public let queryParameters: [String: String]
    public let queryItems: [URLQueryItem]?
    public let body: Data?
    
    public init(
        path: String, 
        method: HTTPMethod = .GET, 
        headers: [String: String] = [:], 
        queryParameters: [String: String] = [:],
        queryItems: [URLQueryItem]? = nil,
        body: Data? = nil
    ) {
        self.path = path
        self.method = method
        self.headers = headers
        self.queryParameters = queryParameters
        self.queryItems = queryItems
        self.body = body
    }
    
    // Convenience static methods
    public static func GET(_ path: String, parameters: [String: String] = [:]) -> APIEndpoint {
        return APIEndpoint(path: path, method: .GET, queryParameters: parameters)
    }
    
    public static func POST(_ path: String, body: Data? = nil) -> APIEndpoint {
        return APIEndpoint(path: path, method: .POST, body: body)
    }
    
    public static func PUT(_ path: String, body: Data? = nil) -> APIEndpoint {
        return APIEndpoint(path: path, method: .PUT, body: body)
    }
    
    public static func DELETE(_ path: String) -> APIEndpoint {
        return APIEndpoint(path: path, method: .DELETE)
    }
}