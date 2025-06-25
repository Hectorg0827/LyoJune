import SwiftUI

@main
struct LyoApp: App {
    @StateObject private var authService = AuthService.shared
    @StateObject private var appState = AppState()
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var networkManager = NetworkManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(appState)
                .environmentObject(dataManager)
                .environmentObject(networkManager)
                .preferredColorScheme(.dark)
                .onAppear {
                    setupAppInitialization()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    handleAppBecameActive()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    handleAppWillResignActive()
                }
        }
    }
    
    private func setupAppInitialization() {
        // Initialize core services
        Task {
            await dataManager.syncData()
        }
        
        // Setup analytics
        if Constants.FeatureFlags.enableAnalytics {
            Task {
                await AnalyticsAPIService.shared.trackEvent(Constants.AnalyticsEvents.appLaunched)
            }
        }
    }
    
    private func handleAppBecameActive() {
        // Refresh data when app becomes active
        Task {
            await dataManager.syncData()
        }
    }
    
    private func handleAppWillResignActive() {
        // Save any pending data
        dataManager.save()
    }
}