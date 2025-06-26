import Foundation

// MARK: - Network Errors
public enum NetworkError: Error, LocalizedError, Equatable {
    case invalidURL
    case noData
    case decodingError(String)
    case encodingError(String)
    case serverError(Int)
    case networkError(String)
    case unauthorized
    case forbidden
    case notFound
    case timeout
    case noInternetConnection
    case rateLimitExceeded
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL provided"
        case .noData:
            return "No data received from server"
        case .decodingError(let details):
            return "Failed to decode response: \(details)"
        case .encodingError(let details):
            return "Failed to encode request: \(details)"
        case .serverError(let code):
            return "Server error with code: \(code)"
        case .networkError(let details):
            return "Network error: \(details)"
        case .unauthorized:
            return "Unauthorized access - please login again"
        case .forbidden:
            return "Access forbidden - insufficient permissions"
        case .notFound:
            return "Requested resource not found"
        case .timeout:
            return "Request timed out - please try again"
        case .noInternetConnection:
            return "No internet connection available"
        case .rateLimitExceeded:
            return "Too many requests - please wait before trying again"
        case .unknown(let details):
            return "Unknown error occurred: \(details)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .unauthorized:
            return "Please log in again to continue"
        case .noInternetConnection:
            return "Check your internet connection and try again"
        case .timeout:
            return "Please check your connection and try again"
        case .rateLimitExceeded:
            return "Please wait a moment before making another request"
        case .serverError:
            return "Please try again later or contact support if the problem persists"
        default:
            return "Please try again"
        }
    }
    
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.noData, .noData),
             (.unauthorized, .unauthorized),
             (.forbidden, .forbidden),
             (.notFound, .notFound),
             (.timeout, .timeout),
             (.noInternetConnection, .noInternetConnection),
             (.rateLimitExceeded, .rateLimitExceeded):
            return true
        case (.decodingError(let lhsDetails), .decodingError(let rhsDetails)),
             (.encodingError(let lhsDetails), .encodingError(let rhsDetails)),
             (.networkError(let lhsDetails), .networkError(let rhsDetails)),
             (.unknown(let lhsDetails), .unknown(let rhsDetails)):
            return lhsDetails == rhsDetails
        case (.serverError(let lhsCode), .serverError(let rhsCode)):
            return lhsCode == rhsCode
        default:
            return false
        }
    }
}

// MARK: - Authentication Errors
public enum AuthError: Error, LocalizedError, Equatable {
    case invalidCredentials
    case userNotFound
    case emailAlreadyExists
    case weakPassword
    case invalidEmail
    case accountDisabled
    case tooManyAttempts
    case networkError(NetworkError)
    case tokenExpired
    case tokenInvalid
    case noRefreshToken
    case refreshTokenExpired
    case biometricNotAvailable
    case biometricNotEnrolled
    case biometricAuthFailed
    case loginFailed(String)
    case registrationFailed(String)
    case tokenRefreshFailed
    case logoutFailed
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .userNotFound:
            return "User account not found"
        case .emailAlreadyExists:
            return "An account with this email already exists"
        case .weakPassword:
            return "Password is too weak - must be at least 8 characters with letters and numbers"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .accountDisabled:
            return "Your account has been disabled"
        case .tooManyAttempts:
            return "Too many login attempts - please try again later"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .tokenExpired:
            return "Your session has expired - please log in again"
        case .tokenInvalid:
            return "Invalid authentication token"
        case .noRefreshToken:
            return "No refresh token available"
        case .refreshTokenExpired:
            return "Refresh token has expired"
        case .biometricNotAvailable:
            return "Biometric authentication is not available on this device"
        case .biometricNotEnrolled:
            return "Please set up biometric authentication in device settings"
        case .biometricAuthFailed:
            return "Biometric authentication failed"
        case .loginFailed(let details):
            return "Login failed: \(details)"
        case .registrationFailed(let details):
            return "Registration failed: \(details)"
        case .tokenRefreshFailed:
            return "Failed to refresh authentication token"
        case .logoutFailed:
            return "Failed to logout properly"
        case .unknown(let details):
            return "Authentication error: \(details)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .invalidCredentials:
            return "Please check your email and password and try again"
        case .emailAlreadyExists:
            return "Try logging in instead, or use a different email address"
        case .weakPassword:
            return "Choose a stronger password with at least 8 characters"
        case .tokenExpired, .refreshTokenExpired:
            return "Please log in again to continue"
        case .biometricNotAvailable:
            return "Use email and password to log in"
        case .biometricNotEnrolled:
            return "Set up Face ID or Touch ID in Settings, then try again"
        case .tooManyAttempts:
            return "Wait a few minutes before trying to log in again"
        default:
            return "Please try again or contact support"
        }
    }
    
    public static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidCredentials, .invalidCredentials),
             (.userNotFound, .userNotFound),
             (.emailAlreadyExists, .emailAlreadyExists),
             (.weakPassword, .weakPassword),
             (.invalidEmail, .invalidEmail),
             (.accountDisabled, .accountDisabled),
             (.tooManyAttempts, .tooManyAttempts),
             (.tokenExpired, .tokenExpired),
             (.tokenInvalid, .tokenInvalid),
             (.noRefreshToken, .noRefreshToken),
             (.refreshTokenExpired, .refreshTokenExpired),
             (.biometricNotAvailable, .biometricNotAvailable),
             (.biometricNotEnrolled, .biometricNotEnrolled),
             (.biometricAuthFailed, .biometricAuthFailed),
             (.tokenRefreshFailed, .tokenRefreshFailed),
             (.logoutFailed, .logoutFailed):
            return true
        case (.networkError(let lhsError), .networkError(let rhsError)):
            return lhsError == rhsError
        case (.loginFailed(let lhsDetails), .loginFailed(let rhsDetails)),
             (.registrationFailed(let lhsDetails), .registrationFailed(let rhsDetails)),
             (.unknown(let lhsDetails), .unknown(let rhsDetails)):
            return lhsDetails == rhsDetails
        default:
            return false
        }
    }
}

// MARK: - API Errors
public enum APIError: Error, LocalizedError, Equatable {
    case networkError(NetworkError)
    case authError(AuthError)
    case validationError([String: String])
    case serverError(Int, String?)
    case clientError(Int, String?)
    case parseError(String)
    case requestError(String)
    case responseError(String)
    case rateLimitError(retryAfter: TimeInterval?)
    case maintenanceMode
    case deprecatedAPI
    case mockDataNotFound
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return error.errorDescription
        case .authError(let error):
            return error.errorDescription
        case .validationError(let errors):
            let errorMessages = errors.values.joined(separator: ", ")
            return "Validation failed: \(errorMessages)"
        case .serverError(let code, let message):
            return message ?? "Server error (\(code))"
        case .clientError(let code, let message):
            return message ?? "Client error (\(code))"
        case .parseError(let details):
            return "Failed to parse response: \(details)"
        case .requestError(let details):
            return "Request error: \(details)"
        case .responseError(let details):
            return "Response error: \(details)"
        case .rateLimitError(let retryAfter):
            if let retry = retryAfter {
                return "Rate limit exceeded. Please wait \(Int(retry)) seconds before trying again"
            } else {
                return "Rate limit exceeded. Please try again later"
            }
        case .maintenanceMode:
            return "The app is currently under maintenance. Please try again later"
        case .deprecatedAPI:
            return "This API version is deprecated. Please update the app"
        case .mockDataNotFound:
            return "Mock data not found for this request"
        case .unknown(let details):
            return "API error: \(details)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .networkError(let error):
            return error.recoverySuggestion
        case .authError(let error):
            return error.recoverySuggestion
        case .validationError:
            return "Please check your input and try again"
        case .serverError:
            return "Please try again later or contact support"
        case .rateLimitError:
            return "Please wait before making another request"
        case .maintenanceMode:
            return "Check back in a few minutes"
        case .deprecatedAPI:
            return "Update the app to the latest version"
        default:
            return "Please try again"
        }
    }
    
    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.networkError(let lhsError), .networkError(let rhsError)):
            return lhsError == rhsError
        case (.authError(let lhsError), .authError(let rhsError)):
            return lhsError == rhsError
        case (.validationError(let lhsErrors), .validationError(let rhsErrors)):
            return lhsErrors == rhsErrors
        case (.serverError(let lhsCode, let lhsMessage), .serverError(let rhsCode, let rhsMessage)):
            return lhsCode == rhsCode && lhsMessage == rhsMessage
        case (.clientError(let lhsCode, let lhsMessage), .clientError(let rhsCode, let rhsMessage)):
            return lhsCode == rhsCode && lhsMessage == rhsMessage
        case (.parseError(let lhsDetails), .parseError(let rhsDetails)),
             (.requestError(let lhsDetails), .requestError(let rhsDetails)),
             (.responseError(let lhsDetails), .responseError(let rhsDetails)),
             (.unknown(let lhsDetails), .unknown(let rhsDetails)):
            return lhsDetails == rhsDetails
        case (.rateLimitError(let lhsRetry), .rateLimitError(let rhsRetry)):
            return lhsRetry == rhsRetry
        case (.maintenanceMode, .maintenanceMode),
             (.deprecatedAPI, .deprecatedAPI),
             (.mockDataNotFound, .mockDataNotFound):
            return true
        default:
            return false
        }
    }
}
    case unauthorized
    case noInternetConnection
    case mockDataNotFound
    
    public var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network error occurred"
        case .decodingError:
            return "Failed to decode response"
        case .invalidURL:
            return "Invalid URL"
        case .serverError(let code):
            return "Server error: \(code)"
        case .unauthorized:
            return "Unauthorized access"
        case .noInternetConnection:
            return "No internet connection"
        case .mockDataNotFound:
            return "Mock data not found"
        }
    }
}

// MARK: - Authentication Errors
public enum AuthError: Error, LocalizedError {
    case loginFailed(String)
    case registrationFailed(String)
    case tokenRefreshFailed
    case noRefreshToken
    case biometricNotAvailable
    case biometricAuthFailed
    case keychainError
    case invalidCredentials
    case userNotFound
    case accountDisabled
    
    public var errorDescription: String? {
        switch self {
        case .loginFailed(let message):
            return "Login failed: \(message)"
        case .registrationFailed(let message):
            return "Registration failed: \(message)"
        case .tokenRefreshFailed:
            return "Failed to refresh authentication token"
        case .noRefreshToken:
            return "No refresh token available"
        case .biometricNotAvailable:
            return "Biometric authentication not available"
        case .biometricAuthFailed:
            return "Biometric authentication failed"
        case .keychainError:
            return "Keychain access error"
        case .invalidCredentials:
            return "Invalid email or password"
        case .userNotFound:
            return "User account not found"
        case .accountDisabled:
            return "Account has been disabled"
        }
    }
}

// MARK: - Core Data Errors
public enum CoreDataError: Error, LocalizedError {
    case contextSaveFailed(Error)
    case fetchFailed(Error)
    case entityNotFound
    case invalidManagedObject
    case persistentStoreError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .contextSaveFailed(let error):
            return "Failed to save context: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Fetch request failed: \(error.localizedDescription)"
        case .entityNotFound:
            return "Entity not found in Core Data model"
        case .invalidManagedObject:
            return "Invalid managed object"
        case .persistentStoreError(let error):
            return "Persistent store error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Configuration Errors
public enum ConfigurationError: Error, LocalizedError {
    case missingAPIKey
    case missingBaseURL
    case invalidConfiguration
    case environmentNotSet
    
    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key not configured"
        case .missingBaseURL:
            return "Base URL not configured"
        case .invalidConfiguration:
            return "Invalid configuration"
        case .environmentNotSet:
            return "Environment not set"
        }
    }
}

// MARK: - WebSocket Errors
public enum WebSocketError: Error, LocalizedError {
    case connectionFailed
    case disconnected
    case messageEncodingFailed
    case messageDecodingFailed
    case invalidURL
    case authenticationFailed
    
    public var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "WebSocket connection failed"
        case .disconnected:
            return "WebSocket disconnected"
        case .messageEncodingFailed:
            return "Failed to encode WebSocket message"
        case .messageDecodingFailed:
            return "Failed to decode WebSocket message"
        case .invalidURL:
            return "Invalid WebSocket URL"
        case .authenticationFailed:
            return "WebSocket authentication failed"
        }
    }
}
