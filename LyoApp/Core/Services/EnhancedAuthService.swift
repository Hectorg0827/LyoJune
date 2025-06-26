import Foundation
import Combine
import UIKit
import LocalAuthentication
import Security
// MARK: - Enhanced Auth Service
final class EnhancedAuthService: ObservableObject {
    static let shared = EnhancedAuthService()
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var authError: AuthError?
    @Published var isLoading: Bool = false
    
    private let networkManager: EnhancedNetworkManager
    private let keychainHelper: KeychainHelper
    private var cancellables = Set<AnyCancellable>()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    init(networkManager: EnhancedNetworkManager = .shared) {
        self.networkManager = networkManager
        self.keychainHelper = KeychainHelper.shared
        
        // Check for existing authentication
        checkExistingAuth()
    }
    
    // MARK: - Public Methods
    
    func login(email: String, password: String) async throws -> User {
        await MainActor.run { isLoading = true }
        
        let endpoint = APIEndpoint(path: "/auth/login", method: .POST)
        let request = LoginRequest(email: email, password: password)
        
        do {
            let data = try JSONEncoder().encode(request)
            let response: LoginResponse = try await networkManager.request(endpoint: endpoint, body: data)
            
            // Store tokens securely
            _ = keychainHelper.save(response.accessToken, for: "access_token")
            _ = keychainHelper.save(response.refreshToken, for: "refresh_token")
            
            await MainActor.run {
                self.isAuthenticated = true
                self.currentUser = response.user
                self.isLoading = false
                self.notificationGenerator.notificationOccurred(.success)
            }
            
            return response.user
        } catch {
            await MainActor.run {
                self.authError = .loginFailed(error.localizedDescription)
                self.isLoading = false
                self.notificationGenerator.notificationOccurred(.error)
            }
            throw error
        }
    }
    
    func register(email: String, password: String, name: String) async throws -> User {
        await MainActor.run { isLoading = true }
        
        let endpoint = APIEndpoint(path: "/auth/register", method: .POST)
        let request = RegisterRequest(email: email, password: password, name: name)
        
        do {
            let data = try JSONEncoder().encode(request)
            let response: LoginResponse = try await networkManager.request(endpoint: endpoint, body: data)
            
            // Store tokens securely
            _ = keychainHelper.save(response.accessToken, for: "access_token")
            _ = keychainHelper.save(response.refreshToken, for: "refresh_token")
            
            await MainActor.run {
                self.isAuthenticated = true
                self.currentUser = response.user
                self.isLoading = false
                self.notificationGenerator.notificationOccurred(.success)
            }
            
            return response.user
        } catch {
            await MainActor.run {
                self.authError = .registrationFailed
                self.isLoading = false
                self.notificationGenerator.notificationOccurred(.error)
            }
            throw error
        }
    }
    
    func logout() async {
        await MainActor.run { isLoading = true }
        
        let endpoint = APIEndpoint(path: "/auth/logout", method: .POST)
        
        // Attempt to notify server (don't fail if this fails)
        do {
            let _: EmptyResponse = try await networkManager.request(endpoint: endpoint)
        } catch {
            // Ignore logout errors - we'll clear local storage anyway
            print("⚠️ Logout request failed: \(error)")
        }
        
        // Clear local storage
        _ = keychainHelper.delete(for: "access_token")
        _ = keychainHelper.delete(for: "refresh_token")
        
        await MainActor.run {
            self.isAuthenticated = false
            self.currentUser = nil
            self.isLoading = false
            self.authError = nil
        }
    }
    
    func refreshToken() async throws {
        guard let refreshToken = keychainHelper.retrieve(for: "refresh_token") else {
            throw AuthError.noRefreshToken
        }
        
        let endpoint = APIEndpoint(path: "/auth/refresh", method: .POST)
        let request = RefreshTokenRequest(refreshToken: refreshToken)
        
        do {
            let data = try JSONEncoder().encode(request)
            let response: LoginResponse = try await networkManager.request(endpoint: endpoint, body: data)
            
            // Update stored tokens
            _ = keychainHelper.save(response.accessToken, for: "access_token")
            _ = keychainHelper.save(response.refreshToken, for: "refresh_token")
            
            await MainActor.run {
                self.currentUser = response.user
            }
        } catch {
            await MainActor.run {
                self.authError = .tokenRefreshFailed
                self.isAuthenticated = false
                self.currentUser = nil
            }
            throw error
        }
    }
    
    // MARK: - Biometric Authentication
    
    func enableBiometricAuth() async throws {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw AuthError.biometricNotAvailable
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Enable biometric authentication for quick login"
            )
            
            if success {
                UserDefaults.standard.set(true, forKey: "biometric_enabled")
                await MainActor.run {
                    self.notificationGenerator.notificationOccurred(.success)
                }
            }
        } catch {
            throw AuthError.biometricAuthFailed
        }
    }
    
    func authenticateWithBiometrics() async throws {
        guard UserDefaults.standard.bool(forKey: "biometric_enabled") else {
            throw AuthError.biometricNotEnrolled
        }
        
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw AuthError.biometricNotAvailable
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to access your account"
            )
            
            if success {
                // Check if we have valid stored credentials
                if let token = keychainHelper.retrieve(for: "access_token") {
                    try await validateToken(token)
                    await MainActor.run {
                        self.isAuthenticated = true
                        self.notificationGenerator.notificationOccurred(.success)
                    }
                } else {
                    throw AuthError.tokenInvalid
                }
            }
        } catch {
            throw AuthError.biometricAuthFailed
        }
    }
    
    // MARK: - Private Methods
    
    private func checkExistingAuth() {
        if let accessToken = keychainHelper.retrieve(for: "access_token") {
            // Validate token with server
            Task {
                do {
                    try await validateToken(accessToken)
                    let user = try await fetchCurrentUser()
                    await MainActor.run {
                        self.isAuthenticated = true
                        self.currentUser = user
                    }
                } catch {
                    // Token invalid, clear it
                    _ = keychainHelper.delete(for: "access_token")
                    _ = keychainHelper.delete(for: "refresh_token")
                    await MainActor.run {
                        self.isAuthenticated = false
                        self.currentUser = nil
                    }
                }
            }
        }
    }
    
    private func validateToken(_ token: String) async throws {
        let endpoint = APIEndpoint(path: "/auth/validate", method: .POST)
        let _: EmptyResponse = try await networkManager.request(endpoint: endpoint)
    }
    
    private func fetchCurrentUser() async throws -> User {
        let endpoint = APIEndpoint(path: "/auth/me", method: .GET)
        return try await networkManager.request(endpoint: endpoint)
    }
}

// MARK: - Request/Response Models

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let name: String
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

struct LoginResponse: Codable {
    let user: User
    let accessToken: String
    let refreshToken: String
}

// MARK: - Computed Properties

extension EnhancedAuthService {
    var errorMessage: String? {
        get {
            return authError?.localizedDescription
        }
        set {
            if newValue != nil {
                // Create a generic auth error with the message
                authError = .invalidCredentials // Default to this since we can't create custom message errors
            } else {
                authError = nil
            }
        }
    }
}
