import SwiftUI

@main
struct LyoApp: App {
    @StateObject private var serviceFactory = EnhancedServiceFactory.shared
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(serviceFactory)
                .environmentObject(appState)
                .withEnhancedServices()
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
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                    handleAppWillTerminate()
                }
        }
    }
    
    private func setupAppInitialization() {
        // Initialize enhanced services
        Task {
            // Check authentication status
            let isAuthenticated = await serviceFactory.authService.isAuthenticated
            if isAuthenticated {
                await serviceFactory.coreDataManager.startBackgroundSync()
                await serviceFactory.webSocketManager.connect()
            }
            
            // Track app launch
            await AnalyticsAPIService.shared.trackEvent("app_launched", parameters: [
                "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
                "platform": "ios"
            ])
        }
    }
    
    private func handleAppBecameActive() {
        // Refresh data and reconnect real-time services when app becomes active
        Task {
            await serviceFactory.networkManager.checkConnectivity()
            
            let isAuthenticated = await serviceFactory.authService.isAuthenticated
            if isAuthenticated {
                await serviceFactory.coreDataManager.syncPendingChanges()
                await serviceFactory.webSocketManager.reconnectIfNeeded()
            }
        }
    }
    
    private func handleAppWillResignActive() {
        // Pause real-time connections to save battery
        serviceFactory.webSocketManager.pauseConnection()
    }
    
    private func handleAppWillTerminate() {
        // Cleanup services on app termination
        Task {
            await serviceFactory.shutdown()
        }
    }
}