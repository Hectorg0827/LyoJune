import Foundation

// MARK: - Auth Error Types (Centralized)
public enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case networkError
    case serverError(String)
    case invalidToken
    case userNotFound
    case emailAlreadyExists
    case weakPassword
    case validationFailed(String)
    case biometricNotAvailable
    case biometricNotEnabled
    case biometricNotEnrolled
    case biometricAuthFailed
    case sessionExpired
    case twoFactorRequired
    case accountLocked
    case registrationFailed
    case loginFailed(String)
    case tokenRefreshFailed
    case tokenInvalid
    case noRefreshToken
    case passwordResetFailed
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Network connection error"
        case .serverError(let message):
            return "Server error: \(message)"
        case .invalidToken:
            return "Invalid authentication token"
        case .userNotFound:
            return "User not found"
        case .emailAlreadyExists:
            return "Email already exists"
        case .weakPassword:
            return "Password is too weak"
        case .validationFailed(let message):
            return "Authentication validation failed: \(message)"
        case .biometricNotAvailable:
            return "Biometric authentication is not available on this device"
        case .biometricNotEnabled:
            return "Biometric authentication is not enabled"
        case .biometricNotEnrolled:
            return "No biometric data is enrolled on this device"
        case .biometricAuthFailed:
            return "Biometric authentication failed"
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .twoFactorRequired:
            return "Two-factor authentication is required"
        case .accountLocked:
            return "Account is temporarily locked. Please try again later."
        case .registrationFailed:
            return "Account registration failed"
        case .loginFailed(let message):
            return "Login failed: \(message)"
        case .tokenRefreshFailed:
            return "Token refresh failed"
        case .tokenInvalid:
            return "Authentication token is invalid"
        case .noRefreshToken:
            return "No refresh token available"
        case .passwordResetFailed:
            return "Password reset failed. Please try again."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Auth State
public enum AuthState {
    case authenticated
    case unauthenticated
    case loading
    case error(AuthError)
    
    public var isAuthenticated: Bool {
        if case .authenticated = self {
            return true
        }
        return false
    }
    
    public var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
}

// MARK: - Token Type
public enum TokenType: String {
    case accessToken = "access_token"
    case refreshToken = "refresh_token"
    case idToken = "id_token"
    
    public var keychainKey: String {
        switch self {
        case .accessToken:
            return "auth_token"
        case .refreshToken:
            return "refresh_token"
        case .idToken:
            return "id_token"
        }
    }
}
