import Foundation

// MARK: - Network Error Types (Centralized)
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
    case noData
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
        case .noData:
            return "No data received from server"
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

// MARK: - Authentication Error Types
public enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case tokenExpired
    case tokenInvalid
    case refreshTokenExpired
    case biometricAuthenticationFailed
    case userNotFound
    case accountLocked
    case accountDisabled
    case passwordTooWeak
    case emailNotVerified
    case twoFactorRequired
    case invalidTwoFactorCode
    case authenticationTimeout
    case logoutFailed
    case keychainError
    case unknown(Error)
    
    // Additional cases needed by EnhancedAuthService
    case passwordResetFailed
    case loginFailed
    case registrationFailed
    case noRefreshToken
    case tokenRefreshFailed
    case biometricNotAvailable
    case biometricAuthFailed
    case biometricNotEnrolled
    
    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid username or password"
        case .tokenExpired:
            return "Authentication token has expired"
        case .tokenInvalid:
            return "Invalid authentication token"
        case .refreshTokenExpired:
            return "Refresh token has expired"
        case .biometricAuthenticationFailed:
            return "Biometric authentication failed"
        case .userNotFound:
            return "User account not found"
        case .accountLocked:
            return "Account is temporarily locked"
        case .accountDisabled:
            return "Account has been disabled"
        case .passwordTooWeak:
            return "Password does not meet requirements"
        case .emailNotVerified:
            return "Email address needs to be verified"
        case .twoFactorRequired:
            return "Two-factor authentication required"
        case .invalidTwoFactorCode:
            return "Invalid two-factor authentication code"
        case .authenticationTimeout:
            return "Authentication request timed out"
        case .logoutFailed:
            return "Failed to logout properly"
        case .keychainError:
            return "Keychain access error"
        case .unknown(let error):
            return error.localizedDescription
        case .passwordResetFailed:
            return "Password reset failed"
        case .loginFailed:
            return "Login failed"
        case .registrationFailed:
            return "Registration failed"
        case .noRefreshToken:
            return "No refresh token available"
        case .tokenRefreshFailed:
            return "Token refresh failed"
        case .biometricNotAvailable:
            return "Biometric authentication not available"
        case .biometricAuthFailed:
            return "Biometric authentication failed"
        case .biometricNotEnrolled:
            return "No biometric credentials enrolled"
        }
    }
}

// MARK: - API Error Types (Centralized)
public enum APIError: Error, LocalizedError {
    case networkError(NetworkError)
    case authError(AuthError)
    case invalidResponse
    case apiDecodingError(Error)
    case apiEncodingError(Error)
    case serverError(Int, String?)
    case clientError(Int, String?)
    case rateLimitExceeded
    case serviceUnavailable
    case requestTimeout
    case unknown(Error)
    
    // Simple cases for backward compatibility
    case invalidURL
    case noInternetConnection
    case unauthorized
    
    public init(_ networkError: NetworkError) {
        self = .networkError(networkError)
    }
    
    public init(_ authError: AuthError) {
        self = .authError(authError)
    }
    
    public var errorDescription: String? {
        switch self {
        case .networkError(let networkError):
            return networkError.localizedDescription
        case .authError(let authError):
            return authError.localizedDescription
        case .invalidResponse:
            return "Invalid response from server"
        case .apiDecodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .apiEncodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return message ?? "Server error (\(code))"
        case .clientError(let code, let message):
            return message ?? "Client error (\(code))"
        case .rateLimitExceeded:
            return "Too many requests. Please try again later."
        case .serviceUnavailable:
            return "Service temporarily unavailable"
        case .requestTimeout:
            return "Request timed out"
        case .unknown(let error):
            return error.localizedDescription
        case .invalidURL:
            return "Invalid URL"
        case .noInternetConnection:
            return "No internet connection"
        case .unauthorized:
            return "Unauthorized access"
        }
    }
    
    public var isRetryable: Bool {
        switch self {
        case .networkError:
            return true
        case .serverError(let code, _):
            return code >= 500
        case .serviceUnavailable, .requestTimeout:
            return true
        default:
            return false
        }
    }
}

// MARK: - WebSocket Error
public enum WebSocketError: Error, LocalizedError {
    case connectionFailed
    case connectionLost
    case invalidMessage
    case authenticationFailed
    case serverError(String)
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "WebSocket connection failed"
        case .connectionLost:
            return "WebSocket connection lost"
        case .invalidMessage:
            return "Invalid WebSocket message"
        case .authenticationFailed:
            return "WebSocket authentication failed"
        case .serverError(let message):
            return "WebSocket server error: \(message)"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Core Data Error
public enum CoreDataError: Error, LocalizedError {
    case saveError(Error)
    case fetchError(Error)
    case deleteError(Error)
    case migrationError(Error)
    case contextError(String)
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .saveError(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .fetchError(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .deleteError(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        case .migrationError(let error):
            return "Data migration failed: \(error.localizedDescription)"
        case .contextError(let message):
            return "Core Data context error: \(message)"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - AI Service Error
public enum AIError: Error, LocalizedError {
    case speechPermissionDenied
    case speechRecognitionUnavailable
    case speechRecognitionSetupFailed
    case networkError
    case processingError
    case quotaExceeded
    case modelNotAvailable
    case invalidInput
    case invalidEndpoint
    case invalidResponse
    case httpError(Int)
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .speechPermissionDenied:
            return "Speech recognition permission is required"
        case .speechRecognitionUnavailable:
            return "Speech recognition is not available"
        case .speechRecognitionSetupFailed:
            return "Failed to setup speech recognition"
        case .networkError:
            return "Network connection required"
        case .processingError:
            return "Failed to process request"
        case .quotaExceeded:
            return "API quota exceeded"
        case .modelNotAvailable:
            return "AI model is not available"
        case .invalidInput:
            return "Invalid input provided"
        case .invalidEndpoint:
            return "Invalid API endpoint"
        case .invalidResponse:
            return "Invalid API response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
