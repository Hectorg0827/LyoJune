import Foundation
import SwiftUI

// MARK: - Enhanced Service Factory
@MainActor
class EnhancedServiceFactory: ObservableObject {
    static let shared = EnhancedServiceFactory()
    
    // MARK: - Core Services
    @Published private var _networkManager: EnhancedNetworkManager?
    @Published private var _authService: EnhancedAuthService?
    @Published private var _apiService: EnhancedAPIService?
    @Published private var _webSocketManager: WebSocketManager?
    @Published private var _coreDataManager: CoreDataManager?
    
    private var isInitialized = false
    
    private init() {}
    
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
    
    var apiService: EnhancedAPIService {
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
    
    var coreDataManager: CoreDataManager {
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
        _coreDataManager = CoreDataManager()
        _authService = EnhancedAuthService(
            networkManager: _networkManager!,
            coreDataManager: _coreDataManager!
        )
        _apiService = EnhancedAPIService(
            networkManager: _networkManager!,
            authService: _authService!,
            coreDataManager: _coreDataManager!
        )
        _webSocketManager = WebSocketManager(
            authService: _authService!
        )
        
        isInitialized = true
        
        // Setup real-time connections if authenticated
        Task {
            await setupRealTimeConnections()
        }
    }
    
    // MARK: - Real-time Setup
    private func setupRealTimeConnections() async {
        guard let authService = _authService,
              await authService.isAuthenticated else {
            return
        }
        
        // Connect to WebSocket for real-time updates
        await webSocketManager.connect()
        
        // Start background sync
        await coreDataManager.startBackgroundSync()
    }
    
    // MARK: - Service Lifecycle
    func shutdown() async {
        await webSocketManager.disconnect()
        await coreDataManager.stopBackgroundSync()
        
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
        await shutdown()
        await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        initializeServices()
    }
    #endif
}

// MARK: - Service Factory Environment Key
struct ServiceFactoryKey: EnvironmentKey {
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
    func withEnhancedServices() -> some View {
        self.environmentObject(EnhancedServiceFactory.shared)
    }
}
