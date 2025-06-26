//
//  Phase3AIntegrationManager.swift
//  LyoApp
//
//  Coordinator for all Phase 3A advanced iOS features
//

import Foundation
import SwiftUI
import Combine

// MARK: - Phase 3A Feature Status
enum Phase3AFeature: String, CaseIterable {
    case coreData = "core_data"
    case biometricAuth = "biometric_auth"
    case notifications = "notifications"
    case siriShortcuts = "siri_shortcuts"
    case spotlight = "spotlight"
    case backgroundTasks = "background_tasks"
    case widgets = "widgets"
    case security = "security"
    
    var displayName: String {
        switch self {
        case .coreData: return "Core Data & Offline Sync"
        case .biometricAuth: return "Biometric Authentication"
        case .notifications: return "Rich Notifications"
        case .siriShortcuts: return "Siri Shortcuts"
        case .spotlight: return "Spotlight Search"
        case .backgroundTasks: return "Background Processing"
        case .widgets: return "Home Screen Widgets"
        case .security: return "Advanced Security"
        }
    }
    
    var systemImage: String {
        switch self {
        case .coreData: return "externaldrive.connected.to.line.below"
        case .biometricAuth: return "faceid"
        case .notifications: return "bell.badge"
        case .siriShortcuts: return "mic.circle"
        case .spotlight: return "magnifyingglass.circle"
        case .backgroundTasks: return "arrow.triangle.2.circlepath.circle"
        case .widgets: return "rectangle.3.group"
        case .security: return "lock.shield"
        }
    }
    
    var priority: Int {
        switch self {
        case .coreData: return 1
        case .security: return 2
        case .biometricAuth: return 3
        case .notifications: return 4
        case .backgroundTasks: return 5
        case .spotlight: return 6
        case .siriShortcuts: return 7
        case .widgets: return 8
        }
    }
}

struct Phase3AFeatureStatus {
    let feature: Phase3AFeature
    var isEnabled: Bool
    var isConfigured: Bool
    var lastUpdated: Date?
    var errorMessage: String?
    
    var status: FeatureStatus {
        if let errorMessage = errorMessage, !errorMessage.isEmpty {
            return .error
        } else if isEnabled && isConfigured {
            return .active
        } else if isConfigured {
            return .configured
        } else {
            return .inactive
        }
    }
}

enum FeatureStatus: String, CaseIterable {
    case inactive = "inactive"
    case configured = "configured"
    case active = "active"
    case error = "error"
    
    var color: Color {
        switch self {
        case .inactive: return .gray
        case .configured: return .yellow
        case .active: return .green
        case .error: return .red
        }
    }
    
    var displayName: String {
        switch self {
        case .inactive: return "Inactive"
        case .configured: return "Configured"
        case .active: return "Active"
        case .error: return "Error"
        }
    }
}

// MARK: - Phase 3A Configuration
struct Phase3AConfiguration: Codable {
    var enabledFeatures: Set<String>
    var autoStartFeatures: Bool
    var backgroundSyncInterval: TimeInterval
    var securityLevel: String
    var notificationSettings: [String: Bool]
    var lastConfigUpdate: Date
    
    static let `default` = Phase3AConfiguration(
        enabledFeatures: Set(Phase3AFeature.allCases.map { $0.rawValue }),
        autoStartFeatures: true,
        backgroundSyncInterval: 15 * 60, // 15 minutes
        securityLevel: "standard",
        notificationSettings: [
            "study_reminders": true,
            "streak_reminders": true,
            "achievements": true,
            "course_updates": false
        ],
        lastConfigUpdate: Date()
    )
}

// MARK: - Phase3AIntegrationManager
@MainActor
class Phase3AIntegrationManager: ObservableObject {
    
    // MARK: - Shared Instance
    static let shared = Phase3AIntegrationManager()
    
    // MARK: - Published Properties
    @Published var featureStatuses: [Phase3AFeature: Phase3AFeatureStatus] = [:]
    @Published var configuration = Phase3AConfiguration.default
    @Published var isInitialized = false
    @Published var isInitializing = false
    @Published var initializationProgress: Double = 0.0
    @Published var overallHealth: SystemHealth = .unknown
    
    // MARK: - Managers
    private var coreDataManager: EnhancedCoreDataManager?
    private var biometricAuthManager: BiometricAuthManager?
    private var notificationManager: NotificationManager?
    private var siriShortcutsManager: SiriShortcutsManager?
    private var spotlightManager: SpotlightManager?
    private var backgroundTaskManager: BackgroundTaskManager?
    private var widgetDataProvider: WidgetDataProvider?
    private var securityManager: SecurityManager?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let configurationKey = "phase3a_configuration"
    private var healthCheckTimer: Timer?
    
    // MARK: - System Health
    enum SystemHealth: String, CaseIterable {
        case unknown = "unknown"
        case excellent = "excellent"
        case good = "good"
        case warning = "warning"
        case critical = "critical"
        
        var color: Color {
            switch self {
            case .unknown: return .gray
            case .excellent: return .green
            case .good: return .blue
            case .warning: return .yellow
            case .critical: return .red
            }
        }
        
        var displayName: String {
            switch self {
            case .unknown: return "Unknown"
            case .excellent: return "Excellent"
            case .good: return "Good"
            case .warning: return "Warning"
            case .critical: return "Critical"
            }
        }
        
        var systemImage: String {
            switch self {
            case .unknown: return "questionmark.circle"
            case .excellent: return "checkmark.circle.fill"
            case .good: return "checkmark.circle"
            case .warning: return "exclamationmark.triangle"
            case .critical: return "xmark.circle.fill"
            }
        }
    }
    
    // MARK: - Initialization
    init() {
        loadConfiguration()
        initializeFeatureStatuses()
        setupObservers()
    }
    
    private func loadConfiguration() {
        if let data = UserDefaults.standard.data(forKey: configurationKey),
           let decodedConfig = try? JSONDecoder().decode(Phase3AConfiguration.self, from: data) {
            configuration = decodedConfig
        }
    }
    
    private func saveConfiguration() {
        if let data = try? JSONEncoder().encode(configuration) {
            UserDefaults.standard.set(data, forKey: configurationKey)
        }
    }
    
    private func initializeFeatureStatuses() {
        for feature in Phase3AFeature.allCases {
            featureStatuses[feature] = Phase3AFeatureStatus(
                feature: feature,
                isEnabled: configuration.enabledFeatures.contains(feature.rawValue),
                isConfigured: false,
                lastUpdated: nil,
                errorMessage: nil
            )
        }
    }
    
    private func setupObservers() {
        // Observe configuration changes
        $configuration
            .dropFirst()
            .sink { [weak self] _ in
                self?.saveConfiguration()
            }
            .store(in: &cancellables)
        
        // Start health monitoring
        startHealthMonitoring()
    }
    
    // MARK: - Initialization Process
    
    /// Initialize all Phase 3A features
    func initializeAllFeatures() async {
        guard !isInitializing else { return }
        
        isInitializing = true
        initializationProgress = 0.0
        
        let enabledFeatures = Phase3AFeature.allCases
            .filter { configuration.enabledFeatures.contains($0.rawValue) }
            .sorted { $0.priority < $1.priority }
        
        let progressIncrement = 1.0 / Double(enabledFeatures.count)
        
        print("🚀 Starting Phase 3A initialization with \(enabledFeatures.count) features...")
        
        for (index, feature) in enabledFeatures.enumerated() {
            print("📱 Initializing \(feature.displayName)...")
            
            do {
                try await initializeFeature(feature)
                updateFeatureStatus(feature, isConfigured: true, error: nil)
                print("✅ \(feature.displayName) initialized successfully")
            } catch {
                updateFeatureStatus(feature, isConfigured: false, error: error.localizedDescription)
                print("❌ Failed to initialize \(feature.displayName): \(error)")
            }
            
            initializationProgress = Double(index + 1) * progressIncrement
        }
        
        isInitialized = true
        isInitializing = false
        initializationProgress = 1.0
        
        await updateSystemHealth()
        
        print("🎉 Phase 3A initialization completed!")
        
        // Start auto-features if enabled
        if configuration.autoStartFeatures {
            await startAllFeatures()
        }
    }
    
    private func initializeFeature(_ feature: Phase3AFeature) async throws {
        switch feature {
        case .coreData:
            coreDataManager = EnhancedCoreDataManager.shared
            
        case .biometricAuth:
            biometricAuthManager = BiometricAuthManager()
            
        case .notifications:
            notificationManager = NotificationManager()
            let granted = await notificationManager!.requestAuthorization()
            if !granted {
                throw Phase3AError.featureNotAuthorized("Notification permission denied")
            }
            
        case .siriShortcuts:
            siriShortcutsManager = SiriShortcutsManager()
            
        case .spotlight:
            spotlightManager = SpotlightManager()
            await spotlightManager!.indexAllContent()
            
        case .backgroundTasks:
            guard let coreData = coreDataManager,
                  let networkManager = EnhancedNetworkManager.shared,
                  let notifications = notificationManager,
                  let spotlight = spotlightManager else {
                throw Phase3AError.dependencyMissing("Required managers not initialized")
            }
            
            backgroundTaskManager = BackgroundTaskManager(
                coreDataManager: coreData,
                networkManager: networkManager,
                notificationManager: notifications,
                spotlightManager: spotlight
            )
            
        case .widgets:
            guard let coreData = coreDataManager else {
                throw Phase3AError.dependencyMissing("Core Data manager required for widgets")
            }
            
            widgetDataProvider = WidgetDataProvider(coreDataManager: coreData)
            await widgetDataProvider!.refreshWidgetData()
            
        case .security:
            securityManager = SecurityManager.shared
            await securityManager!.performSecurityCheck()
        }
    }
    
    // MARK: - Feature Management
    
    /// Start all configured features
    func startAllFeatures() async {
        for feature in Phase3AFeature.allCases {
            if configuration.enabledFeatures.contains(feature.rawValue) {
                await startFeature(feature)
            }
        }
        
        await updateSystemHealth()
    }
    
    /// Start specific feature
    func startFeature(_ feature: Phase3AFeature) async {
        guard featureStatuses[feature]?.isConfigured == true else {
            print("⚠️ Cannot start \(feature.displayName) - not configured")
            return
        }
        
        do {
            switch feature {
            case .coreData:
                // Core Data is always running once initialized
                break
                
            case .biometricAuth:
                await biometricAuthManager?.evaluateBiometricAvailability()
                
            case .notifications:
                await notificationManager?.refreshPendingNotifications()
                
            case .siriShortcuts:
                siriShortcutsManager?.refreshDonatedShortcuts()
                
            case .spotlight:
                // Spotlight indexing runs automatically
                break
                
            case .backgroundTasks:
                await backgroundTaskManager?.scheduleBackgroundTasks()
                
            case .widgets:
                await widgetDataProvider?.refreshWidgetData()
                
            case .security:
                await securityManager?.performSecurityCheck()
            }
            
            updateFeatureStatus(feature, isEnabled: true, error: nil)
            print("▶️ Started \(feature.displayName)")
            
        } catch {
            updateFeatureStatus(feature, isEnabled: false, error: error.localizedDescription)
            print("❌ Failed to start \(feature.displayName): \(error)")
        }
    }
    
    /// Stop specific feature
    func stopFeature(_ feature: Phase3AFeature) async {
        updateFeatureStatus(feature, isEnabled: false, error: nil)
        print("⏹️ Stopped \(feature.displayName)")
    }
    
    /// Toggle feature on/off
    func toggleFeature(_ feature: Phase3AFeature) async {
        if configuration.enabledFeatures.contains(feature.rawValue) {
            configuration.enabledFeatures.remove(feature.rawValue)
            await stopFeature(feature)
        } else {
            configuration.enabledFeatures.insert(feature.rawValue)
            if !isFeatureConfigured(feature) {
                try? await initializeFeature(feature)
            }
            await startFeature(feature)
        }
    }
    
    // MARK: - Status Management
    
    private func updateFeatureStatus(
        _ feature: Phase3AFeature,
        isEnabled: Bool? = nil,
        isConfigured: Bool? = nil,
        error: String? = nil
    ) {
        var status = featureStatuses[feature] ?? Phase3AFeatureStatus(
            feature: feature,
            isEnabled: false,
            isConfigured: false,
            lastUpdated: nil,
            errorMessage: nil
        )
        
        if let isEnabled = isEnabled {
            status.isEnabled = isEnabled
        }
        
        if let isConfigured = isConfigured {
            status.isConfigured = isConfigured
        }
        
        if let error = error {
            status.errorMessage = error
        } else if error == nil && status.errorMessage != nil {
            status.errorMessage = nil
        }
        
        status.lastUpdated = Date()
        featureStatuses[feature] = status
    }
    
    private func isFeatureConfigured(_ feature: Phase3AFeature) -> Bool {
        return featureStatuses[feature]?.isConfigured ?? false
    }
    
    // MARK: - Health Monitoring
    
    private func startHealthMonitoring() {
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            Task { @MainActor in
                await self.updateSystemHealth()
            }
        }
    }
    
    private func updateSystemHealth() async {
        let activeFeatures = featureStatuses.values.filter { $0.isEnabled && $0.isConfigured }
        let errorFeatures = featureStatuses.values.filter { $0.status == .error }
        let totalFeatures = featureStatuses.count
        
        let healthScore = calculateHealthScore(
            activeFeatures: activeFeatures.count,
            errorFeatures: errorFeatures.count,
            totalFeatures: totalFeatures
        )
        
        overallHealth = determineHealthLevel(score: healthScore)
    }
    
    private func calculateHealthScore(activeFeatures: Int, errorFeatures: Int, totalFeatures: Int) -> Double {
        let baseScore = Double(activeFeatures) / Double(totalFeatures)
        let errorPenalty = Double(errorFeatures) * 0.2
        return max(0.0, baseScore - errorPenalty)
    }
    
    private func determineHealthLevel(score: Double) -> SystemHealth {
        switch score {
        case 0.9...1.0: return .excellent
        case 0.7..<0.9: return .good
        case 0.4..<0.7: return .warning
        case 0.0..<0.4: return .critical
        default: return .unknown
        }
    }
    
    // MARK: - Public Interface
    
    /// Get current status of all features
    func getFeatureStatus() -> [Phase3AFeature: Phase3AFeatureStatus] {
        return featureStatuses
    }
    
    /// Get status of specific feature
    func getFeatureStatus(_ feature: Phase3AFeature) -> Phase3AFeatureStatus? {
        return featureStatuses[feature]
    }
    
    /// Check if feature is active
    func isFeatureActive(_ feature: Phase3AFeature) -> Bool {
        return featureStatuses[feature]?.status == .active
    }
    
    /// Get system health report
    func getSystemHealthReport() -> [String: Any] {
        let activeCount = featureStatuses.values.filter { $0.status == .active }.count
        let errorCount = featureStatuses.values.filter { $0.status == .error }.count
        let configuredCount = featureStatuses.values.filter { $0.isConfigured }.count
        
        return [
            "overall_health": overallHealth.rawValue,
            "active_features": activeCount,
            "configured_features": configuredCount,
            "error_features": errorCount,
            "total_features": featureStatuses.count,
            "health_score": calculateHealthScore(
                activeFeatures: activeCount,
                errorFeatures: errorCount,
                totalFeatures: featureStatuses.count
            ),
            "last_check": Date()
        ]
    }
    
    /// Update configuration
    func updateConfiguration(_ newConfig: Phase3AConfiguration) {
        configuration = newConfig
        Task {
            await updateSystemHealth()
        }
    }
    
    deinit {
        healthCheckTimer?.invalidate()
    }
}

// MARK: - Phase 3A Errors
enum Phase3AError: LocalizedError {
    case featureNotAuthorized(String)
    case dependencyMissing(String)
    case configurationError(String)
    case initializationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .featureNotAuthorized(let message):
            return "Feature not authorized: \(message)"
        case .dependencyMissing(let message):
            return "Dependency missing: \(message)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .initializationFailed(let message):
            return "Initialization failed: \(message)"
        }
    }
}

// MARK: - Extensions for Managers
extension EnhancedNetworkManager {
    static let shared = EnhancedNetworkManager()
}

extension EnhancedCoreDataManager {
    static let shared = EnhancedCoreDataManager()
}
