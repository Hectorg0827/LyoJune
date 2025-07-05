import SwiftUI

@main
struct LyoApp: App {
    @StateObject private var serviceFactory = EnhancedServiceFactory.shared
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(serviceFactory)
                .environmentObject(serviceFactory.authService)
                .environmentObject(serviceFactory.networkManager)
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
            let isAuthenticated = serviceFactory.authService.isAuthenticated
            
            if isAuthenticated {
                // Start background sync and WebSocket connections
                await serviceFactory.coreDataManager.startSync()
                serviceFactory.webSocketManager.connect()
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
            let isAuthenticated = serviceFactory.authService.isAuthenticated
            
            // Always perform network operations for production app
            await serviceFactory.networkManager.checkConnectivity()
            
            if isAuthenticated {
                await serviceFactory.coreDataManager.startSync()
                serviceFactory.webSocketManager.reconnectIfNeeded()
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
            serviceFactory.shutdown()
        }
    }
}