import Foundation

// MARK: - API Client Protocol
/// Protocol defining the interface for API clients
public protocol APIClientProtocol {
    func request<T: Codable>(_ endpoint: APIEndpoint, responseType: T.Type) async throws -> T
    func upload<T: Codable>(data: Data, to endpoint: APIEndpoint, responseType: T.Type) async throws -> T
    func download(from endpoint: APIEndpoint) async throws -> Data
}

// MARK: - API Endpoint
/// Represents an API endpoint with all necessary information for making requests
public struct APIEndpoint {
    public let path: String
    public let method: HTTPMethod
    public let headers: [String: String]?
    public let queryParameters: [String: String]?
    public let body: Data?
    
    public init(
        path: String,
        method: HTTPMethod = .GET,
        headers: [String: String]? = nil,
        queryParameters: [String: String]? = nil,
        body: Data? = nil
    ) {
        self.path = path
        self.method = method
        self.headers = headers
        self.queryParameters = queryParameters
        self.body = body
    }
}

// MARK: - HTTP Method
/// Enumeration of supported HTTP methods
public enum HTTPMethod: String, CaseIterable {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - Endpoint (Legacy support)
/// Legacy endpoint type for backward compatibility
public typealias Endpoint = APIEndpoint

// MARK: - Offline Request
/// Represents a request that can be stored offline and executed later
public struct OfflineRequest: Codable {
    public let id: UUID
    public let endpoint: String
    public let method: String
    public let headers: [String: String]?
    public let body: Data?
    public let timestamp: Date
    public let retryCount: Int
    
    public init(
        endpoint: String,
        method: String,
        headers: [String: String]? = nil,
        body: Data? = nil,
        retryCount: Int = 0
    ) {
        self.id = UUID()
        self.endpoint = endpoint
        self.method = method
        self.headers = headers
        self.body = body
        self.timestamp = Date()
        self.retryCount = retryCount
    }
}

// MARK: - API Endpoint Extensions
extension APIEndpoint {
    /// Create a GET endpoint
    public static func get(_ path: String, queryParameters: [String: String]? = nil) -> APIEndpoint {
        return APIEndpoint(path: path, method: .GET, queryParameters: queryParameters)
    }
    
    /// Create a POST endpoint
    public static func post(_ path: String, body: Data? = nil, headers: [String: String]? = nil) -> APIEndpoint {
        return APIEndpoint(path: path, method: .POST, headers: headers, body: body)
    }
    
    /// Create a PUT endpoint
    public static func put(_ path: String, body: Data? = nil, headers: [String: String]? = nil) -> APIEndpoint {
        return APIEndpoint(path: path, method: .PUT, headers: headers, body: body)
    }
    
    /// Create a DELETE endpoint
    public static func delete(_ path: String, headers: [String: String]? = nil) -> APIEndpoint {
        return APIEndpoint(path: path, method: .DELETE, headers: headers)
    }
}

// MARK: - Request Builder
/// Helper for building API requests
public struct APIRequestBuilder {
    private var endpoint: APIEndpoint
    
    public init(path: String, method: HTTPMethod = .GET) {
        self.endpoint = APIEndpoint(path: path, method: method)
    }
    
    public func headers(_ headers: [String: String]) -> APIRequestBuilder {
        var newBuilder = self
        newBuilder.endpoint = APIEndpoint(
            path: endpoint.path,
            method: endpoint.method,
            headers: headers,
            queryParameters: endpoint.queryParameters,
            body: endpoint.body
        )
        return newBuilder
    }
    
    public func queryParameters(_ parameters: [String: String]) -> APIRequestBuilder {
        var newBuilder = self
        newBuilder.endpoint = APIEndpoint(
            path: endpoint.path,
            method: endpoint.method,
            headers: endpoint.headers,
            queryParameters: parameters,
            body: endpoint.body
        )
        return newBuilder
    }
    
    public func body<T: Codable>(_ body: T) throws -> APIRequestBuilder {
        var newBuilder = self
        let data = try JSONEncoder().encode(body)
        newBuilder.endpoint = APIEndpoint(
            path: endpoint.path,
            method: endpoint.method,
            headers: endpoint.headers,
            queryParameters: endpoint.queryParameters,
            body: data
        )
        return newBuilder
    }
    
    public func build() -> APIEndpoint {
        return endpoint
    }
}
