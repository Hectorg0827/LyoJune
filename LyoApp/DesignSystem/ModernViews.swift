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
            
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Modern loading animation
                ZStack {
                    Circle()
                        .stroke(
                            DesignTokens.Colors.primary.opacity(0.2),
                            lineWidth: 4
                        )
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            DesignTokens.Colors.primary,
                            style: StrokeStyle(
                                lineWidth: DesignTokens.BorderRadius.medium,
                                lineCap: .round
                            )
                        )
                        .frame(width: 60, height: 60)
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
    @EnvironmentObject var authService: EnhancedAuthService
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var networkManager: EnhancedNetworkManager
    @StateObject private var errorManager = ErrorManager.shared
    @StateObject private var offlineManager = OfflineManager.shared
    @State private var showingOfflineAlert = false
    
    var body: some View {
        ZStack {
            if authService.isLoading {
                ModernLoadingView(message: "Initializing Lyo...")
                    .transition(.opacity)
            } else if authService.isAuthenticated {
                EnhancedMainTabView()
                    .overlay(alignment: .top) {
                        if !networkManager.isConnected {
                            ModernOfflineIndicatorView()
                        }
                    }
                    .transition(.move(edge: .bottom))
            } else {
                EnhancedAuthenticationView()
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(AnimationPresets.easeInOut, value: authService.isAuthenticated)
        .animation(AnimationPresets.easeInOut, value: authService.isLoading)
        .environmentObject(errorManager)
        .onAppear {
            HapticManager.shared.lightImpact()
        }
    }
}

/// Modern offline indicator using design system
struct ModernOfflineIndicatorView: View {
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(DesignTokens.Colors.error)
            
            Text("No Internet Connection")
                .font(DesignTokens.Typography.labelSmall)
                .foregroundColor(DesignTokens.Colors.error)
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(
            DesignTokens.Colors.error.opacity(0.1)
                .cornerRadius(DesignTokens.BorderRadius.md)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.md)
                .stroke(DesignTokens.Colors.error, lineWidth: 1)
        )
        .scaleEffect(isVisible ? 1 : 0.8)
        .opacity(isVisible ? 1 : 0)
        .animation(AnimationPresets.springBouncy, value: isVisible)
        .onAppear {
            isVisible = true
            HapticManager.shared.warning()
        }
    }
}

#Preview {
    ModernLoadingView()
}

#Preview {
    ModernOfflineIndicatorView()
}
