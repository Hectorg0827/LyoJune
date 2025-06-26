import Foundation

// NOTE: This file contains duplicate type definitions that have been consolidated 
// into LearningModels.swift (which is included in the build).
// These definitions are left here for reference but should not be used.

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

// MARK: - Network Connection Type
public enum NetworkConnectionType: String, Codable, CaseIterable {
    case wifi = "wifi"
    case cellular = "cellular"
    case ethernet = "ethernet"
    case none = "none"
}

// MARK: - Request/Response Types
public struct EmptyRequest: Codable {
    public init() {}
}

// MARK: - Network Errors
public enum NetworkError: Error, LocalizedError {
    case noInternetConnection
    case requestTimeout
    case serverError(statusCode: Int)
    case invalidResponse
    case decodingError(String)
    case encodingError(String)
    case invalidURL
    case unauthorizedAccess
    case rateLimitExceeded
    case networkUnavailable
    case sslError
    case networkError(String)
    case timeout
    case unauthorized
    case forbidden
    case notFound
    case custom(String)
    
    public var errorDescription: String? {
        switch self {
        case .noInternetConnection:
            return "No internet connection available"
        case .requestTimeout, .timeout:
            return "Request timed out"
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)"
        case .invalidResponse:
            return "Invalid response received"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .encodingError(let message):
            return "Failed to encode request: \(message)"
        case .invalidURL:
            return "Invalid URL"
        case .unauthorizedAccess, .unauthorized:
            return "Unauthorized access"
        case .forbidden:
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .networkUnavailable:
            return "Network unavailable"
        case .sslError:
            return "SSL connection error"
        case .networkError(let message):
            return "Network error: \(message)"
        case .custom(let message):
            return message
        }
    }
}

// MARK: - User Model (Basic)
public struct User: Codable, Identifiable, Hashable {
    public let id: String
    public let email: String
    public let firstName: String?
    public let lastName: String?
    public let username: String?
    public let profileImageURL: String?
    public let isVerified: Bool
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(
        id: String,
        email: String,
        firstName: String? = nil,
        lastName: String? = nil,
        username: String? = nil,
        profileImageURL: String? = nil,
        isVerified: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.username = username
        self.profileImageURL = profileImageURL
        self.isVerified = isVerified
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public var fullName: String {
        let components = [firstName, lastName].compactMap { $0 }
        return components.isEmpty ? (username ?? email) : components.joined(separator: " ")
    }
}

// MARK: - Service Protocols
public protocol EnhancedAPIService {
    func request<T: Codable>(_ endpoint: APIEndpoint, responseType: T.Type) async throws -> T
}

public protocol CoreDataManager: AnyObject {
    func save() throws
    func fetch<T: NSManagedObject>(_ type: T.Type) throws -> [T]
}

// Basic implementation for CoreDataManager
public class BasicCoreDataManager: CoreDataManager {
    public static let shared = BasicCoreDataManager()
    
    private init() {}
    
    public func save() throws {
        // Basic implementation - would need actual Core Data context
        print("Core Data save called")
    }
    
    public func fetch<T: NSManagedObject>(_ type: T.Type) throws -> [T] {
        // Basic implementation - would return actual entities
        return []
    }
}
