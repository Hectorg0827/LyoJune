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
                    .transition(.opacity)
            } else if authService.isAuthenticated {
                MainTabView()
                    .overlay(alignment: .top) {
                        if !networkManager.isConnected {
                            ModernOfflineIndicatorView()
                        }
                    }
                    .transition(.move(edge: .top))
            } else {
                AuthenticationView()
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut, value: authService.isAuthenticated)
        .animation(.easeInOut, value: authService.isLoading)
        .environmentObject(errorManager)
        .onAppear {
            HapticManager.shared.impactOccurred(style: .light)
        }
        .environmentObject(offlineManager)
        .onReceive(networkManager.$isConnected) { isConnected in
            if !isConnected && authService.isAuthenticated {
                showingOfflineAlert = true
            }
        }
        .onReceive(authService.$authError) { authError in
            if let authError = authError {
                errorManager.handle(authError, context: "Authentication")
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