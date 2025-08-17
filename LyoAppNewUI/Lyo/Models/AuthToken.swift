import Foundation

/// The request body sent to the `/v1/auth/refresh` endpoint.
struct RefreshTokenRequest: Encodable {
    let refreshToken: String
}

/// The response body received from the `/v1/auth/refresh` endpoint.
struct AccessTokenResponse: Decodable {
    /// The new JWT access token.
    let accessToken: String

    /// The new JWT refresh token. This is optional, as some servers may not
    /// implement refresh token rotation.
    let refreshToken: String?
}
