import SwiftUI
import Foundation

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var networkManager: NetworkManager
    @StateObject private var errorManager = ErrorManager.shared
    @StateObject private var offlineManager = OfflineManager.shared
    @State private var showingOfflineAlert = false
    
    var body: some View {
        Group {
            if authService.isLoading {
                LoadingView()
            } else if authService.isAuthenticated {
                MainTabView()
                    .overlay(alignment: .top) {
                        if !networkManager.isOnline {
                            OfflineIndicatorView()
                        }
                    }
            } else {
                AuthenticationView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: authService.isLoading)
        .errorHandling() // Add global error handling
        .environmentObject(errorManager)
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

struct OfflineIndicatorView: View {
    var body: some View {
        HStack {
            Image(systemName: "wifi.slash")
                .foregroundColor(.white)
            Text("Offline")
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.red.opacity(0.7))
        .cornerRadius(16)
        .padding(.top, 8)
    }
}

struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.2),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: 0.8)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(
                            Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                }
                
                VStack(spacing: 8) {
                    Text("LyoApp")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Loading your learning experience...")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService.shared)
        .environmentObject(AppState())
        .environmentObject(NetworkManager.shared)
}