import SwiftUI
import Foundation

struct ContentView: View {
    @StateObject private var authService = EnhancedAuthService.shared
    @EnvironmentObject var appState: AppState
    @State private var showingOfflineAlert = false
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
        .animation(.easeInOut, value: authService.isAuthenticated)
        .onReceive(NotificationCenter.default.publisher(for: .errorOccurred)) { notification in
            if let error = notification.object as? Error {
                // Handle error display
                print("Error occurred: \(error.localizedDescription)")
            }
        }
    }
}

// Extension for notification names
extension Notification.Name {
    static let errorOccurred = Notification.Name("errorOccurred")
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}