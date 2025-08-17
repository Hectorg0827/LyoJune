import Foundation

/// A structured error type that represents possible failures from API requests.
public enum APIError: Error, LocalizedError {

    /// The URL for the request was malformed or invalid.
    case invalidURL

    /// The network request failed due to an underlying connectivity issue or `URLSession` error.
    /// The associated `Error` provides more details.
    case requestFailed(Error)

    /// The server responded with a non-2xx status code that was not otherwise handled (e.g., not a 401).
    /// The associated `Int` is the HTTP status code.
    case unexpectedStatusCode(Int)

    /// The server responded with a 401 Unauthorized status code, and the subsequent token refresh attempt also failed.
    case unauthorized

    /// The server returned data that could not be decoded into the expected type.
    /// The associated `Error` provides details from the `JSONDecoder`.
    case decodingFailed(Error)

    /// The server returned a specific error message.
    case serverError(message: String)

    /// A user-facing description of the error.
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL was invalid."
        case .requestFailed(let error):
            return "The network request failed: \(error.localizedDescription)"
        case .unexpectedStatusCode(let statusCode):
            return "Received an unexpected HTTP status code: \(statusCode)."
        case .unauthorized:
            return "Unauthorized. Your session may have expired."
        case .decodingFailed:
            return "Failed to decode the server's response."
        case .serverError(let message):
            return message
        }
    }
}
