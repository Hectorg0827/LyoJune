import Foundation

/// The live implementation of the `AuthServicing` protocol.
/// This class manages user authentication tokens, including fetching, storing, and refreshing them.
final class AuthService: AuthServicing {

    private let baseURL: URL
    private let session: URLSession
    private let storage: SecureStoring

    /// Initializes a new `AuthService`.
    /// - Parameters:
    ///   - baseURL: The base URL for the API. The refresh path will be appended to this.
    ///   - session: The `URLSession` to use for the refresh network call.
    ///              This should be a raw session to avoid circular dependencies with `HTTPClient`.
    ///   - storage: A `SecureStoring` implementation (e.g., `KeychainStorage`) for tokens.
    init(baseURL: URL, session: URLSession, storage: SecureStoring) {
        self.baseURL = baseURL
        self.session = session
        self.storage = storage
    }

    // MARK: - AuthServicing Conformance

    func currentAccessToken() async -> String? {
        try? storage.read(forKey: KeychainStorage.accessTokenKey)
    }

    func refreshToken() async throws {
        // 1. Get the current refresh token from secure storage.
        guard let refreshToken = try? storage.read(forKey: KeychainStorage.refreshTokenKey) else {
            // If there's no refresh token, the user is not logged in or the session is invalid.
            throw APIError.unauthorized
        }

        // 2. Construct the URLRequest for the refresh endpoint.
        let url = baseURL.appendingPathComponent("/v1/auth/refresh")
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = RefreshTokenRequest(refreshToken: refreshToken)
        request.httpBody = try JSONEncoder().encode(requestBody)

        // 3. Perform the network call using a raw URLSession.
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            // If the refresh call itself fails (e.g., expired refresh token), it's an authorization failure.
            throw APIError.unauthorized
        }

        // 4. Decode the response and save the new tokens.
        do {
            let tokenResponse = try JSONDecoder().decode(AccessTokenResponse.self, from: data)
            try storage.save(value: tokenResponse.accessToken, forKey: KeychainStorage.accessTokenKey)

            // If the server provides a new refresh token (rotation), save it as well.
            if let newRefreshToken = tokenResponse.refreshToken {
                try storage.save(value: newRefreshToken, forKey: KeychainStorage.refreshTokenKey)
            }
        } catch {
            // If decoding fails, it's a critical error.
            throw APIError.decodingFailed(error)
        }
    }

    // MARK: - Public Helper Methods (for login/logout)

    /// Saves tokens after a successful login.
    /// This would be called by the Auth/Onboarding feature.
    func saveTokens(accessToken: String, refreshToken: String) throws {
        try storage.save(value: accessToken, forKey: KeychainStorage.accessTokenKey)
        try storage.save(value: refreshToken, forKey: KeychainStorage.refreshTokenKey)
    }

    /// Clears all tokens on logout.
    func clearTokens() throws {
        try storage.delete(forKey: KeychainStorage.accessTokenKey)
        try storage.delete(forKey: KeychainStorage.refreshTokenKey)
    }
}
