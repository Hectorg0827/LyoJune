import Foundation

// MARK: - Configuration Manager
struct ConfigurationManager {
    static let shared = ConfigurationManager()
    
    private let bundle = Bundle.main
    private var configDictionary: [String: Any] = [:]
    
    private init() {
        loadConfiguration()
    }
    
    // MARK: - Configuration Loading
    private mutating func loadConfiguration() {
        // Try to load from .env file first (for development)
        loadFromEnvironmentFile()
        
        // Load from Info.plist as fallback
        loadFromInfoPlist()
        
        // Load from build configuration
        loadFromBuildConfiguration()
    }
    
    private mutating func loadFromEnvironmentFile() {
        // Try multiple locations for .env file
        var envContent: String?
        
        // First try bundle resource (added to Xcode project)
        if let envPath = bundle.path(forResource: ".env", ofType: nil) {
            envContent = try? String(contentsOfFile: envPath, encoding: .utf8)
        }
        
        // Fallback to project root (development)
        if envContent == nil {
            let projectRoot = bundle.bundlePath.replacingOccurrences(of: "/build/", with: "/")
            let envPath = projectRoot + "/.env"
            envContent = try? String(contentsOfFile: envPath, encoding: .utf8)
        }
        
        guard let content = envContent else {
            print("⚠️ .env file not found - using default configuration")
            return
        }
        
        
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip comments and empty lines
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                continue
            }
            
            // Parse key=value pairs
            let components = trimmedLine.components(separatedBy: "=")
            if components.count >= 2 {
                let key = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let value = components.dropFirst().joined(separator: "=").trimmingCharacters(in: .whitespacesAndNewlines)
                configDictionary[key] = value
            }
        }
        
        print("✅ Loaded configuration from .env file")
    }
    
    private mutating func loadFromInfoPlist() {
        if let path = bundle.path(forResource: "Config", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path) as? [String: Any] {
            configDictionary.merge(plist) { (_, new) in new }
        }
    }
    
    private mutating func loadFromBuildConfiguration() {
        // Load configuration based on build settings
        #if DEBUG
        configDictionary["DEBUG_MODE"] = "true"
        configDictionary["LOG_LEVEL"] = "debug"
        #else
        configDictionary["DEBUG_MODE"] = "false"
        configDictionary["LOG_LEVEL"] = "error"
        #endif
        
        // Add default values if not already set
        if configDictionary["BACKEND_BASE_URL"] == nil {
            configDictionary["BACKEND_BASE_URL"] = "https://api.lyo.app/v1"
        }
    }
    
    // MARK: - Configuration Access
    func string(for key: ConfigKey) -> String? {
        return configDictionary[key.rawValue] as? String
    }
    
    func bool(for key: ConfigKey) -> Bool {
        guard let stringValue = configDictionary[key.rawValue] as? String else {
            return false
        }
        return stringValue.lowercased() == "true"
    }
    
    func int(for key: ConfigKey) -> Int? {
        guard let stringValue = configDictionary[key.rawValue] as? String else {
            return nil
        }
        return Int(stringValue)
    }
    
    func double(for key: ConfigKey) -> Double? {
        guard let stringValue = configDictionary[key.rawValue] as? String else {
            return nil
        }
        return Double(stringValue)
    }
    
    // MARK: - Required Configuration
    func requiredString(for key: ConfigKey) -> String {
        guard let value = string(for: key), !value.isEmpty else {
            fatalError("Required configuration key '\(key.rawValue)' is missing or empty")
        }
        return value
    }
}

// MARK: - Configuration Keys
enum ConfigKey: String, CaseIterable {
    // Backend Configuration
    case backendBaseURL = "BACKEND_BASE_URL"
    case backendWebSocketURL = "BACKEND_WS_URL"
    
    // Authentication
    case jwtSecretKey = "JWT_SECRET_KEY"
    case apiKey = "API_KEY"
    
    // AI Services
    case gemmaApiKey = "GEMMA_API_KEY"
    case gemmaApiEndpoint = "GEMMA_API_ENDPOINT"
    case openaiApiKey = "OPENAI_API_KEY"
    case claudeApiKey = "CLAUDE_API_KEY"
    
    // Analytics
    case analyticsApiKey = "ANALYTICS_API_KEY"
    case mixpanelToken = "MIXPANEL_TOKEN"
    
    // Push Notifications
    case fcmServerKey = "FCM_SERVER_KEY"
    case apnsKeyId = "APNS_KEY_ID"
    case apnsTeamId = "APNS_TEAM_ID"
    
    // Third Party
    case stripePublishableKey = "STRIPE_PUBLISHABLE_KEY"
    case firebaseConfigPath = "FIREBASE_CONFIG_PATH"
    
    // Development
    case debugMode = "DEBUG_MODE"
    case mockBackend = "MOCK_BACKEND"
    case logLevel = "LOG_LEVEL"
}

// MARK: - Secure Configuration Access
extension ConfigurationManager {
    
    // MARK: - API Configuration
    var apiBaseURL: String {
        return string(for: .backendBaseURL) ?? "https://api.lyo.app/v1"
    }
    
    var backendBaseURL: String {
        return string(for: .backendBaseURL) ?? "https://api.lyo.app/v1"
    }
    
    var backendWebSocketURL: String {
        return string(for: .backendWebSocketURL) ?? "wss://api.lyo.app/v1/ws"
    }
    
    var webSocketURL: String {
        return backendWebSocketURL
    }
    
    // MARK: - API Keys (Secure Access)
    var gemmaApiKey: String? {
        // First try to get from Keychain (production)
        if let keychainKey = KeychainHelper.shared.retrieveData(for: "gemma_api_key"),
           let key = String(data: keychainKey, encoding: .utf8) {
            return key
        }
        
        // Fallback to configuration (development)
        return string(for: .gemmaApiKey)
    }
    
    var openaiApiKey: String? {
        if let keychainKey = KeychainHelper.shared.retrieveData(for: "openai_api_key"),
           let key = String(data: keychainKey, encoding: .utf8) {
            return key
        }
        return string(for: .openaiApiKey)
    }
    
    var claudeApiKey: String? {
        if let keychainKey = KeychainHelper.shared.retrieveData(for: "claude_api_key"),
           let key = String(data: keychainKey, encoding: .utf8) {
            return key
        }
        return string(for: .claudeApiKey)
    }
    
    // MARK: - Feature Flags
    var isDebugMode: Bool {
        return bool(for: .debugMode)
    }
    
    var shouldUseMockBackend: Bool {
        return bool(for: .mockBackend)
    }
    
    var logLevel: LogLevel {
        guard let levelString = string(for: .logLevel) else {
            return .error
        }
        return LogLevel(rawValue: levelString) ?? .error
    }
    
    // MARK: - Secure Key Storage
    func storeSecureKey(_ key: String, for identifier: String) -> Bool {
        guard let keyData = key.data(using: .utf8) else { return false }
        return KeychainHelper.shared.save(keyData, for: identifier)
    }
    
    func removeSecureKey(for identifier: String) -> Bool {
        return KeychainHelper.shared.delete(for: identifier)
    }
}

// MARK: - Log Level
enum LogLevel: String, CaseIterable {
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"
    
    var priority: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .warning: return 2
        case .error: return 3
        }
    }
}

// MARK: - Configuration Validation
extension ConfigurationManager {
    
    func validateConfiguration() -> [ConfigurationError] {
        var errors: [ConfigurationError] = []
        
        // Validate required backend configuration
        if backendBaseURL.isEmpty {
            errors.append(.missingRequiredKey(.backendBaseURL))
        }
        
        // Validate URL formats
        if URL(string: backendBaseURL) == nil {
            errors.append(.invalidURL(.backendBaseURL))
        }
        
        if let wsURL = string(for: .backendWebSocketURL), URL(string: wsURL) == nil {
            errors.append(.invalidURL(.backendWebSocketURL))
        }
        
        // Validate API keys in production
        #if !DEBUG
        if gemmaApiKey?.isEmpty ?? true {
            errors.append(.missingAPIKey("Gemma API key is required for production"))
        }
        #endif
        
        return errors
    }
}

// MARK: - Configuration Errors
enum ConfigurationError: LocalizedError {
    case missingRequiredKey(ConfigKey)
    case invalidURL(ConfigKey)
    case missingAPIKey(String)
    
    var errorDescription: String? {
        switch self {
        case .missingRequiredKey(let key):
            return "Required configuration key '\(key.rawValue)' is missing"
        case .invalidURL(let key):
            return "Invalid URL format for configuration key '\(key.rawValue)'"
        case .missingAPIKey(let message):
            return message
        }
    }
}

// MARK: - Development Helpers
#if DEBUG
extension ConfigurationManager {
    
    func printConfiguration() {
        print("=== LyoApp Configuration ===")
        print("Backend URL: \(backendBaseURL)")
        print("Debug Mode: \(isDebugMode)")
        print("Mock Backend: \(shouldUseMockBackend)")
        print("Log Level: \(logLevel.rawValue)")
        
        // Don't print sensitive keys in logs
        print("Gemma API Key: \(gemmaApiKey != nil ? "✓ Configured" : "✗ Missing")")
        print("OpenAI API Key: \(openaiApiKey != nil ? "✓ Configured" : "✗ Missing")")
        print("Claude API Key: \(claudeApiKey != nil ? "✓ Configured" : "✗ Missing")")
        print("=============================")
    }
}
#endif
