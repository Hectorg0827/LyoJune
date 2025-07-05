import Foundation

// MARK: - HTTP Method
public enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
    case PATCH
}

// MARK: - API Error
public enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(statusCode: Int, data: Data?)
    case decodingError(Error)
    case encodingError(Error)
    case networkError(Error)
    case noData
    case unauthorized
    case forbidden
    case notFound
    case serverError
    case badRequest
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL provided was invalid."
        case .requestFailed(let statusCode, let data):
            var message = "Request failed with status code \(statusCode)."
            if let data = data, let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                message += " Details: \(errorResponse.message)"
            }
            return message
        case .decodingError(let error):
            return "Failed to decode the response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode the request: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .noData:
            return "No data received from the server."
        case .unauthorized:
            return "Authentication failed. Please check your credentials."
        case .forbidden:
            return "You do not have permission to access this resource."
        case .notFound:
            return "The requested resource was not found."
        case .serverError:
            return "The server encountered an internal error. Please try again later."
        case .badRequest:
            return "The request was malformed or invalid."
        case .unknown(let error):
            return "An unknown error occurred: \(error.localizedDescription)"
        }
    }
}

// MARK: - Error Response Model (for API errors)
public struct ErrorResponse: Decodable {
    let message: String
    let code: String?
    let