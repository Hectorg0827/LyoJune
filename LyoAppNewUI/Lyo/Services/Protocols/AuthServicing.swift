import Foundation

/// A protocol that defines the contract for a service responsible for authentication.
///
/// This protocol abstracts the details of token storage and renewal, allowing the `HTTPClient`
/// and other services to remain agnostic of the specific implementation (e.g., Keychain storage, OAuth flow).
public protocol AuthServicing {

    /// Retrieves the current valid access token, if one exists.
    /// - Returns: The current JWT access token as a `String`, or `nil` if the user is not authenticated.
    func currentAccessToken() async -> String?

    /// Attempts to refresh the access token using a stored refresh token.
    /// This method is responsible for making the network call to the refresh endpoint
    /// and securely updating the stored tokens upon success.
    /// - Throws: An `Error` (typically `APIError`) if the refresh attempt fails.
    func refreshToken() async throws
}
