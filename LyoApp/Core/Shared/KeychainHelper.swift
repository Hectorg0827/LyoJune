import Foundation
import Security

/// A helper class for securely storing and retrieving data from the iOS Keychain
public class KeychainHelper {
    
    // MARK: - Shared Instance
    public static let shared = KeychainHelper()
    
    // MARK: - Constants
    private static let service = Bundle.main.bundleIdentifier ?? "com.lyo.lyoapp"
    
    // Private initializer to enforce singleton
    private init() {}
    
    // MARK: - Public Methods
    
    /// Store a string value in the keychain
    /// - Parameters:
    ///   - value: The string to store
    ///   - key: The key to associate with the value
    /// - Returns: True if successful, false otherwise
    @discardableResult
    public func store(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        return store(data, forKey: key)
    }
    
    /// Store data in the keychain
    /// - Parameters:
    ///   - data: The data to store
    ///   - key: The key to associate with the data
    /// - Returns: True if successful, false otherwise
    @discardableResult
    public func store(_ data: Data, forKey key: String) -> Bool {
        // Delete any existing item first
        delete(forKey: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Retrieve a string value from the keychain
    /// - Parameter key: The key associated with the value
    /// - Returns: The stored string, or nil if not found
    public func retrieve(forKey key: String) -> String? {
        guard let data = retrieveData(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// Retrieve data from the keychain
    /// - Parameter key: The key associated with the data
    /// - Returns: The stored data, or nil if not found
    public func retrieveData(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
    
    /// Delete a value from the keychain
    /// - Parameter key: The key associated with the value to delete
    /// - Returns: True if successful or item doesn't exist, false otherwise
    @discardableResult
    public func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    /// Update an existing value in the keychain
    /// - Parameters:
    ///   - value: The new string value
    ///   - key: The key associated with the value
    /// - Returns: True if successful, false otherwise
    @discardableResult
    public func update(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        return update(data, forKey: key)
    }
    
    /// Update existing data in the keychain
    /// - Parameters:
    ///   - data: The new data
    ///   - key: The key associated with the data
    /// - Returns: True if successful, false otherwise
    @discardableResult
    public func update(_ data: Data, forKey: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: forKey
        ]
        
        let updateFields: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, updateFields as CFDictionary)
        
        // If item doesn't exist, create it
        if status == errSecItemNotFound {
            return store(data, forKey: forKey)
        }
        
        return status == errSecSuccess
    }
    
    /// Clear all keychain items for this app
    /// - Returns: True if successful, false otherwise
    @discardableResult
    public func clearAll() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

// MARK: - Convenience Methods
extension KeychainHelper {
    
    /// Common keychain keys used throughout the app
    public enum Keys {
        public static let authToken = "auth_token"
        public static let refreshToken = "refresh_token"
        public static let userID = "user_id"
        public static let biometricEnabled = "biometric_enabled"
    }
    
    // MARK: - Convenience methods for backward compatibility
    
    /// Save a string value to the keychain (convenience method)
    @discardableResult
    public func save(_ value: String, for key: String) -> Bool {
        return store(value, forKey: key)
    }
    
    /// Save data to the keychain (convenience method)
    @discardableResult
    public func save(_ data: Data, for key: String) -> Bool {
        return store(data, forKey: key)
    }
    
    /// Retrieve a string value from the keychain (convenience method)
    public func retrieve(for key: String) -> String? {
        return retrieve(forKey: key)
    }
    
    /// Retrieve data from the keychain (convenience method)
    public func retrieveData(for key: String) -> Data? {
        return retrieveData(forKey: key)
    }
    
    /// Load data from the keychain (alias for retrieveData)
    public func load(for key: String) -> Data? {
        return retrieveData(forKey: key)
    }
    
    /// Delete a value from the keychain (convenience method)
    @discardableResult
    public func delete(for key: String) -> Bool {
        return delete(forKey: key)
    }
}
