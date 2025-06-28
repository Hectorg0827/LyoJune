import SwiftUI

// ModernDesignSystem should be accessible since it's in the same target, but let's make sure all types are accessible

// MARK: - Phase 2 Enhanced Authentication View
// Modern, accessible, and delightful authentication experience

struct AuthenticationView: View {
    @StateObject private var authService = EnhancedAuthService.shared
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
        VStack(spacing: DesignTokens.Spacing.lg) {
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
                    .frame(width: 120, height: 120)
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
                    .font(DesignTokens.Typography.displayLarge)
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
            
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("Welcome to LyoApp")
                    .font(DesignTokens.Typography.displayMedium)
                    .fontWeight(.bold)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text(isSignUp ? "Create your learning journey" : "Continue your learning journey")
                    .font(DesignTokens.Typography.bodyLarge)
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
                            style: .filled,
                            size: .medium,
                            placeholder: "First Name"
                        )
                        .focused($focusedField, equals: .firstName)
                        
                        ModernTextField(
                            title: "Last Name",
                            text: $lastName,
                            style: .filled,
                            size: .medium,
                            placeholder: "Last Name"
                        )
                        .focused($focusedField, equals: .lastName)
                    }
                    
                    ModernTextField(
                        title: "Username",
                        text: $username,
                        style: .filled,
                        size: .medium,
                        placeholder: "Username"
                    )
                    .focused($focusedField, equals: .username)
                }
                
                ModernTextField(
                    title: "Email",
                    text: $email,
                    style: .filled,
                    size: .medium,
                    placeholder: "Email"
                )
                .focused($focusedField, equals: .email)
                
                ModernTextField(
                    title: "Password",
                    text: $password,
                    style: .filled,
                    size: .medium,
                    isSecure: !showingPassword,
                    placeholder: "Password"
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
                size: .large,
                isLoading: authService.isLoading,
                isEnabled: isFormValid
            ) {
                handleAuthentication()
            }
            
            if !isSignUp {
                ModernButton(
                    title: "Forgot Password?",
                    style: .tertiary,
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
                
                Text("OR")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                
                Rectangle()
                    .fill(DesignTokens.Colors.neutral300.opacity(0.3))
                    .frame(height: 1)
            }
            
            HStack(spacing: DesignTokens.Spacing.md) {
                ModernButton(
                    title: "Apple",
                    style: .secondary,
                    size: .medium
                ) {
                    handleAppleSignIn()
                }
                
                ModernButton(
                    title: "Google",
                    style: .secondary,
                    size: .medium
                ) {
                    handleGoogleSignIn()
                }
            }
        }
        .opacity(isAnimating ? 1.0 : 0.3)
        .offset(y: isAnimating ? 0 : 40)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.8).delay(0.8),
            value: isAnimating
        )
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
                ProgressView()
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
    
    // MARK: - Private Methods
    
    private func startInitialAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                isAnimating = true
            }
        }
    }
    
    private func handleAuthentication() {
        guard isFormValid else { return }
        
        HapticManager.shared.mediumImpact()
        
        Task {
            do {
                if isSignUp {
                    try await authService.signUp(
                        email: email,
                        password: password,
                        firstName: firstName,
                        lastName: lastName,
                        username: username
                    )
                } else {
                    try await authService.signIn(email: email, password: password)
                }
            } catch {
                // Error handling is managed by the authService
                print("Authentication error: \(error)")
            }
        }
    }
    
    private func handleForgotPassword() {
        guard !email.isEmpty, isValidEmail(email) else {
            // Show alert for valid email requirement
            return
        }
        
        HapticManager.shared.lightImpact()
        
        Task {
            do {
                try await authService.resetPassword(email: email)
            } catch {
                print("Password reset error: \(error)")
            }
        }
    }
    
    private func handleAppleSignIn() {
        HapticManager.shared.lightImpact()
        // Implement Apple Sign In
    }
    
    private func handleGoogleSignIn() {
        HapticManager.shared.lightImpact()
        // Implement Google Sign In
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