
import Foundation

// MARK: - HTTP Method
public enum HTTPMethod: String, CaseIterable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

// MARK: - API Errors
public enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError
    case decodingError
    case encodingError
    case mockDataNotFound
    case unauthorized
    case serverError(Int)
    case noInternetConnection
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError:
            return "Network error occurred"
        case .decodingError:
            return "Failed to decode response"
        case .encodingError:
            return "Failed to encode request"
        case .mockDataNotFound:
            return "Mock data not found"
        case .unauthorized:
            return "Unauthorized access"
        case .serverError(let code):
            return "Server error: \(code)"
        case .noInternetConnection:
            return "No internet connection"
        }
    }
}

// MARK: - API Client Protocol
public protocol APIClientProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}

// MARK: - Empty Response for Delete/Update operations
public struct EmptyResponse: Codable {}

// MARK: - Empty Request for operations without body
public struct EmptyRequest: Codable {}
