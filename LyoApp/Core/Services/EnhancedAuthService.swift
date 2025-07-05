import Foundation
import Combine
import UIKit
import LocalAuthentication
import Security

// Import network types for API endpoints
// Note: NetworkTypes is available via shared target access

// Models are now defined in their respective files under Core/Models
// and are available project-wide. No direct imports are needed as
// they are part of the same application target.

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
    
    // Method aliases for compatibility with UI
    func signIn(email: String, password: String) async throws -> User {
        return try await login(email: email, password: password)
    }
    
    func signUp(email: String, password: String, firstName: String, lastName: String, username: String) async throws -> User {
        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        return try await register(email: email, password: password, name: fullName)
    }
    
    func clearError() {
        authError = nil
    }
    
    func resetPassword(email: String) async throws {
        await MainActor.run { isLoading = true }
        
        let endpoint = APIEndpoint(path: "/auth/reset-password", method: .POST)
        let request = ["email": email]
        
        do {
            let data = try JSONEncoder().encode(request)
            let _: EmptyResponse = try await networkManager.request(endpoint: endpoint, body: data)
            
            await MainActor.run {
                self.isLoading = false
                self.notificationGenerator.notificationOccurred(.success)
            }
        } catch {
            await MainActor.run {
                self.authError = .passwordResetFailed
                self.isLoading = false
                self.notificationGenerator.notificationOccurred(.error)
            }
            throw error
        }
    }
    
    func login(email: String, password: String) async throws -> User {
        await MainActor.run { isLoading = true }
        
        // Production authentication only
        let endpoint = APIEndpoint(path: "/auth/login", method: .POST)
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let deviceName = UIDevice.current.name
        let request = LoginRequest(email: email, password: password, deviceId: deviceId, deviceName: deviceName)
        
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
        
        // Production registration only
        let endpoint = APIEndpoint(path: "/auth/register", method: .POST)
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let deviceName = UIDevice.current.name
        
        // Split name into first and last name
        let nameComponents = name.split(separator: " ", maxSplits: 1)
        let firstName = String(nameComponents.first ?? "")
        let lastName = nameComponents.count > 1 ? String(nameComponents[1]) : ""
        let username = email.components(separatedBy: "@").first ?? email
        
        let request = RegisterRequest(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
            username: username,
            deviceId: deviceId,
            deviceName: deviceName
        )
        
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
