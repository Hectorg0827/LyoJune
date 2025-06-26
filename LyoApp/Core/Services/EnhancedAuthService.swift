import Foundation
import Combine
import LocalAuthentication
import UIKit

/// Enhanced Authentication Service for Phase 3 with real backend integration
class EnhancedAuthService: ObservableObject {
    static let shared = EnhancedAuthService()
    
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var currentUser: User?
    @Published var authError: AuthError?
    
    private let networkManager = EnhancedNetworkManager.shared
    private let configManager = ConfigurationManager.shared
    private let keychainHelper = KeychainHelper.shared
    
    private var cancellables = Set<AnyCancellable>()
    private var refreshTokenTimer: Timer?
    
    // Token management
    private(set) var currentToken: String?
    private var refreshToken: String?
    
    // Biometric authentication
    private let biometricContext = LAContext()
    
    private init() {
        loadStoredAuthentication()
        setupTokenRefreshTimer()
    }
    
    deinit {
        refreshTokenTimer?.invalidate()
    }
    
    // MARK: - Authentication State Loading
    
    private func loadStoredAuthentication() {
        isLoading = true
        
        // Load tokens from keychain
        if let tokenData = keychainHelper.load(for: "auth_token"),
           let token = String(data: tokenData, encoding: .utf8) {
            currentToken = token
            
            // Load refresh token
            if let refreshTokenData = keychainHelper.load(for: "refresh_token"),
               let refreshTokenString = String(data: refreshTokenData, encoding: .utf8) {
                refreshToken = refreshTokenString
            }
            
            // Validate token with backend
            validateCurrentToken()
        } else {
            isLoading = false
        }
    }
    
    private func validateCurrentToken() {
        guard let token = currentToken else {
            isLoading = false
            return
        }
        
        let request = networkManager.buildRequest(for: .validateToken)
        
        networkManager.performRequest(request, responseType: User.self)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        if case .unauthorized = error {
                            // Token is invalid, try to refresh
                            self?.attemptTokenRefresh()
                        } else {
                            self?.handleAuthError(.validationFailed(error.localizedDescription))
                        }
                    }
                },
                receiveValue: { [weak self] user in
                    self?.currentUser = user
                    self?.isAuthenticated = true
                    self?.isLoading = false
                    self?.authError = nil
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Authentication Methods
    
    func signIn(email: String, password: String) -> Future<User, AuthError> {
        return Future<User, AuthError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown))
                return
            }
            
            self.isLoading = true
            self.authError = nil
            
            let loginRequest = LoginRequest(email: email, password: password)
            
            guard let requestData = try? JSONEncoder().encode(loginRequest) else {
                promise(.failure(.invalidCredentials))
                self.isLoading = false
                return
            }
            
            let request = self.networkManager.buildRequest(
                for: .login,
                method: .POST,
                body: requestData
            )
            
            self.networkManager.performRequest(request, responseType: LoginResponse.self)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            let authError = self.mapNetworkErrorToAuthError(error)
                            self.handleAuthError(authError)
                            promise(.failure(authError))
                        }
                    },
                    receiveValue: { response in
                        self.handleSuccessfulAuthentication(response)
                        promise(.success(response.user))
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    func signUp(email: String, password: String, fullName: String) -> Future<User, AuthError> {
        return Future<User, AuthError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown))
                return
            }
            
            self.isLoading = true
            self.authError = nil
            
            let signUpRequest = SignUpRequest(
                email: email,
                password: password,
                fullName: fullName
            )
            
            guard let requestData = try? JSONEncoder().encode(signUpRequest) else {
                promise(.failure(.invalidCredentials))
                self.isLoading = false
                return
            }
            
            let request = self.networkManager.buildRequest(
                for: .signUp,
                method: .POST,
                body: requestData
            )
            
            self.networkManager.performRequest(request, responseType: LoginResponse.self)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            let authError = self.mapNetworkErrorToAuthError(error)
                            self.handleAuthError(authError)
                            promise(.failure(authError))
                        }
                    },
                    receiveValue: { response in
                        self.handleSuccessfulAuthentication(response)
                        promise(.success(response.user))
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    func signOut() {
        isLoading = true
        
        // Call logout endpoint
        let request = networkManager.buildRequest(for: .logout, method: .POST)
        
        networkManager.performRequest(request, responseType: LogoutResponse.self)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] _ in
                    // Always clear local auth state, even if logout fails
                    self?.clearAuthenticationState()
                },
                receiveValue: { [weak self] _ in
                    self?.clearAuthenticationState()
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Biometric Authentication
    
    func enableBiometricAuth() -> Future<Bool, AuthError> {
        return Future<Bool, AuthError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown))
                return
            }
            
            var error: NSError?
            
            // Check if biometric authentication is available
            guard self.biometricContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
                promise(.failure(.biometricNotAvailable))
                return
            }
            
            let reason = "Enable biometric authentication for secure and convenient access to your account"
            
            self.biometricContext.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            ) { success, error in
                DispatchQueue.main.async {
                    if success {
                        // Store biometric preference
                        UserDefaults.standard.set(true, forKey: "biometric_auth_enabled")
                        promise(.success(true))
                    } else {
                        promise(.failure(.biometricAuthFailed))
                    }
                }
            }
        }
    }
    
    func authenticateWithBiometrics() -> Future<Bool, AuthError> {
        return Future<Bool, AuthError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown))
                return
            }
            
            // Check if biometric auth is enabled
            guard UserDefaults.standard.bool(forKey: "biometric_auth_enabled") else {
                promise(.failure(.biometricNotEnabled))
                return
            }
            
            let reason = "Authenticate to access your Lyo account"
            
            self.biometricContext.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            ) { success, error in
                DispatchQueue.main.async {
                    if success {
                        // Load stored authentication
                        self.loadStoredAuthentication()
                        promise(.success(true))
                    } else {
                        promise(.failure(.biometricAuthFailed))
                    }
                }
            }
        }
    }
    
    // MARK: - Token Management
    
    func refreshToken(completion: @escaping (Bool) -> Void) {
        guard let refreshToken = refreshToken else {
            completion(false)
            return
        }
        
        let refreshRequest = RefreshTokenRequest(refreshToken: refreshToken)
        
        guard let requestData = try? JSONEncoder().encode(refreshRequest) else {
            completion(false)
            return
        }
        
        let request = networkManager.buildRequest(
            for: .refreshToken,
            method: .POST,
            body: requestData
        )
        
        networkManager.performRequest(request, responseType: RefreshTokenResponse.self)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completionResult in
                    if case .failure = completionResult {
                        // Refresh token is invalid, sign out user
                        self?.clearAuthenticationState()
                        completion(false)
                    }
                },
                receiveValue: { [weak self] response in
                    self?.updateTokens(
                        accessToken: response.accessToken,
                        refreshToken: response.refreshToken
                    )
                    completion(true)
                }
            )
            .store(in: &cancellables)
    }
    
    private func setupTokenRefreshTimer() {
        // Refresh token every 50 minutes (tokens typically expire in 1 hour)
        refreshTokenTimer = Timer.scheduledTimer(withTimeInterval: 3000, repeats: true) { [weak self] _ in
            if self?.isAuthenticated == true {
                self?.refreshToken { _ in }
            }
        }
    }
    
    private func attemptTokenRefresh() {
        refreshToken { [weak self] success in
            if !success {
                self?.clearAuthenticationState()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleSuccessfulAuthentication(_ response: LoginResponse) {
        currentUser = response.user
        updateTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )
        
        isAuthenticated = true
        isLoading = false
        authError = nil
        
        // Provide haptic feedback for successful authentication
        HapticManager.shared.notification(.success)
    }
    
    private func updateTokens(accessToken: String, refreshToken: String) {
        self.currentToken = accessToken
        self.refreshToken = refreshToken
        
        // Store tokens securely in keychain
        if let tokenData = accessToken.data(using: .utf8) {
            keychainHelper.save(tokenData, for: "auth_token")
        }
        
        if let refreshTokenData = refreshToken.data(using: .utf8) {
            keychainHelper.save(refreshTokenData, for: "refresh_token")
        }
    }
    
    private func clearAuthenticationState() {
        currentToken = nil
        refreshToken = nil
        currentUser = nil
        isAuthenticated = false
        isLoading = false
        authError = nil
        
        // Clear stored tokens
        keychainHelper.delete(for: "auth_token")
        keychainHelper.delete(for: "refresh_token")
        
        // Clear biometric auth preference
        UserDefaults.standard.removeObject(forKey: "biometric_auth_enabled")
        
        // Cancel refresh timer
        refreshTokenTimer?.invalidate()
        setupTokenRefreshTimer()
    }
    
    private func handleAuthError(_ error: AuthError) {
        authError = error
        isLoading = false
        
        // Provide haptic feedback for auth errors
        HapticManager.shared.notification(.error)
    }
    
    private func mapNetworkErrorToAuthError(_ networkError: NetworkError) -> AuthError {
        switch networkError {
        case .unauthorized:
            return .invalidCredentials
        case .networkError:
            return .networkError
        case .serverError:
            return .serverError
        default:
            return .unknown
        }
    }
}

// MARK: - Supporting Types

// MARK: - Request Types
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct SignUpRequest: Codable {
    let email: String
    let password: String
    let fullName: String
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

// MARK: - Response Types
struct LoginResponse: Codable {
    let user: User
    let accessToken: String
    let refreshToken: String
}

struct RefreshTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
}

struct LogoutResponse: Codable {
    let success: Bool
}

// MARK: - Error Types
enum AuthError: LocalizedError {
    case invalidCredentials
    case networkError
    case serverError
    case validationFailed(String)
    case biometricNotAvailable
    case biometricNotEnabled
    case biometricAuthFailed
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Network connection error"
        case .serverError:
            return "Server error. Please try again later."
        case .validationFailed(let message):
            return "Authentication validation failed: \(message)"
        case .biometricNotAvailable:
            return "Biometric authentication is not available on this device"
        case .biometricNotEnabled:
            return "Biometric authentication is not enabled"
        case .biometricAuthFailed:
            return "Biometric authentication failed"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

// MARK: - API Endpoints Extension
extension APIEndpoint {
    static let login = APIEndpoint(path: "/auth/login")
    static let signUp = APIEndpoint(path: "/auth/signup")
    static let logout = APIEndpoint(path: "/auth/logout")
    static let refreshToken = APIEndpoint(path: "/auth/refresh")
    static let validateToken = APIEndpoint(path: "/auth/validate")
}
