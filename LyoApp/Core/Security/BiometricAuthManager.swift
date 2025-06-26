//
//  BiometricAuthManager.swift
//  LyoApp
//
//  Advanced biometric authentication with security features
//

import Foundation
import LocalAuthentication
import Security
import CryptoKit
import SwiftUI

// MARK: - Biometric Authentication Types
enum BiometricType {
    case none
    case faceID
    case touchID
    case opticID
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        }
    }
    
    var systemImage: String {
        switch self {
        case .none: return "lock"
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        }
    }
}

enum BiometricError: LocalizedError {
    case biometryNotAvailable
    case biometryNotEnrolled
    case biometryLockout
    case authenticationFailed
    case userCancel
    case userFallback
    case systemCancel
    case passcodeNotSet
    case keychainError(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .biometryNotAvailable:
            return "Biometric authentication is not available on this device"
        case .biometryNotEnrolled:
            return "No biometric authentication is enrolled. Please set up Face ID or Touch ID in Settings"
        case .biometryLockout:
            return "Biometric authentication is locked. Please enter your passcode"
        case .authenticationFailed:
            return "Authentication failed. Please try again"
        case .userCancel:
            return "Authentication was cancelled"
        case .userFallback:
            return "User chose to enter password instead"
        case .systemCancel:
            return "Authentication was cancelled by the system"
        case .passcodeNotSet:
            return "Please set up a passcode in Settings to use biometric authentication"
        case .keychainError(let message):
            return "Keychain error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}

// MARK: - Biometric Authentication Result
struct BiometricAuthResult {
    let success: Bool
    let error: BiometricError?
    let biometricType: BiometricType
    let authenticatedAt: Date
    let failureCount: Int
    
    static let failed = BiometricAuthResult(
        success: false,
        error: .authenticationFailed,
        biometricType: .none,
        authenticatedAt: Date(),
        failureCount: 1
    )
}

// MARK: - Keychain Configuration
struct KeychainConfiguration {
    static let serviceName = "com.lyoapp.biometric"
    static let accountName = "user_biometric_key"
    static let accessGroup: String? = nil // Set this for app groups
}

// MARK: - BiometricAuthManager
@MainActor
class BiometricAuthManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAvailable = false
    @Published var biometricType: BiometricType = .none
    @Published var isEnabled = false
    @Published var isAuthenticated = false
    @Published var failureCount = 0
    @Published var lastAuthenticationDate: Date?
    
    // MARK: - Private Properties
    private let context = LAContext()
    private let keychainManager = KeychainManager()
    private let maxFailureAttempts = 3
    private let lockoutDuration: TimeInterval = 300 // 5 minutes
    
    // MARK: - User Defaults Keys
    private enum UserDefaultsKeys {
        static let biometricEnabled = "biometric_enabled"
        static let failureCount = "biometric_failure_count"
        static let lastFailureDate = "biometric_last_failure_date"
        static let lastAuthDate = "biometric_last_auth_date"
    }
    
    // MARK: - Initialization
    init() {
        loadConfiguration()
        evaluateBiometricAvailability()
    }
    
    // MARK: - Public Methods
    
    /// Check if biometric authentication is available
    func evaluateBiometricAvailability() {
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isAvailable = true
            
            switch context.biometryType {
            case .faceID:
                biometricType = .faceID
            case .touchID:
                biometricType = .touchID
            case .opticID:
                biometricType = .opticID
            case .none:
                biometricType = .none
                isAvailable = false
            @unknown default:
                biometricType = .none
                isAvailable = false
            }
        } else {
            isAvailable = false
            biometricType = .none
        }
    }
    
    /// Enable biometric authentication
    func enableBiometricAuth() async -> Result<Void, BiometricError> {
        guard isAvailable else {
            return .failure(.biometryNotAvailable)
        }
        
        // First authenticate to enable
        let authResult = await authenticate(reason: "Enable biometric authentication for secure app access")
        
        if authResult.success {
            // Generate and store encryption key
            let keyData = generateEncryptionKey()
            let storeResult = await keychainManager.store(
                key: KeychainConfiguration.accountName,
                data: keyData,
                service: KeychainConfiguration.serviceName
            )
            
            if case .success = storeResult {
                isEnabled = true
                UserDefaults.standard.set(true, forKey: UserDefaultsKeys.biometricEnabled)
                return .success(())
            } else {
                return .failure(.keychainError("Failed to store biometric key"))
            }
        } else {
            return .failure(authResult.error ?? .authenticationFailed)
        }
    }
    
    /// Disable biometric authentication
    func disableBiometricAuth() async -> Result<Void, BiometricError> {
        // Remove from keychain
        let deleteResult = await keychainManager.delete(
            key: KeychainConfiguration.accountName,
            service: KeychainConfiguration.serviceName
        )
        
        if case .success = deleteResult {
            isEnabled = false
            isAuthenticated = false
            UserDefaults.standard.set(false, forKey: UserDefaultsKeys.biometricEnabled)
            resetFailureCount()
            return .success(())
        } else {
            return .failure(.keychainError("Failed to remove biometric key"))
        }
    }
    
    /// Authenticate using biometric
    func authenticate(reason: String = "Authenticate to access LyoApp") async -> BiometricAuthResult {
        guard isAvailable && isEnabled else {
            return BiometricAuthResult(
                success: false,
                error: .biometryNotAvailable,
                biometricType: biometricType,
                authenticatedAt: Date(),
                failureCount: failureCount
            )
        }
        
        // Check if locked out
        if isLockedOut() {
            return BiometricAuthResult(
                success: false,
                error: .biometryLockout,
                biometricType: biometricType,
                authenticatedAt: Date(),
                failureCount: failureCount
            )
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if success {
                // Verify keychain key exists (additional security check)
                let keyResult = await keychainManager.retrieve(
                    key: KeychainConfiguration.accountName,
                    service: KeychainConfiguration.serviceName
                )
                
                if case .success = keyResult {
                    isAuthenticated = true
                    lastAuthenticationDate = Date()
                    UserDefaults.standard.set(Date(), forKey: UserDefaultsKeys.lastAuthDate)
                    resetFailureCount()
                    
                    return BiometricAuthResult(
                        success: true,
                        error: nil,
                        biometricType: biometricType,
                        authenticatedAt: Date(),
                        failureCount: 0
                    )
                } else {
                    // Key missing - disable biometric auth
                    await disableBiometricAuth()
                    return BiometricAuthResult(
                        success: false,
                        error: .keychainError("Biometric key not found"),
                        biometricType: biometricType,
                        authenticatedAt: Date(),
                        failureCount: failureCount
                    )
                }
            } else {
                incrementFailureCount()
                return BiometricAuthResult(
                    success: false,
                    error: .authenticationFailed,
                    biometricType: biometricType,
                    authenticatedAt: Date(),
                    failureCount: failureCount
                )
            }
        } catch {
            let biometricError = mapLAError(error)
            
            if biometricError != .userCancel && biometricError != .userFallback {
                incrementFailureCount()
            }
            
            return BiometricAuthResult(
                success: false,
                error: biometricError,
                biometricType: biometricType,
                authenticatedAt: Date(),
                failureCount: failureCount
            )
        }
    }
    
    /// Sign out and clear authentication
    func signOut() {
        isAuthenticated = false
        lastAuthenticationDate = nil
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastAuthDate)
    }
    
    /// Check if authentication is still valid (based on timeout)
    func isAuthenticationValid(timeout: TimeInterval = 300) -> Bool {
        guard isAuthenticated,
              let lastAuth = lastAuthenticationDate else {
            return false
        }
        
        return Date().timeIntervalSince(lastAuth) < timeout
    }
    
    // MARK: - Private Methods
    
    private func loadConfiguration() {
        isEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.biometricEnabled)
        failureCount = UserDefaults.standard.integer(forKey: UserDefaultsKeys.failureCount)
        
        if let lastAuthDate = UserDefaults.standard.object(forKey: UserDefaultsKeys.lastAuthDate) as? Date {
            lastAuthenticationDate = lastAuthDate
        }
    }
    
    private func generateEncryptionKey() -> Data {
        let key = SymmetricKey(size: .bits256)
        return key.withUnsafeBytes { Data($0) }
    }
    
    private func incrementFailureCount() {
        failureCount += 1
        UserDefaults.standard.set(failureCount, forKey: UserDefaultsKeys.failureCount)
        UserDefaults.standard.set(Date(), forKey: UserDefaultsKeys.lastFailureDate)
    }
    
    private func resetFailureCount() {
        failureCount = 0
        UserDefaults.standard.set(0, forKey: UserDefaultsKeys.failureCount)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastFailureDate)
    }
    
    private func isLockedOut() -> Bool {
        guard failureCount >= maxFailureAttempts else { return false }
        
        if let lastFailureDate = UserDefaults.standard.object(forKey: UserDefaultsKeys.lastFailureDate) as? Date {
            return Date().timeIntervalSince(lastFailureDate) < lockoutDuration
        }
        
        return false
    }
    
    private func mapLAError(_ error: Error) -> BiometricError {
        guard let laError = error as? LAError else {
            return .unknown(error.localizedDescription)
        }
        
        switch laError.code {
        case .biometryNotAvailable:
            return .biometryNotAvailable
        case .biometryNotEnrolled:
            return .biometryNotEnrolled
        case .biometryLockout:
            return .biometryLockout
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel:
            return .userCancel
        case .userFallback:
            return .userFallback
        case .systemCancel:
            return .systemCancel
        case .passcodeNotSet:
            return .passcodeNotSet
        default:
            return .unknown(laError.localizedDescription)
        }
    }
}

// MARK: - Keychain Manager
class KeychainManager {
    
    enum KeychainError: Error {
        case duplicateItem
        case itemNotFound
        case invalidItemFormat
        case unexpectedPasswordData
        case unhandledError(status: OSStatus)
    }
    
    func store(key: String, data: Data, service: String) async -> Result<Void, KeychainError> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: service,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleBiometryCurrentSet
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        switch status {
        case errSecSuccess:
            return .success(())
        case errSecDuplicateItem:
            // Update existing item
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecAttrService as String: service
            ]
            
            let updateAttributes: [String: Any] = [
                kSecValueData as String: data
            ]
            
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
            
            if updateStatus == errSecSuccess {
                return .success(())
            } else {
                return .failure(.unhandledError(status: updateStatus))
            }
        default:
            return .failure(.unhandledError(status: status))
        }
    }
    
    func retrieve(key: String, service: String) async -> Result<Data, KeychainError> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        switch status {
        case errSecSuccess:
            guard let data = item as? Data else {
                return .failure(.unexpectedPasswordData)
            }
            return .success(data)
        case errSecItemNotFound:
            return .failure(.itemNotFound)
        default:
            return .failure(.unhandledError(status: status))
        }
    }
    
    func delete(key: String, service: String) async -> Result<Void, KeychainError> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecSuccess, errSecItemNotFound:
            return .success(())
        default:
            return .failure(.unhandledError(status: status))
        }
    }
}
