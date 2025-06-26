//
//  SecurityManager.swift
//  LyoApp
//
//  Comprehensive security manager with jailbreak detection, certificate pinning, and data protection
//

import Foundation
import Security
import CryptoKit
import LocalAuthentication
import CommonCrypto

// MARK: - Security Threat Types
enum SecurityThreat: String, CaseIterable {
    case jailbreak = "jailbreak"
    case debugger = "debugger"
    case simulator = "simulator"
    case hooking = "hooking"
    case tampering = "tampering"
    case reverseEngineering = "reverse_engineering"
    case certificatePinning = "certificate_pinning"
    
    var description: String {
        switch self {
        case .jailbreak: return "Device appears to be jailbroken"
        case .debugger: return "Debugger detected"
        case .simulator: return "Running on simulator"
        case .hooking: return "Runtime manipulation detected"
        case .tampering: return "App tampering detected"
        case .reverseEngineering: return "Reverse engineering attempt detected"
        case .certificatePinning: return "Certificate pinning validation failed"
        }
    }
    
    var severity: SecuritySeverity {
        switch self {
        case .jailbreak, .tampering, .reverseEngineering:
            return .critical
        case .debugger, .hooking:
            return .high
        case .simulator, .certificatePinning:
            return .medium
        }
    }
}

enum SecuritySeverity: String, Comparable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    static func < (lhs: SecuritySeverity, rhs: SecuritySeverity) -> Bool {
        let order: [SecuritySeverity] = [.low, .medium, .high, .critical]
        return order.firstIndex(of: lhs) ?? 0 < order.firstIndex(of: rhs) ?? 0
    }
}

// MARK: - Security Configuration
struct SecurityConfiguration {
    let enableJailbreakDetection: Bool
    let enableDebuggerDetection: Bool
    let enableTamperingDetection: Bool
    let enableCertificatePinning: Bool
    let allowSimulator: Bool
    let enableRuntimeProtection: Bool
    let logSecurityEvents: Bool
    let blockOnSecurityViolation: Bool
    
    static let `default` = SecurityConfiguration(
        enableJailbreakDetection: true,
        enableDebuggerDetection: true,
        enableTamperingDetection: true,
        enableCertificatePinning: true,
        allowSimulator: false,
        enableRuntimeProtection: true,
        logSecurityEvents: true,
        blockOnSecurityViolation: false
    )
    
    static let development = SecurityConfiguration(
        enableJailbreakDetection: false,
        enableDebuggerDetection: false,
        enableTamperingDetection: false,
        enableCertificatePinning: false,
        allowSimulator: true,
        enableRuntimeProtection: false,
        logSecurityEvents: true,
        blockOnSecurityViolation: false
    )
}

// MARK: - Security Event
struct SecurityEvent {
    let id: UUID
    let threat: SecurityThreat
    let timestamp: Date
    let details: [String: Any]
    let deviceInfo: [String: String]
    let appInfo: [String: String]
    
    init(threat: SecurityThreat, details: [String: Any] = [:]) {
        self.id = UUID()
        self.threat = threat
        self.timestamp = Date()
        self.details = details
        self.deviceInfo = SecurityManager.collectDeviceInfo()
        self.appInfo = SecurityManager.collectAppInfo()
    }
}

// MARK: - Certificate Pinning Data
struct CertificatePinData {
    let host: String
    let publicKeyHashes: Set<String>
    let certificateHashes: Set<String>
    
    init(host: String, publicKeyHashes: [String] = [], certificateHashes: [String] = []) {
        self.host = host
        self.publicKeyHashes = Set(publicKeyHashes)
        self.certificateHashes = Set(certificateHashes)
    }
}

// MARK: - SecurityManager
@MainActor
class SecurityManager: NSObject, ObservableObject {
    
    // MARK: - Shared Instance
    static let shared = SecurityManager()
    
    // MARK: - Published Properties
    @Published var securityEvents: [SecurityEvent] = []
    @Published var currentThreats: Set<SecurityThreat> = []
    @Published var isSecure: Bool = true
    @Published var configuration: SecurityConfiguration = .default
    
    // MARK: - Private Properties
    private var certificatePins: [String: CertificatePinData] = [:]
    private let maxSecurityEvents = 100
    private var securityCheckTimer: Timer?
    private let securityQueue = DispatchQueue(label: "com.lyoapp.security", qos: .userInitiated)
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupSecurity()
        startPeriodicSecurityChecks()
    }
    
    // MARK: - Setup
    
    private func setupSecurity() {
        #if DEBUG
        configuration = .development
        #else
        configuration = .default
        #endif
        
        setupCertificatePinning()
        performInitialSecurityCheck()
    }
    
    private func setupCertificatePinning() {
        // Add your API endpoints and their certificate pins
        certificatePins = [
            "api.lyoapp.com": CertificatePinData(
                host: "api.lyoapp.com",
                publicKeyHashes: [
                    // Add your actual public key hashes here
                    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
                ],
                certificateHashes: [
                    // Add your actual certificate hashes here
                    "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="
                ]
            )
        ]
    }
    
    private func startPeriodicSecurityChecks() {
        securityCheckTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task { @MainActor in
                await self.performSecurityCheck()
            }
        }
    }
    
    // MARK: - Security Checks
    
    /// Perform comprehensive security check
    func performSecurityCheck() async {
        var detectedThreats: Set<SecurityThreat> = []
        
        if configuration.enableJailbreakDetection {
            let jailbreakResult = await checkJailbreak()
            if jailbreakResult.isDetected {
                detectedThreats.insert(.jailbreak)
                logSecurityEvent(.jailbreak, details: jailbreakResult.details)
            }
        }
        
        if configuration.enableDebuggerDetection {
            let debuggerResult = await checkDebugger()
            if debuggerResult.isDetected {
                detectedThreats.insert(.debugger)
                logSecurityEvent(.debugger, details: debuggerResult.details)
            }
        }
        
        if configuration.enableTamperingDetection {
            let tamperingResult = await checkTampering()
            if tamperingResult.isDetected {
                detectedThreats.insert(.tampering)
                logSecurityEvent(.tampering, details: tamperingResult.details)
            }
        }
        
        if !configuration.allowSimulator {
            let simulatorResult = await checkSimulator()
            if simulatorResult.isDetected {
                detectedThreats.insert(.simulator)
                logSecurityEvent(.simulator, details: simulatorResult.details)
            }
        }
        
        if configuration.enableRuntimeProtection {
            let hookingResult = await checkHooking()
            if hookingResult.isDetected {
                detectedThreats.insert(.hooking)
                logSecurityEvent(.hooking, details: hookingResult.details)
            }
        }
        
        // Update current threats and security status
        currentThreats = detectedThreats
        isSecure = detectedThreats.isEmpty || detectedThreats.allSatisfy { $0.severity < .high }
        
        // Handle security violations
        if configuration.blockOnSecurityViolation && !isSecure {
            await handleSecurityViolation(threats: detectedThreats)
        }
    }
    
    private func performInitialSecurityCheck() {
        Task {
            await performSecurityCheck()
        }
    }
    
    // MARK: - Specific Security Checks
    
    private func checkJailbreak() async -> (isDetected: Bool, details: [String: Any]) {
        return await withCheckedContinuation { continuation in
            securityQueue.async {
                var details: [String: Any] = [:]
                var isJailbroken = false
                
                // Check for common jailbreak files
                let jailbreakPaths = [
                    "/Applications/Cydia.app",
                    "/Library/MobileSubstrate/MobileSubstrate.dylib",
                    "/bin/bash",
                    "/usr/sbin/sshd",
                    "/etc/apt",
                    "/private/var/lib/apt/",
                    "/private/var/lib/cydia",
                    "/private/var/mobile/Library/SBSettingsThemes/",
                    "/Library/MobileSubstrate/MobileSubstrate.dylib",
                    "/Applications/RockApp.app",
                    "/Applications/Icy.app",
                    "/Applications/WinterBoard.app",
                    "/Applications/SBSettings.app",
                    "/Applications/blackra1n.app",
                    "/Applications/IntelliScreen.app",
                    "/Applications/Snoop-it Config.app"
                ]
                
                var foundPaths: [String] = []
                for path in jailbreakPaths {
                    if FileManager.default.fileExists(atPath: path) {
                        foundPaths.append(path)
                        isJailbroken = true
                    }
                }
                
                if !foundPaths.isEmpty {
                    details["found_paths"] = foundPaths
                }
                
                // Check if we can write to system directories
                let testPath = "/private/test_jailbreak.txt"
                let testString = "jailbreak test"
                
                do {
                    try testString.write(toFile: testPath, atomically: true, encoding: .utf8)
                    try FileManager.default.removeItem(atPath: testPath)
                    isJailbroken = true
                    details["system_write_access"] = true
                } catch {
                    details["system_write_access"] = false
                }
                
                // Check for suspicious URL schemes
                let suspiciousSchemes = ["cydia://", "sileo://", "zbra://"]
                var foundSchemes: [String] = []
                
                for scheme in suspiciousSchemes {
                    if let url = URL(string: scheme), UIApplication.shared.canOpenURL(url) {
                        foundSchemes.append(scheme)
                        isJailbroken = true
                    }
                }
                
                if !foundSchemes.isEmpty {
                    details["found_url_schemes"] = foundSchemes
                }
                
                continuation.resume(returning: (isJailbroken, details))
            }
        }
    }
    
    private func checkDebugger() async -> (isDetected: Bool, details: [String: Any]) {
        return await withCheckedContinuation { continuation in
            securityQueue.async {
                var details: [String: Any] = [:]
                var isDebugging = false
                
                // Check if debugger is attached using ptrace
                var info = kinfo_proc()
                var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
                var size = MemoryLayout<kinfo_proc>.stride
                
                let result = sysctl(&mib, u_int(mib.count), &info, &size, nil, 0)
                
                if result == 0 {
                    let isTraced = (info.kp_proc.p_flag & P_TRACED) != 0
                    if isTraced {
                        isDebugging = true
                        details["ptrace_detected"] = true
                    }
                }
                
                // Check for debugging environment variables
                let debugEnvVars = ["DYLD_INSERT_LIBRARIES", "MSHookFunction", "MSFindSymbol"]
                var foundEnvVars: [String] = []
                
                for envVar in debugEnvVars {
                    if getenv(envVar) != nil {
                        foundEnvVars.append(envVar)
                        isDebugging = true
                    }
                }
                
                if !foundEnvVars.isEmpty {
                    details["debug_env_vars"] = foundEnvVars
                }
                
                continuation.resume(returning: (isDebugging, details))
            }
        }
    }
    
    private func checkTampering() async -> (isDetected: Bool, details: [String: Any]) {
        return await withCheckedContinuation { continuation in
            securityQueue.async {
                var details: [String: Any] = [:]
                var isTampered = false
                
                // Check bundle signature
                guard let bundlePath = Bundle.main.bundlePath,
                      let bundleURL = URL(string: bundlePath) else {
                    details["bundle_check"] = "failed_to_get_bundle_path"
                    continuation.resume(returning: (true, details))
                    return
                }
                
                // Check if main executable has been modified
                guard let executablePath = Bundle.main.executablePath else {
                    details["executable_check"] = "failed_to_get_executable_path"
                    continuation.resume(returning: (true, details))
                    return
                }
                
                // Basic file integrity check (you should implement proper code signing verification)
                let fileManager = FileManager.default
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: executablePath)
                    if let modificationDate = attributes[.modificationDate] as? Date {
                        details["executable_modified"] = modificationDate
                        
                        // If modification date is very recent, it might indicate tampering
                        if modificationDate.timeIntervalSinceNow > -3600 { // Within last hour
                            isTampered = true
                            details["recent_modification"] = true
                        }
                    }
                } catch {
                    details["executable_attributes_error"] = error.localizedDescription
                }
                
                continuation.resume(returning: (isTampered, details))
            }
        }
    }
    
    private func checkSimulator() async -> (isDetected: Bool, details: [String: Any]) {
        return await withCheckedContinuation { continuation in
            securityQueue.async {
                var details: [String: Any] = [:]
                
                #if targetEnvironment(simulator)
                details["target_environment"] = "simulator"
                continuation.resume(returning: (true, details))
                #else
                // Additional runtime checks
                let isSimulator = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil
                
                if isSimulator {
                    details["simulator_env_detected"] = true
                }
                
                continuation.resume(returning: (isSimulator, details))
                #endif
            }
        }
    }
    
    private func checkHooking() async -> (isDetected: Bool, details: [String: Any]) {
        return await withCheckedContinuation { continuation in
            securityQueue.async {
                var details: [String: Any] = [:]
                var isHooked = false
                
                // Check for common hooking frameworks
                let hookingLibraries = [
                    "MobileSubstrate",
                    "CydiaSubstrate",
                    "FridaGadget",
                    "cycript",
                    "SSLKillSwitch"
                ]
                
                var foundLibraries: [String] = []
                
                for library in hookingLibraries {
                    if dlopen(library, RTLD_NOLOAD) != nil {
                        foundLibraries.append(library)
                        isHooked = true
                    }
                }
                
                if !foundLibraries.isEmpty {
                    details["found_hooking_libraries"] = foundLibraries
                }
                
                // Check for method swizzling on critical classes
                let criticalClasses = ["NSURLSession", "NSURLConnection", "SecTrustEvaluate"]
                for className in criticalClasses {
                    if let cls = NSClassFromString(className) {
                        // Basic check for method implementation changes
                        // This is a simplified check - in production, you'd want more sophisticated detection
                        details["checked_classes"] = (details["checked_classes"] as? [String] ?? []) + [className]
                    }
                }
                
                continuation.resume(returning: (isHooked, details))
            }
        }
    }
    
    // MARK: - Certificate Pinning
    
    func validateCertificate(for host: String, trust: SecTrust) -> Bool {
        guard configuration.enableCertificatePinning,
              let pinData = certificatePins[host] else {
            return true // Allow if pinning not configured
        }
        
        // Get certificate chain
        let certificateCount = SecTrustGetCertificateCount(trust)
        
        for i in 0..<certificateCount {
            if let certificate = SecTrustGetCertificateAtIndex(trust, i) {
                // Check certificate hash
                let certificateData = SecCertificateCopyData(certificate)
                let certificateHash = sha256Hash(data: CFDataGetBytePtr(certificateData), length: CFDataGetLength(certificateData))
                
                if pinData.certificateHashes.contains(certificateHash) {
                    return true
                }
                
                // Check public key hash
                if let publicKey = SecCertificateCopyKey(certificate) {
                    if let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) {
                        let publicKeyHash = sha256Hash(data: CFDataGetBytePtr(publicKeyData), length: CFDataGetLength(publicKeyData))
                        
                        if pinData.publicKeyHashes.contains(publicKeyHash) {
                            return true
                        }
                    }
                }
            }
        }
        
        // Log certificate pinning failure
        logSecurityEvent(.certificatePinning, details: [
            "host": host,
            "certificate_count": certificateCount
        ])
        
        return false
    }
    
    private func sha256Hash(data: UnsafePointer<UInt8>, length: Int) -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256(data, CC_LONG(length), &hash)
        return Data(hash).base64EncodedString()
    }
    
    // MARK: - Data Protection
    
    func encryptSensitiveData(_ data: Data, using key: SymmetricKey? = nil) throws -> Data {
        let encryptionKey = key ?? SymmetricKey(size: .bits256)
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
        return sealedBox.combined ?? Data()
    }
    
    func decryptSensitiveData(_ encryptedData: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    func generateSecureKey() -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }
    
    // MARK: - Event Logging
    
    private func logSecurityEvent(_ threat: SecurityThreat, details: [String: Any] = [:]) {
        guard configuration.logSecurityEvents else { return }
        
        let event = SecurityEvent(threat: threat, details: details)
        securityEvents.append(event)
        
        // Limit stored events
        if securityEvents.count > maxSecurityEvents {
            securityEvents.removeFirst(securityEvents.count - maxSecurityEvents)
        }
        
        print("🚨 Security Event: \(threat.description)")
        if !details.isEmpty {
            print("   Details: \(details)")
        }
    }
    
    // MARK: - Security Violation Handling
    
    private func handleSecurityViolation(threats: Set<SecurityThreat>) async {
        let criticalThreats = threats.filter { $0.severity == .critical }
        
        if !criticalThreats.isEmpty {
            // Handle critical security violations
            await handleCriticalSecurityViolation(threats: criticalThreats)
        } else {
            // Handle non-critical violations
            await handleNonCriticalSecurityViolation(threats: threats)
        }
    }
    
    private func handleCriticalSecurityViolation(threats: Set<SecurityThreat>) async {
        // Log security violation
        print("🚨 Critical security violation detected: \(threats.map { $0.rawValue }.joined(separator: ", "))")
        
        // Could implement:
        // - App termination
        // - Data wiping
        // - Server notification
        // - User notification
        
        // For now, just notify the app
        NotificationCenter.default.post(
            name: .criticalSecurityViolation,
            object: nil,
            userInfo: ["threats": Array(threats)]
        )
    }
    
    private func handleNonCriticalSecurityViolation(threats: Set<SecurityThreat>) async {
        // Log and potentially warn user
        print("⚠️ Security concerns detected: \(threats.map { $0.rawValue }.joined(separator: ", "))")
        
        NotificationCenter.default.post(
            name: .securityConcernDetected,
            object: nil,
            userInfo: ["threats": Array(threats)]
        )
    }
    
    // MARK: - Device and App Information
    
    static func collectDeviceInfo() -> [String: String] {
        return [
            "model": UIDevice.current.model,
            "system_name": UIDevice.current.systemName,
            "system_version": UIDevice.current.systemVersion,
            "device_name": UIDevice.current.name,
            "identifier_for_vendor": UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        ]
    }
    
    static func collectAppInfo() -> [String: String] {
        let bundle = Bundle.main
        return [
            "bundle_identifier": bundle.bundleIdentifier ?? "unknown",
            "version": bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
            "build": bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown",
            "executable_name": bundle.object(forInfoDictionaryKey: "CFBundleExecutable") as? String ?? "unknown"
        ]
    }
    
    deinit {
        securityCheckTimer?.invalidate()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let criticalSecurityViolation = Notification.Name("criticalSecurityViolation")
    static let securityConcernDetected = Notification.Name("securityConcernDetected")
}
