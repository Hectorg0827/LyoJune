import SwiftUI

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
    @State private var focusedField: Field?
    
    enum Field: Hashable {
        case email, password, firstName, lastName, username
    }
    
    var body: some View {
        ZStack {
            // Dynamic background with subtle animation
            modernBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: ModernDesignSystem.Spacing.xl) {
                    Spacer()
                        .frame(height: ModernDesignSystem.Spacing.xxl)
                    
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
                        .frame(height: ModernDesignSystem.Spacing.xl)
                }
                .padding(.horizontal, ModernDesignSystem.Spacing.lg)
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
                    .init(color: ModernDesignSystem.Colors.backgroundPrimary, location: 0.0),
                    .init(color: ModernDesignSystem.Colors.backgroundSecondary, location: 0.7),
                    .init(color: ModernDesignSystem.Colors.primary.opacity(0.1), location: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated accent elements
            Circle()
                .fill(ModernDesignSystem.Colors.accent.opacity(0.1))
                .frame(width: 200, height: 200)
                .blur(radius: 50)
                .offset(x: isAnimating ? 100 : -100, y: isAnimating ? -50 : 50)
                .animation(
                    ModernDesignSystem.Animations.easeInOut
                        .repeatForever(autoreverses: true)
                        .speed(0.3),
                    value: isAnimating
                )
            
            Circle()
                .fill(ModernDesignSystem.Colors.secondary.opacity(0.08))
                .frame(width: 150, height: 150)
                .blur(radius: 40)
                .offset(x: isAnimating ? -80 : 80, y: isAnimating ? 100 : -100)
                .animation(
                    ModernDesignSystem.Animations.easeInOut
                        .repeatForever(autoreverses: true)
                        .speed(0.4),
                    value: isAnimating
                )
        }
    }
    
    @ViewBuilder
    private var logoSection: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            // Enhanced logo with modern design
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                ModernDesignSystem.Colors.primary,
                                ModernDesignSystem.Colors.secondary
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(
                                ModernDesignSystem.Colors.primary.opacity(0.3),
                                lineWidth: 2
                            )
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .opacity(isAnimating ? 0.5 : 1.0)
                            .animation(
                                ModernDesignSystem.Animations.pulse,
                                value: isAnimating
                            )
                    )
                
                Text("L")
                    .font(ModernDesignSystem.Typography.displayLarge)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .scaleEffect(1.2)
            }
            .shadow(
                color: ModernDesignSystem.Colors.primary.opacity(0.3),
                radius: 20,
                x: 0,
                y: 10
            )
            
            VStack(spacing: ModernDesignSystem.Spacing.sm) {
                Text("Welcome to LyoApp")
                    .font(ModernDesignSystem.Typography.displayMedium)
                    .fontWeight(.bold)
                    .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                
                Text(isSignUp ? "Create your learning journey" : "Continue your learning journey")
                    .font(ModernDesignSystem.Typography.bodyLarge)
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .opacity(isAnimating ? 1.0 : 0.3)
        .scaleEffect(isAnimating ? 1.0 : 0.8)
        .animation(
            ModernDesignSystem.Animations.spring.delay(0.2),
            value: isAnimating
        )
    }
    
    @ViewBuilder
    private var authFormSection: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            // Auth Form
            VStack(spacing: 20) {
                // Sign Up Additional Fields
                if isSignUp {
                    HStack(spacing: ModernDesignSystem.Spacing.md) {
                        ModernTextField(
                            text: $firstName,
                            placeholder: "First Name",
                            style: .filled,
                            size: .medium
                        )
                        .focused($focusedField, equals: .firstName)
                        
                        ModernTextField(
                            text: $lastName,
                            placeholder: "Last Name",
                            style: .filled,
                            size: .medium
                        )
                        .focused($focusedField, equals: .lastName)
                    }
                    
                    ModernTextField(
                        text: $username,
                        placeholder: "Username",
                        style: .filled,
                        size: .medium,
                        icon: "person.crop.circle"
                    )
                    .focused($focusedField, equals: .username)
                }
                
                ModernTextField(
                    text: $email,
                    placeholder: "Email",
                    style: .filled,
                    size: .medium,
                    icon: "envelope",
                    keyboardType: .emailAddress
                )
                .focused($focusedField, equals: .email)
                
                ModernTextField(
                    text: $password,
                    placeholder: "Password",
                    style: .filled,
                    size: .medium,
                    icon: "lock",
                    isSecure: !showingPassword,
                    trailingIcon: showingPassword ? "eye.slash" : "eye",
                    trailingAction: {
                        showingPassword.toggle()
                        HapticManager.shared.lightImpact()
                    }
                )
                .focused($focusedField, equals: .password)
                
                if isSignUp {
                    HStack(spacing: ModernDesignSystem.Spacing.sm) {
                        ModernCheckbox(isChecked: $agreedToTerms)
                        
                        Text("I agree to the ")
                            .font(ModernDesignSystem.Typography.bodySmall)
                            .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                        + Text("Terms of Service")
                            .font(ModernDesignSystem.Typography.bodySmall)
                            .foregroundColor(ModernDesignSystem.Colors.primary)
                            .underline()
                        + Text(" and ")
                            .font(ModernDesignSystem.Typography.bodySmall)
                            .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                        + Text("Privacy Policy")
                            .font(ModernDesignSystem.Typography.bodySmall)
                            .foregroundColor(ModernDesignSystem.Colors.primary)
                            .underline()
                    }
                    .padding(.horizontal, ModernDesignSystem.Spacing.sm)
                }
            }
            .opacity(isAnimating ? 1.0 : 0.5)
            .offset(y: isAnimating ? 0 : 20)
            .animation(
                ModernDesignSystem.Animations.spring.delay(0.4),
                value: isAnimating
            )
        }
        .animation(.easeInOut(duration: 0.3), value: isSignUp)
    }
    
    @ViewBuilder
    private var actionButtonsSection: some View {
        VStack(spacing: ModernDesignSystem.Spacing.md) {
            ModernButton(
                title: isSignUp ? "Create Account" : "Sign In",
                style: .primary,
                size: .large,
                isLoading: authService.isLoading,
                isDisabled: !isFormValid,
                icon: isSignUp ? "person.badge.plus" : "arrow.right.circle"
            ) {
                handleAuthentication()
            }
            
            if !isSignUp {
                ModernButton(
                    title: "Forgot Password?",
                    style: .ghost,
                    size: .medium
                ) {
                    handleForgotPassword()
                }
            }
        }
        .opacity(isAnimating ? 1.0 : 0.5)
        .offset(y: isAnimating ? 0 : 30)
        .animation(
            ModernDesignSystem.Animations.spring.delay(0.6),
            value: isAnimating
        )
    }
    
    @ViewBuilder
    private var socialSignInSection: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            HStack {
                Rectangle()
                    .fill(ModernDesignSystem.Colors.neutral300.opacity(0.3))
                    .frame(height: 1)
                
                Text("OR")
                    .font(ModernDesignSystem.Typography.caption)
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    .padding(.horizontal, ModernDesignSystem.Spacing.md)
                
                Rectangle()
                    .fill(ModernDesignSystem.Colors.neutral300.opacity(0.3))
                    .frame(height: 1)
            }
            
            HStack(spacing: ModernDesignSystem.Spacing.md) {
                ModernButton(
                    title: "Apple",
                    style: .secondary,
                    size: .medium,
                    icon: "apple.logo"
                ) {
                    handleAppleSignIn()
                }
                
                ModernButton(
                    title: "Google",
                    style: .secondary,
                    size: .medium,
                    icon: "globe"
                ) {
                    handleGoogleSignIn()
                }
            }
        }
        .opacity(isAnimating ? 1.0 : 0.3)
        .offset(y: isAnimating ? 0 : 40)
        .animation(
            ModernDesignSystem.Animations.spring.delay(0.8),
            value: isAnimating
        )
    }
    
    @ViewBuilder
    private var toggleSection: some View {
        HStack(spacing: ModernDesignSystem.Spacing.sm) {
            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                .font(ModernDesignSystem.Typography.bodyMedium)
                .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                
            Button(action: {
                withAnimation(ModernDesignSystem.Animations.springSnappy) {
                    isSignUp.toggle()
                    clearFields()
                }
                HapticManager.shared.lightImpact()
            }) {
                Text(isSignUp ? "Sign In" : "Sign Up")
                    .font(ModernDesignSystem.Typography.bodyMedium.weight(.semibold))
                    .foregroundColor(ModernDesignSystem.Colors.primary)
            }
        }
        .opacity(isAnimating ? 1.0 : 0.3)
        .offset(y: isAnimating ? 0 : 50)
        .animation(
            ModernDesignSystem.Animations.spring.delay(1.0),
            value: isAnimating
        )
    }
    
    @ViewBuilder
    private var loadingOverlay: some View {
        ZStack {
            ModernDesignSystem.Colors.backgroundPrimary.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: ModernDesignSystem.Spacing.lg) {
                ModernProgressView(style: .circular, size: .large)
                
                Text(isSignUp ? "Creating your account..." : "Signing you in...")
                    .font(ModernDesignSystem.Typography.bodyLarge)
                    .foregroundColor(ModernDesignSystem.Colors.textPrimary)
            }
            .padding(ModernDesignSystem.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg)
                    .fill(ModernDesignSystem.Colors.backgroundSecondary)
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
            if isSignUp {
                await authService.signUp(
                    email: email,
                    password: password,
                    firstName: firstName,
                    lastName: lastName,
                    username: username
                )
            } else {
                await authService.signIn(email: email, password: password)
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
            await authService.resetPassword(email: email)
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
            withAnimation(ModernDesignSystem.Animations.springSnappy) {
                isChecked.toggle()
            }
            HapticManager.shared.lightImpact()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.sm)
                    .fill(isChecked ? ModernDesignSystem.Colors.primary : Color.clear)
                    .frame(width: 20, height: 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.sm)
                            .stroke(
                                isChecked ? ModernDesignSystem.Colors.primary : ModernDesignSystem.Colors.neutral300,
                                lineWidth: 2
                            )
                    )
                
                if isChecked {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(isChecked ? 1.0 : 0.0)
                        .animation(ModernDesignSystem.Animations.springBouncy, value: isChecked)
                }
            }
        }
    }

#Preview {
    AuthenticationView()
        .preferredColorScheme(.dark)
}