import Foundation

/// An enum representing HTTP methods.
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// A type that represents a single API endpoint.
public struct Endpoint<Response: Decodable> {

    /// The path component of the URL.
    let path: String

    /// The HTTP method for the request.
    let method: HTTPMethod

    /// The headers to be sent with the request.
    var headers: [String: String]?

    /// The query items to be added to the URL.
    let queryItems: [URLQueryItem]?

    /// The body of the request.
    var body: Data?

    /// Creates a new endpoint.
    /// - Parameters:
    ///   - path: The path of the endpoint, relative to the base URL.
    ///   - method: The HTTP method to use.
    ///   - headers: Optional dictionary of headers.
    ///   - queryItems: Optional array of URL query items.
    ///   - body: Optional request body as `Data`.
    public init(path: String, method: HTTPMethod, headers: [String : String]? = nil, queryItems: [URLQueryItem]? = nil, body: Data? = nil) {
        self.path = path
        self.method = method
        self.headers = headers
        self.queryItems = queryItems
        self.body = body
    }
}

// MARK: - Convenience Initializer for Encodable Body

extension Endpoint {

    /// Creates a new endpoint with an `Encodable` body.
    /// The body object will be encoded to JSON `Data`.
    /// - Parameters:
    ///   - path: The path of the endpoint.
    ///   - method: The HTTP method.
    ///   - headers: Optional headers.
    ///   - encodableBody: An `Encodable` object to use as the request body.
    ///   - encoder: The `JSONEncoder` to use for encoding. Defaults to a standard encoder.
    public init<T: Encodable>(
        path: String,
        method: HTTPMethod,
        headers: [String: String]? = ["Content-Type": "application/json"],
        encodableBody: T,
        encoder: JSONEncoder = JSONEncoder()
    ) throws {
        self.path = path
        self.method = method
        self.headers = headers
        self.body = try encoder.encode(encodableBody)
    }
}
