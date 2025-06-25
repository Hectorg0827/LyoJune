import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authService: LyoAuthService
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var showingPassword = false
    
    var body: some View {
        ZStack {
            GlassBackground()
            
            ScrollView {
                VStack(spacing: 30) {
                    Spacer()
                        .frame(height: 50)
                    
                    // Logo and Title
                    VStack(spacing: 20) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text("L")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                            .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
                        
                        VStack(spacing: 8) {
                            Text("Welcome to LyoApp")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(isSignUp ? "Create your learning journey" : "Continue your learning journey")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // Auth Form
                    VStack(spacing: 20) {
                        // Email Field
                        GlassFormField(
                            title: "Email",
                            text: $email,
                            placeholder: "Enter your email",
                            icon: "envelope"
                        )
                        
                        // Password Field
                        GlassPasswordField(
                            title: "Password",
                            text: $password,
                            placeholder: "Enter your password",
                            showingPassword: $showingPassword
                        )
                        
                        // Sign In/Up Button
                        Button(action: handleAuth) {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(authService.isLoading || email.isEmpty || password.isEmpty)
                        .opacity(authService.isLoading || email.isEmpty || password.isEmpty ? 0.6 : 1.0)
                        
                        // Error Message
                        if let errorMessage = authService.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                        }
                        
                        // Toggle Sign In/Up
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isSignUp.toggle()
                            }
                        }) {
                            HStack {
                                Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                    .foregroundColor(.white.opacity(0.8))
                                Text(isSignUp ? "Sign In" : "Sign Up")
                                    .foregroundColor(.blue)
                                    .fontWeight(.semibold)
                            }
                            .font(.body)
                        }
                        
                        // Demo Access
                        Button(action: {
                            Task {
                                await authService.signIn(email: "demo@lyo.app", password: "demo123")
                            }
                        }) {
                            Text("Continue as Demo User")
                                .foregroundColor(.white.opacity(0.6))
                                .font(.caption)
                                .underline()
                        }
                        .padding(.top, 20)
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
            }
        }
    }
    
    private func handleAuth() {
        Task {
            await authService.signIn(email: email, password: password)
        }
    }
}


struct GlassPasswordField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    @Binding var showingPassword: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                Image(systemName: "lock")
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 20)
                
                Group {
                    if showingPassword {
                        TextField(placeholder, text: $text)
                    } else {
                        SecureField(placeholder, text: $text)
                    }
                }
                .foregroundColor(.white)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                
                Button(action: {
                    showingPassword.toggle()
                }) {
                    Image(systemName: showingPassword ? "eye.slash" : "eye")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Material.ultraThin)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

struct GlassBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.black,
                Color.blue.opacity(0.2),
                Color.purple.opacity(0.1),
                Color.black
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(LyoAuthService())
}