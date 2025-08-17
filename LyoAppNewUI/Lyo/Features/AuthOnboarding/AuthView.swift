import SwiftUI
import AuthenticationServices // Needed for the Sign in with Apple button

struct AuthView: View {
    // In a real app, this would be a @StateObject-wrapped ViewModel.
    // @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        VStack {
            Spacer()

            // MARK: - Header
            VStack(spacing: 16) {
                Text("Welcome to Lyo")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Your personal learning companion. Let's get started.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)

            Spacer()

            // MARK: - Authentication Buttons
            VStack(spacing: 12) {
                // --- Sign in with Apple ---
                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in
                        // Configure the request for name and email
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        // This is where the result from the native Apple Sign In flow is handled.
                        // viewModel.handleAppleSignIn(result: result)
                        print("Apple Sign In completion handler called.")
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(8)

                // --- Sign in with Google ---
                socialSignInButton(
                    imageName: "google.logo", // Placeholder - requires asset
                    text: "Sign in with Google",
                    action: {
                        // viewModel.signInWithGoogle()
                        print("Google Sign In tapped.")
                    }
                )

                // --- Sign in with Meta ---
                socialSignInButton(
                    imageName: "meta.logo", // Placeholder - requires asset
                    text: "Sign in with Meta",
                    action: {
                        // viewModel.signInWithMeta()
                        print("Meta Sign In tapped.")
                    }
                )
            }
            .padding(.horizontal, 20)

            // MARK: - Footer
            Text("By continuing, you agree to our Terms of Service and Privacy Policy.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 20)
                .padding(.horizontal, 40)

            Spacer()
        }
        .background(Color(.systemGroupedBackground))
        .edgesIgnoringSafeArea(.all)
    }

    /// A helper for creating custom social sign-in buttons.
    @ViewBuilder
    private func socialSignInButton(imageName: String, text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                // In a real app, you'd use Image(imageName) with assets.
                Image(systemName: "questionmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)

                Spacer()

                Text(text)
                    .fontWeight(.semibold)

                Spacer()
            }
            .padding()
            .frame(height: 50)
            .background(Color(.secondarySystemBackground))
            .foregroundColor(.primary)
            .cornerRadius(8)
        }
        .accessibilityLabel(text)
    }
}

#if DEBUG
struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
    }
}
#endif
