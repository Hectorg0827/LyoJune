import SwiftUI
import Combine

// MARK: - Error Handling UI Components

struct ErrorBannerView: View {
    let message: String
    let action: (() -> Void)?
    @Binding var isVisible: Bool
    
    var body: some View {
        if isVisible {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.white)
                
                Text(message)
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .medium))
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if let action = action {
                    Button("Retry") {
                        action()
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .semibold))
                }
                
                Button(action: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isVisible = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .font(.system(size: 12, weight: .semibold))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color.red, Color.red.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
        }
    }
}

struct OfflineIndicatorView: View {
    @EnvironmentObject var networkManager: NetworkManager
    
    var body: some View {
        if !networkManager.isOnline {
            HStack {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .semibold))
                
                Text("You're offline")
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .medium))
                
                Spacer()
                
                Text("Some features may be limited")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [Color.orange, Color.orange.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background with blur effect
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Animated Logo or Loading Indicator
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(
                            .linear(duration: 2)
                            .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isAnimating ? 1.1 : 0.9)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
                
                VStack(spacing: 8) {
                    Text("LyoApp")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Preparing your learning experience...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Error Handling View Modifier

struct ErrorHandlingModifier: ViewModifier {
    @EnvironmentObject var errorManager: ErrorManager
    @State private var showErrorBanner = false
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                ErrorBannerView(
                    message: errorManager.currentError?.localizedDescription ?? "",
                    action: errorManager.retryAction,
                    isVisible: $showErrorBanner
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .onReceive(errorManager.$currentError) { error in
                withAnimation(.easeInOut(duration: 0.3)) {
                    showErrorBanner = error != nil
                }
                
                // Auto-hide after 5 seconds
                if error != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showErrorBanner = false
                        }
                        errorManager.clearError()
                    }
                }
            }
    }
}

extension View {
    func errorHandling() -> some View {
        modifier(ErrorHandlingModifier())
    }
}

// MARK: - Error Manager

// MARK: - Network Status View

struct NetworkStatusView: View {
    @EnvironmentObject var networkManager: NetworkManager
    @EnvironmentObject var offlineManager: OfflineManager
    
    var body: some View {
        VStack {
            if offlineManager.isSyncing {
                SyncProgressView(progress: offlineManager.syncProgress)
            } else if !networkManager.isOnline {
                OfflineIndicatorView()
            }
            
            if let message = offlineManager.offlineMessage {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }
        }
    }
}

struct SyncProgressView: View {
    let progress: Double
    
    var body: some View {
        HStack {
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundColor(.blue)
                .font(.system(size: 14))
            
            Text("Syncing...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            ProgressView(value: progress)
                .frame(width: 100)
                .tint(.blue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}
