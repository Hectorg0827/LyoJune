import SwiftUI
import Foundation

struct ContentView: View {
    @EnvironmentObject var authService: EnhancedAuthService
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var networkManager: EnhancedNetworkManager
    @StateObject private var errorManager = ErrorManager.shared
    @StateObject private var offlineManager = OfflineManager.shared
    @State private var showingOfflineAlert = false
    
    var body: some View {
        Group {
            if authService.isLoading {
                ModernLoadingView(message: "Initializing Lyo...")
                    .transition(AnimationSystem.Presets.fadeInOut)
            } else if authService.isAuthenticated {
                MainTabView()
                    .overlay(alignment: .top) {
                        if !networkManager.isOnline {
                            ModernOfflineIndicatorView()
                        }
                    }
                    .transition(AnimationSystem.Presets.slideUp)
            } else {
                AuthenticationView()
                    .transition(AnimationSystem.Presets.slideFromBottom)
            }
        }
        .animation(AnimationSystem.Presets.easeInOut, value: authService.isAuthenticated)
        .animation(AnimationSystem.Presets.easeInOut, value: authService.isLoading)
        .errorHandling() // Add global error handling
        .environmentObject(errorManager)
        .onAppear {
            HapticManager.shared.impact(.light)
        }
        .environmentObject(offlineManager)
        .onReceive(networkManager.$isOnline) { isOnline in
            if !isOnline && authService.isAuthenticated {
                showingOfflineAlert = true
            }
        }
        .onReceive(authService.$errorMessage) { errorMessage in
            if let errorMessage = errorMessage {
                errorManager.handle(AuthError.invalidCredentials, context: "Authentication")
            }
        }
        .alert("Offline Mode", isPresented: $showingOfflineAlert) {
            Button("OK") { }
        } message: {
            Text("You're currently offline. Some features may be limited, but you can still access your downloaded content.")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(EnhancedAuthService.shared)
        .environmentObject(AppState())
        .environmentObject(EnhancedNetworkManager.shared)
}