
import Foundation
import Combine
import Security
import UIKit

// MARK: - Auth Service
@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let keychain = KeychainHelper.shared
    private var cancellables = Set<AnyCancellable>()
    private let networkManager = EnhancedNetworkManager.shared

    private init() {
        checkAuthStatus()
        setupNotifications()
    }

    // MARK: - Authentication Methods
    func login(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let request = LoginRequest(
            email: email,
            password: password,
            deviceId: getDeviceId(),
            deviceName: getDeviceName()
        )

        do {
            let response: AuthResponse = try await apiClient.request(Endpoint(path: "/auth/login", method: .post, body: request))
            try saveTokens(response.accessToken, response.refreshToken)
            self.currentUser = response.user
            self.isAuthenticated = true
            NotificationCenter.default.post(name: Constants.NotificationNames.userDidLogin, object: nil)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func register(email: String, password: String, firstName: String, lastName: String, username: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let request = RegisterRequest(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
            username: username,
            deviceId: getDeviceId(),
            deviceName: getDeviceName()
        )

        do {
            let response: AuthResponse = try await apiClient.request(Endpoint(path: "/auth/register", method: .post, body: request))
            try saveTokens(response.accessToken, response.refreshToken)
            self.currentUser = response.user
            self.isAuthenticated = true
            NotificationCenter.default.post(name: Constants.NotificationNames.userDidLogin, object: nil)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func logout() async {
        isLoading = true

        do {
            let _: EmptyResponse = try await apiClient.request(Endpoint(path: "/auth/logout", method: .post, body: EmptyRequest()))
        } catch {
            print("Failed to notify server about logout: \(error)")
        }

        clearTokens()
        self.currentUser = nil
        self.isAuthenticated = false
        NotificationCenter.default.post(name: Constants.NotificationNames.userDidLogout, object: nil)
        isLoading = false
    }

    func refreshToken() async throws {
        guard let refreshToken = getRefreshToken() else {
            throw NetworkError.unauthorized
        }

        let request = RefreshTokenRequest(refreshToken: refreshToken)

        do {
            let response: AuthResponse = try await apiClient.request(Endpoint(path: "/auth/refresh", method: .post, body: request))
            try saveTokens(response.accessToken, response.refreshToken)
            self.currentUser = response.user
        } catch {
            await logout()
            throw NetworkError.unauthorized
        }
    }

    func updateProfile(firstName: String, lastName: String, bio: String?) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let request = UpdateProfileRequest(
            firstName: firstName,
            lastName: lastName,
            bio: bio
        )

        do {
            let response: User = try await apiClient.request(Endpoint(path: "/profile", method: .put, body: request))
            self.currentUser = response
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func uploadAvatar(imageData: Data) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response: User = try await apiClient.request(Endpoint(path: "/profile/avatar", method: .post, body: imageData))
            self.currentUser = response
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Token Management
    func getAccessToken() async -> String? {
        guard let data = keychain.load(for: Constants.KeychainKeys.authToken),
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        return token
    }

    private func getRefreshToken() -> String? {
        guard let data = keychain.load(for: Constants.KeychainKeys.refreshToken),
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        return token
    }

    private func saveTokens(_ accessToken: String, _ refreshToken: String) throws {
        guard let accessData = accessToken.data(using: .utf8),
              let refreshData = refreshToken.data(using: .utf8) else {
            throw NetworkError.unknown
        }

        guard keychain.save(accessData, for: Constants.KeychainKeys.authToken),
              keychain.save(refreshData, for: Constants.KeychainKeys.refreshToken) else {
            throw NetworkError.unknown
        }
    }

    private func clearTokens() {
        _ = keychain.delete(for: Constants.KeychainKeys.authToken)
        _ = keychain.delete(for: Constants.KeychainKeys.refreshToken)
    }

    // MARK: - Helper Methods
    private func checkAuthStatus() {
        Task {
            if await getAccessToken() != nil {
                do {
                    let user: User = try await apiClient.request(Endpoint(path: "/profile"))
                    await MainActor.run {
                        self.currentUser = user
                        self.isAuthenticated = true
                    }
                } catch {
                    clearTokens()
                }
            }
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.checkAuthStatus()
            }
            .store(in: &cancellables)
    }

    private func getDeviceId() -> String {
        if let deviceId = UserDefaults.standard.string(forKey: "deviceId") {
            return deviceId
        } else {
            let deviceId = UUID().uuidString
            UserDefaults.standard.set(deviceId, forKey: "deviceId")
            return deviceId
        }
    }

    private func getDeviceName() -> String {
        return UIDevice.current.name
    }
}

