import Foundation
import AuthenticationServices // For ASAuthorization

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var isLoading: Bool = false
    @Published var errorToast: Toast? = nil

    private let httpClient: HTTPClienting
    private let authService: AuthService // Using concrete class to get saveTokens method

    init(httpClient: HTTPClienting, authService: AuthService) {
        self.httpClient = httpClient
        self.authService = authService
    }

    // MARK: - Public Intent Methods

    /// Handles the result from the native "Sign in with Apple" flow.
    public func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = appleIDCredential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8)
            else {
                errorToast = Toast(message: "Failed to get Apple identity token.", style: .error)
                return
            }

            let fullName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")

            exchangeToken(
                provider: .apple,
                token: identityToken,
                fullName: fullName.isEmpty ? nil : fullName,
                email: appleIDCredential.email
            )

        case .failure(let error):
            // Handle cancellation as a non-fatal event.
            if (error as? ASAuthorizationError)?.code == .canceled {
                return
            }
            errorToast = Toast(message: "Apple Sign In failed: \(error.localizedDescription)", style: .error)
        }
    }

    /// Placeholder for Google Sign-In flow.
    public func signInWithGoogle() {
        // TODO: Integrate Google Sign-In SDK
        // 1. Call GIDSignIn.sharedInstance.signIn(...)
        // 2. On completion, get the idToken.
        // 3. Call exchangeToken(provider: .google, token: idToken, ...)

        print("Simulating Google Sign In...")
        exchangeToken(provider: .google, token: "fake-google-token", fullName: "Demo User", email: "demo@example.com")
    }

    /// Placeholder for Meta Sign-In flow.
    public func signInWithMeta() {
        // TODO: Integrate Facebook Login SDK
        // 1. Call LoginManager().logIn(...)
        // 2. On completion, get the authenticationToken.
        // 3. Call exchangeToken(provider: .meta, token: authenticationToken, ...)

        print("Simulating Meta Sign In...")
        exchangeToken(provider: .meta, token: "fake-meta-token", fullName: "Demo User", email: "demo@example.com")
    }

    // MARK: - Private Logic

    private func exchangeToken(provider: OAuthProvider, token: String, fullName: String?, email: String?) {
        Task {
            isLoading = true

            do {
                let endpoint = provider.endpoint(token: token, fullName: fullName, email: email)
                let response = try await httpClient.request(endpoint)

                try authService.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)

                // If we get here, the entire flow was successful.
                // A higher-level coordinator would now dismiss the auth flow.
                print("Successfully authenticated and saved tokens.")

            } catch {
                errorToast = Toast(message: "Authentication failed: \(error.localizedDescription)", style: .error)
            }

            isLoading = false
        }
    }
}

// MARK: - Helper Enum

private enum OAuthProvider {
    case apple, google, meta

    func endpoint(token: String, fullName: String?, email: String?) -> Endpoint<AuthResponse> {
        switch self {
        case .apple:
            return AuthEndpoint.exchangeAppleToken(token: token, fullName: fullName, email: email)
        case .google:
            return AuthEndpoint.exchangeGoogleToken(token: token, fullName: fullName, email: email)
        case .meta:
            return AuthEndpoint.exchangeMetaToken(token: token, fullName: fullName, email: email)
        }
    }
}
