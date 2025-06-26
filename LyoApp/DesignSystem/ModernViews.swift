import SwiftUI

/// Enhanced Loading View using the modern design system
struct ModernLoadingView: View {
    @State private var isAnimating = false
    let message: String
    
    init(message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        ZStack {
            // Glass background
            DesignTokens.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: DesignTokens.Spacing.large) {
                // Modern loading animation
                ZStack {
                    Circle()
                        .stroke(
                            DesignTokens.Colors.primary.opacity(0.2),
                            lineWidth: DesignTokens.BorderRadius.medium
                        )
                        .frame(size: 60)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            DesignTokens.Colors.primary,
                            style: StrokeStyle(
                                lineWidth: DesignTokens.BorderRadius.medium,
                                lineCap: .round
                            )
                        )
                        .frame(size: 60)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(
                            .linear(duration: 1.0).repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                }
                
                // Loading text
                Text(message)
                    .font(DesignTokens.Typography.bodyLarge)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .onAppear {
                isAnimating = true
            }
        }
    }
}

/// Enhanced version of ContentView with modern design system
struct EnhancedContentView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var networkManager: NetworkManager
    @StateObject private var errorManager = ErrorManager.shared
    @StateObject private var offlineManager = OfflineManager.shared
    @State private var showingOfflineAlert = false
    
    var body: some View {
        Group {
            if authService.isLoading {
                ModernLoadingView(message: "Initializing Lyo...")
                    .transition(AnimationSystem.Presets.fadeInOut)
            } else if authService.isAuthenticated {
                EnhancedMainTabView()
                    .overlay(alignment: .top) {
                        if !networkManager.isOnline {
                            ModernOfflineIndicatorView()
                        }
                    }
                    .transition(AnimationSystem.Presets.slideUp)
            } else {
                EnhancedAuthenticationView()
                    .transition(AnimationSystem.Presets.slideFromBottom)
            }
        }
        .animation(AnimationSystem.Presets.easeInOut, value: authService.isAuthenticated)
        .animation(AnimationSystem.Presets.easeInOut, value: authService.isLoading)
        .errorHandling()
        .environmentObject(errorManager)
        .onAppear {
            HapticManager.shared.impact(.light)
        }
    }
}

/// Modern offline indicator using design system
struct ModernOfflineIndicatorView: View {
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.small) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(DesignTokens.Colors.error)
            
            Text("No Internet Connection")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.error)
        }
        .padding(.horizontal, DesignTokens.Spacing.medium)
        .padding(.vertical, DesignTokens.Spacing.small)
        .background(
            DesignTokens.Colors.errorBackground
                .cornerRadius(DesignTokens.BorderRadius.medium)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.medium)
                .stroke(DesignTokens.Colors.error, lineWidth: 1)
        )
        .scaleEffect(isVisible ? 1 : 0.8)
        .opacity(isVisible ? 1 : 0)
        .animation(AnimationSystem.Presets.bounceIn, value: isVisible)
        .onAppear {
            isVisible = true
            HapticManager.shared.notification(.warning)
        }
    }
}

#Preview {
    ModernLoadingView()
}

#Preview {
    ModernOfflineIndicatorView()
}
