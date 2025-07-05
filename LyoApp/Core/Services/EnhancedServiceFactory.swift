import Foundation
import SwiftUI
import CoreData

// MARK: - Enhanced Service Factory
@MainActor
class EnhancedServiceFactory: ObservableObject {
    nonisolated static let shared = EnhancedServiceFactory()
    
    // MARK: - Core Services
    @Published private var _networkManager: EnhancedNetworkManager?
    @Published private var _authService: EnhancedAuthService?
    @Published private var _apiService: EnhancedNetworkManager? // Using EnhancedNetworkManager as API service
    @Published private var _webSocketManager: WebSocketManager?
    @Published private var _coreDataManager: DataManager?
    
    private var isInitialized = false
    
    nonisolated private init() {}
    
    // MARK: - Service Getters
    var networkManager: EnhancedNetworkManager {
        if _networkManager == nil {
            initializeServices()
        }
        return _networkManager!
    }
    
    var authService: EnhancedAuthService {
        if _authService == nil {
            initializeServices()
        }
        return _authService!
    }
    
    var apiService: EnhancedNetworkManager {
        if _apiService == nil {
            initializeServices()
        }
        return _apiService!
    }
    
    var webSocketManager: WebSocketManager {
        if _webSocketManager == nil {
            initializeServices()
        }
        return _webSocketManager!
    }
    
    var coreDataManager: DataManager {
        if _coreDataManager == nil {
            initializeServices()
        }
        return _coreDataManager!
    }
    
    // MARK: - Initialization
    private func initializeServices() {
        guard !isInitialized else { return }
        
        // Initialize core services in dependency order
        _networkManager = EnhancedNetworkManager()
        _coreDataManager = DataManager.shared
        _authService = EnhancedAuthService(
            networkManager: _networkManager!
        )
        _apiService = EnhancedNetworkManager() // This implements EnhancedAPIService protocol
        _webSocketManager = WebSocketManager()
        
        isInitialized = true
        
        // Setup real-time connections if authenticated
        Task {
            setupRealTimeConnections()
        }
    }
    
    // MARK: - Real-time Setup
    private func setupRealTimeConnections() {
        guard let authService = _authService,
              authService.isAuthenticated else {
            return
        }
        
        // Connect to WebSocket for real-time updates
        webSocketManager.connect()
        
        // Start background sync if needed
        // coreDataManager.startBackgroundSync()
    }
    
    // MARK: - Service Lifecycle
    func shutdown() {
        webSocketManager.disconnect()
        // coreDataManager.stopBackgroundSync()
        
        _networkManager = nil
        _authService = nil
        _apiService = nil
        _webSocketManager = nil
        _coreDataManager = nil
        
        isInitialized = false
    }
    
    // MARK: - Development Helpers
    #if DEBUG
    func resetForTesting() async {
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        initializeServices()
    }
    #endif
}

// MARK: - Service Factory Environment Key
struct ServiceFactoryKey: @preconcurrency EnvironmentKey {
    @MainActor
    static let defaultValue = EnhancedServiceFactory.shared
}

extension EnvironmentValues {
    var serviceFactory: EnhancedServiceFactory {
        get { self[ServiceFactoryKey.self] }
        set { self[ServiceFactoryKey.self] = newValue }
    }
}

// MARK: - Convenience Extensions
extension View {
    @MainActor
    func withEnhancedServices() -> some View {
        self.environmentObject(EnhancedServiceFactory.shared)
    }
}
