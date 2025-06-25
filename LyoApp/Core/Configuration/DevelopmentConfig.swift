import Foundation

// MARK: - Development Configuration
struct DevelopmentConfig {
    
    // MARK: - Singleton
    static let shared = DevelopmentConfig()
    
    private init() {}
    
    // MARK: - Feature Flags
    var useMockData: Bool {
        return ConfigurationManager.shared.shouldUseMockBackend
    }
    
    var isDebugMode: Bool {
        return ConfigurationManager.shared.isDebugMode
    }
    
    var logLevel: LogLevel {
        return ConfigurationManager.shared.logLevel
    }
    
    // MARK: - Backend Configuration
    var backendURL: String {
        return ConfigurationManager.shared.apiBaseURL
    }
    
    var webSocketURL: String {
        return ConfigurationManager.shared.backendWebSocketURL
    }
    
    // MARK: - Development Features
    var enableMockUser: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    var enableDebugLogging: Bool {
        return isDebugMode && logLevel.priority <= LogLevel.debug.priority
    }
    
    var enableNetworkLogging: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Testing Configuration
    var useInMemoryStorage: Bool {
        return ProcessInfo.processInfo.arguments.contains("--uitesting")
    }
    
    var skipOnboarding: Bool {
        return ProcessInfo.processInfo.arguments.contains("--skip-onboarding")
    }
    
    // MARK: - Performance Settings
    var cacheTimeout: TimeInterval {
        return isDebugMode ? 60 : 300 // 1 minute in debug, 5 minutes in release
    }
    
    var networkTimeout: TimeInterval {
        return 30.0
    }
    
    // MARK: - UI Configuration
    var showDebugInfo: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    var enableHapticFeedback: Bool {
        return true
    }
    
    var animationDuration: Double {
        return useInMemoryStorage ? 0.0 : 0.3 // Disable animations in UI tests
    }
}

// MARK: - Environment Detection
extension DevelopmentConfig {
    
    enum Environment {
        case development
        case staging
        case production
    }
    
    var currentEnvironment: Environment {
        #if DEBUG
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }
    
    var isProduction: Bool {
        return currentEnvironment == .production
    }
    
    var environmentName: String {
        switch currentEnvironment {
        case .development:
            return "Development"
        case .staging:
            return "Staging"
        case .production:
            return "Production"
        }
    }
}
