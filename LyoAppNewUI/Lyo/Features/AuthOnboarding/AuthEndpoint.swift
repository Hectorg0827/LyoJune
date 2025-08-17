import Foundation

/// A namespace for creating authentication-related API endpoints.
enum AuthEndpoint {

    /// Creates an endpoint to exchange an Apple identity token for a Lyo JWT.
    /// - Parameters:
    ///   - token: The identity token string provided by the Sign in with Apple flow.
    ///   - fullName: The user's full name, if available.
    ///   - email: The user's email, if available.
    /// - Returns: An `Endpoint` configured for the Apple OAuth exchange.
    static func exchangeAppleToken(token: String, fullName: String?, email: String?) -> Endpoint<AuthResponse> {
        let requestBody = OAuthExchangeRequest(token: token, fullName: fullName, email: email)

        // Using try! is acceptable here as the `OAuthExchangeRequest` is a simple struct
        // and is guaranteed to encode successfully. This avoids polluting call sites with error handling.
        return try! Endpoint(
            path: "/v1/auth/oauth/apple",
            method: .post,
            encodableBody: requestBody
        )
    }

    /// Creates an endpoint to exchange a Google identity token for a Lyo JWT.
    static func exchangeGoogleToken(token: String, fullName: String?, email: String?) -> Endpoint<AuthResponse> {
        let requestBody = OAuthExchangeRequest(token: token, fullName: fullName, email: email)
        return try! Endpoint(
            path: "/v1/auth/oauth/google",
            method: .post,
            encodableBody: requestBody
        )
    }

    /// Creates an endpoint to exchange a Meta (Facebook) identity token for a Lyo JWT.
    static func exchangeMetaToken(token: String, fullName: String?, email: String?) -> Endpoint<AuthResponse> {
        let requestBody = OAuthExchangeRequest(token: token, fullName: fullName, email: email)
        return try! Endpoint(
            path: "/v1/auth/oauth/meta",
            method: .post,
            encodableBody: requestBody
        )
    }
}
