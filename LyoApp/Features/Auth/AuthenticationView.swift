import SwiftUI

// ModernDesignSystem should be accessible since it's in the same target, but let's make sure all types are accessible

// MARK: - Phase 2 Enhanced Authentication View
// Modern, accessible, and delightful authentication experience

struct AuthenticationView: View {
    @EnvironmentObject var authService: EnhancedAuthService
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var username = ""
    @State private var isSignUp = false
    @State private var showingPassword = false
    @State private var agreedToTerms = false
    @State private var isAnimating = false
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case email, password, firstName, lastName, username
    }
    
    var body: some View {
        ZStack {
            // Dynamic background with subtle animation
            modernBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xl) {
                    Spacer()
                        .frame(height: DesignTokens.Spacing.xxl)
                    
                    // Enhanced Logo and Title
                    logoSection
                    
                    // Modern Form Section
                    authFormSection
                    
                    // Enhanced Action Buttons
                    actionButtonsSection
                    
                    // Social Sign-in (if available)
                    socialSignInSection
                    
                    // Enhanced Toggle Section
                    toggleSection
                    
                    Spacer()
                        .frame(height: DesignTokens.Spacing.xl)
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
            }
            
            // Loading overlay
            if authService.isLoading {
                loadingOverlay
            }
        }
        .onAppear {
            startInitialAnimation()
        }
        .alert("Authentication Error", 
               isPresented: .constant(authService.authError != nil)) {
            Button("OK") {
                authService.clearError()
            }
        } message: {
            if let error = authService.authError {
                Text(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Enhanced UI Components
    
    @ViewBuilder
    private var modernBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: DesignTokens.Colors.backgroundPrimary, location: 0.0),
                    .init(color: DesignTokens.Colors.backgroundSecondary, location: 0.7),
                    .init(color: DesignTokens.Colors.primary.opacity(0.1), location: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated accent elements
            Circle()
                .fill(DesignTokens.Colors.accent.opacity(0.1))
                .frame(width: 200, height: 200)
                .blur(radius: 50)
                .offset(x: isAnimating ? 100 : -100, y: isAnimating ? -50 : 50)
                .animation(
                    Animation.easeInOut
                        .repeatForever(autoreverses: true)
                        .speed(0.3),
                    value: isAnimating
                )
            
            Circle()
                .fill(DesignTokens.Colors.secondary.opacity(0.08))
                .frame(width: 150, height: 150)
                .blur(radius: 40)
                .offset(x: isAnimating ? -80 : 80, y: isAnimating ? 100 : -100)
                .animation(
                    Animation.easeInOut
                        .repeatForever(autoreverses: true)
                        .speed(0.4),
                    value: isAnimating
                )
        }
    }
    
    @ViewBuilder
    private var logoSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) { // Reduced spacing
            // Enhanced logo with modern design
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                DesignTokens.Colors.primary,
                                DesignTokens.Colors.secondary
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100) // Reduced size
                    .overlay(
                        Circle()
                            .stroke(
                                DesignTokens.Colors.primary.opacity(0.3),
                                lineWidth: 2
                            )
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .opacity(isAnimating ? 0.5 : 1.0)
                            .animation(
                                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                    )
                
                Text("L")
                    .font(DesignTokens.Typography.displayMedium) // Reduced font size
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .scaleEffect(1.2)
            }
            .shadow(
                color: DesignTokens.Colors.primary.opacity(0.3),
                radius: 20,
                x: 0,
                y: 10
            )
            
            VStack(spacing: DesignTokens.Spacing.xs) { // Reduced spacing
                Text("Welcome to LyoApp")
                    .font(DesignTokens.Typography.headlineSmall) // Reduced font size
                    .fontWeight(.bold)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text(isSignUp ? "Create your learning journey" : "Continue your learning journey")
                    .font(DesignTokens.Typography.bodyMedium) // Reduced font size
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .opacity(isAnimating ? 1.0 : 0.3)
        .scaleEffect(isAnimating ? 1.0 : 0.8)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.8).delay(0.2),
            value: isAnimating
        )
    }
    
    @ViewBuilder
    private var authFormSection: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Auth Form
            VStack(spacing: 20) {
                // Sign Up Additional Fields
                if isSignUp {
                    HStack(spacing: DesignTokens.Spacing.md) {
                        ModernTextField(
                            title: "First Name",
                            text: $firstName,
                            placeholder: "First Name"
                        )
                        .focused($focusedField, equals: .firstName)
                        
                        ModernTextField(
                            title: "Last Name",
                            text: $lastName,
                            placeholder: "Last Name"
                        )
                        .focused($focusedField, equals: .lastName)
                    }
                    
                    ModernTextField(
                        title: "Username",
                        text: $username,
                        placeholder: "Username"
                    )
                    .focused($focusedField, equals: .username)
                }
                
                ModernTextField(
                    title: "Email",
                    text: $email,
                    placeholder: "Email"
                )
                .focused($focusedField, equals: .email)
                
                ModernTextField(
                    title: "Password",
                    text: $password,
                    placeholder: "Password",
                    isSecure: !showingPassword
                )
                .focused($focusedField, equals: .password)
                
                if isSignUp {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        ModernCheckbox(isChecked: $agreedToTerms)
                        
                        Text("I agree to the ")
                            .font(DesignTokens.Typography.bodySmall)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        + Text("Terms of Service")
                            .font(DesignTokens.Typography.bodySmall)
                            .foregroundColor(DesignTokens.Colors.primary)
                            .underline()
                        + Text(" and ")
                            .font(DesignTokens.Typography.bodySmall)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        + Text("Privacy Policy")
                            .font(DesignTokens.Typography.bodySmall)
                            .foregroundColor(DesignTokens.Colors.primary)
                            .underline()
                    }
                    .padding(.horizontal, DesignTokens.Spacing.sm)
                }
            }
            .opacity(isAnimating ? 1.0 : 0.5)
            .offset(y: isAnimating ? 0 : 20)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.8).delay(0.4),
                value: isAnimating
            )
        }
        .animation(.easeInOut(duration: 0.3), value: isSignUp)
    }
    
    @ViewBuilder
    private var actionButtonsSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ModernButton(
                title: isSignUp ? "Create Account" : "Sign In",
                style: .primary,
                size: .large
            ) {
                handleAuthentication()
            }
            
            if !isSignUp {
                ModernButton(
                    title: "Forgot Password?",
                    style: .secondary,
                    size: .medium
                ) {
                    handleForgotPassword()
                }
            }
        }
        .opacity(isAnimating ? 1.0 : 0.5)
        .offset(y: isAnimating ? 0 : 30)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.8).delay(0.6),
            value: isAnimating
        )
    }
    
    @ViewBuilder
    private var socialSignInSection: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            HStack {
                Rectangle()
                    .fill(DesignTokens.Colors.neutral300.opacity(0.3))
                    .frame(height: 1)
                
                Text("OR CONTINUE WITH")
                    .font(DesignTokens.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                Rectangle()
                    .fill(DesignTokens.Colors.neutral300.opacity(0.3))
                    .frame(height: 1)
            }
            
            HStack(spacing: DesignTokens.Spacing.lg) {
                socialLoginButton(provider: .apple)
                socialLoginButton(provider: .google)
                socialLoginButton(provider: .meta)
            }
        }
        .opacity(isAnimating ? 1.0 : 0.5)
        .offset(y: isAnimating ? 0 : 30)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.8).delay(0.7),
            value: isAnimating
        )
    }

    @ViewBuilder
    private func socialLoginButton(provider: SocialProvider) -> some View {
        Button(action: {
            handleSocialSignIn(provider: provider)
        }) {
            HStack {
                Image(systemName: provider.iconName)
                    .font(.title2)
                    .imageScale(.large)
                    .foregroundColor(provider.color)
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(DesignTokens.Colors.surfaceVariant)
            .cornerRadius(DesignTokens.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                    .stroke(DesignTokens.Colors.border, lineWidth: 1)
            )
        }
    }
    
    @ViewBuilder
    private var toggleSection: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 1.0)) {
                    isSignUp.toggle()
                    clearFields()
                }
                HapticManager.shared.lightImpact()
            }) {
                Text(isSignUp ? "Sign In" : "Sign Up")
                    .font(DesignTokens.Typography.bodyMedium.weight(.semibold))
                    .foregroundColor(DesignTokens.Colors.primary)
            }
        }
        .opacity(isAnimating ? 1.0 : 0.3)
        .offset(y: isAnimating ? 0 : 50)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.8).delay(1.0),
            value: isAnimating
        )
    }
    
    @ViewBuilder
    private var loadingOverlay: some View {
        ZStack {
            DesignTokens.Colors.backgroundPrimary.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: DesignTokens.Spacing.lg) {
                ProgressView(value: authService.isLoading ? 0.5 : 0.0, total: 1.0)
                    .scaleEffect(1.5)
                
                Text(isSignUp ? "Creating your account..." : "Signing you in...")
                    .font(DesignTokens.Typography.bodyLarge)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
            }
            .padding(DesignTokens.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.lg)
                    .fill(DesignTokens.Colors.backgroundSecondary)
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        if isSignUp {
            return !email.isEmpty && 
                   !password.isEmpty && 
                   !firstName.isEmpty && 
                   !lastName.isEmpty && 
                   !username.isEmpty && 
                   agreedToTerms &&
                   isValidEmail(email) &&
                   password.count >= 6
        } else {
            return !email.isEmpty && 
                   !password.isEmpty && 
                   isValidEmail(email)
        }
    }
    
    // MARK: - Logic Handlers
    
    private func startInitialAnimation() {
        withAnimation {
            isAnimating = true
        }
    }
    
    private func handleAuthentication() {
        guard isFormValid else { return }
        
        HapticManager.shared.mediumImpact()
        
        Task {
            do {
                if isSignUp {
                    _ = try await authService.signUp(
                        email: email,
                        password: password,
                        firstName: firstName,
                        lastName: lastName,
                        username: username
                    )
                } else {
                    _ = try await authService.signIn(email: email, password: password)
                }
            } catch {
                // Error handling is managed by the authService
                print("Authentication error: \(error)")
            }
        }
    }
    
    private func handleSocialSignIn(provider: SocialProvider) {
        Task {
            do {
                // TODO: Implement actual social authentication with provider SDKs
                // This would involve integrating with Apple Sign In, Google Sign In, etc.
                switch provider {
                case .apple:
                    // Implement Apple Sign In
                    break
                case .google:
                    // Implement Google Sign In
                    break
                case .facebook:
                    // Implement Facebook Sign In
                    break
                }
            } catch {
                print("Social login failed: \(error)")
            }
        }
    }

    private func handleForgotPassword() {
        // Placeholder for forgot password logic
        print("Forgot password tapped")
    }
    
    private func toggleAuthMode() {
        withAnimation(.spring(response: 0.3, dampingFraction: 1.0)) {
            isSignUp.toggle()
            clearFields()
        }
        HapticManager.shared.lightImpact()
    }
    
    private func clearFields() {
        email = ""
        password = ""
        firstName = ""
        lastName = ""
        username = ""
        agreedToTerms = false
        focusedField = nil
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - Modern Checkbox Component
struct ModernCheckbox: View {
    @Binding var isChecked: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 1.0)) {
                isChecked.toggle()
            }
            HapticManager.shared.lightImpact()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.sm)
                    .fill(isChecked ? DesignTokens.Colors.primary : Color.clear)
                    .frame(width: 20, height: 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.sm)
                            .stroke(
                                isChecked ? DesignTokens.Colors.primary : DesignTokens.Colors.neutral300,
                                lineWidth: 2
                            )
                    )
                
                if isChecked {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(isChecked ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isChecked)
                }
            }
        }
    }
}

#Preview {
    AuthenticationView()
        .preferredColorScheme(.dark)
}

// MARK: - Social Provider Enum
enum SocialProvider: String {
    case apple, google, meta

    var iconName: String {
        switch self {
        case .apple: return "applelogo"
        case .google: return "g.circle.fill" // Placeholder, as there is no official Google logo in SF Symbols
        case .meta: return "f.circle.fill" // Placeholder, using Facebook logo
        }
    }

    var color: Color {
        switch self {
        case .apple: return DesignTokens.Colors.textPrimary
        case .google: return .red
        case .meta: return .blue
        }
    }
}