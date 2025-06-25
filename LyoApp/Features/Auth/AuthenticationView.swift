import SwiftUI

struct AuthenticationView: View {
    @StateObject private var authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var username = ""
    @State private var isSignUp = false
    @State private var showingPassword = false
    @State private var agreedToTerms = false
    
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
                        // Sign Up Additional Fields
                        if isSignUp {
                            HStack(spacing: 12) {
                                GlassFormField(
                                    title: "First Name",
                                    text: $firstName,
                                    placeholder: "First name",
                                    icon: "person"
                                )
                                
                                GlassFormField(
                                    title: "Last Name",
                                    text: $lastName,
                                    placeholder: "Last name",
                                    icon: "person.fill"
                                )
                            }
                            
                            GlassFormField(
                                title: "Username",
                                text: $username,
                                placeholder: "Choose a username",
                                icon: "at"
                            )
                        }
                        
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
                            placeholder: isSignUp ? "Create a password (min 8 characters)" : "Enter your password",
                            showingPassword: $showingPassword
                        )
                        
                        // Password Requirements (Sign Up only)
                        if isSignUp {
                            PasswordRequirementsView(password: password)
                        }
                        
                        // Terms Agreement (Sign Up only)
                        if isSignUp {
                            TermsAgreementView(agreedToTerms: $agreedToTerms)
                        }
                        
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
                        .disabled(!isFormValid)
                        .opacity(isFormValid ? 1.0 : 0.6)
                        
                        // Error Message
                        if let errorMessage = authService.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Toggle Sign In/Up
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isSignUp.toggle()
                                clearForm()
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
                        
                        // Forgot Password (Sign In only)
                        if !isSignUp {
                            Button(action: handleForgotPassword) {
                                Text("Forgot Password?")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                    .underline()
                            }
                        }
                        
                        // Demo Access
                        Button(action: handleDemoLogin) {
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
        .animation(.easeInOut(duration: 0.3), value: isSignUp)
    }
    
    private var isFormValid: Bool {
        if authService.isLoading { return false }
        
        let emailValid = !email.isEmpty && email.contains("@")
        let passwordValid = password.count >= 8
        
        if isSignUp {
            let namesValid = !firstName.isEmpty && !lastName.isEmpty
            let usernameValid = username.count >= 3
            return emailValid && passwordValid && namesValid && usernameValid && agreedToTerms
        } else {
            return emailValid && !password.isEmpty
        }
    }
    
    private func handleAuth() {
        Task {
            do {
                if isSignUp {
                    try await authService.register(
                        email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                        password: password,
                        firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                        lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                        username: username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    )
                } else {
                    try await authService.login(
                        email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                        password: password
                    )
                }
            } catch {
                // Error is handled by the AuthService
            }
        }
    }
    
    private func handleDemoLogin() {
        Task {
            do {
                try await authService.login(email: "demo@lyo.app", password: "demo123456")
            } catch {
                // If demo user doesn't exist, create one
                do {
                    try await authService.register(
                        email: "demo@lyo.app",
                        password: "demo123456",
                        firstName: "Demo",
                        lastName: "User",
                        username: "demouser"
                    )
                } catch {
                    authService.errorMessage = "Demo login failed. Please create an account."
                }
            }
        }
    }
    
    private func handleForgotPassword() {
        // In a real app, this would trigger a password reset flow
        authService.errorMessage = "Password reset functionality coming soon. Please contact support."
    }
    
    private func clearForm() {
        email = ""
        password = ""
        firstName = ""
        lastName = ""
        username = ""
        agreedToTerms = false
        authService.errorMessage = nil
    }
}

struct PasswordRequirementsView: View {
    let password: String
    
    private var requirements: [(String, Bool)] {
        [
            ("At least 8 characters", password.count >= 8),
            ("Contains uppercase letter", password.range(of: "[A-Z]", options: .regularExpression) != nil),
            ("Contains lowercase letter", password.range(of: "[a-z]", options: .regularExpression) != nil),
            ("Contains number", password.range(of: "[0-9]", options: .regularExpression) != nil)
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Password Requirements:")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            ForEach(requirements, id: \.0) { requirement, met in
                HStack(spacing: 8) {
                    Image(systemName: met ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(met ? .green : .white.opacity(0.5))
                        .font(.caption)
                    
                    Text(requirement.0)
                        .font(.caption)
                        .foregroundColor(met ? .green : .white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Material.ultraThin)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct TermsAgreementView: View {
    @Binding var agreedToTerms: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: {
                agreedToTerms.toggle()
            }) {
                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                    .foregroundColor(agreedToTerms ? .blue : .white.opacity(0.7))
                    .font(.system(size: 20))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("I agree to the ")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                + Text("Terms of Service")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .underline()
                + Text(" and ")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                + Text("Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .underline()
            }
        }
        .padding(.horizontal, 16)
    }
}

struct GlassFormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 20)
                
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .autocapitalization(title.contains("Email") ? .none : .words)
                    .disableAutocorrection(title.contains("Email") || title.contains("Username"))
                    .keyboardType(title.contains("Email") ? .emailAddress : .default)
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
}