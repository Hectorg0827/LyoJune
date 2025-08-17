import Foundation

/// The request body sent to the backend to exchange a third-party OAuth token for a Lyo JWT.
struct OAuthExchangeRequest: Encodable {
    /// The token received from the OAuth provider (e.g., Apple, Google).
    let token: String
    /// The full name of the user, if available from the OAuth provider.
    let fullName: String?
    /// The email of the user, if available from the OAuth provider.
    let email: String?
}

/// The response from a successful OAuth exchange, containing the app's internal tokens.
/// This could be extended if the backend returns user profile information as well.
struct AuthResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}
