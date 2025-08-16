import Foundation

/// A protocol for a secure storage service, abstracting Keychain operations.
protocol SecureStoring {
    /// Saves a string value for a given key.
    /// - Parameters:
    ///   - value: The string value to save.
    ///   - key: The key to associate with the value.
    /// - Throws: An error if the save operation fails.
    func save(value: String, forKey key: String) throws

    /// Reads a string value for a given key.
    /// - Parameter key: The key for the value to read.
    /// - Returns: The stored string value, or `nil` if not found.
    /// - Throws: An error if the read operation fails.
    func read(forKey key: String) throws -> String?

    /// Deletes a value for a given key.
    /// - Parameter key: The key of the value to delete.
    /// - Throws: An error if the delete operation fails.
    func delete(forKey key: String) throws
}

/// A service for securely storing data in the system's Keychain.
///
/// **Note:** This is a placeholder implementation that uses `UserDefaults` for demonstration
/// purposes within a sandbox environment that lacks true Keychain access. In a production app,
/// this class would be backed by the Keychain Services API (`SecItemAdd`, `SecItemCopyMatching`, etc.).
final class KeychainStorage: SecureStoring {

    private let userDefaults: UserDefaults

    /// A namespace to prevent key collisions in UserDefaults.
    private let keyPrefix = "com.lyo.keychain_mock."

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func save(value: String, forKey key: String) throws {
        // In a real implementation, this would use SecItemAdd/SecItemUpdate.
        userDefaults.set(value, forKey: prefixedKey(key))
    }

    func read(forKey key: String) throws -> String? {
        // In a real implementation, this would use SecItemCopyMatching.
        return userDefaults.string(forKey: prefixedKey(key))
    }

    func delete(forKey key: String) throws {
        // In a real implementation, this would use SecItemDelete.
        userDefaults.removeObject(forKey: prefixedKey(key))
    }

    private func prefixedKey(_ key: String) -> String {
        return "\(keyPrefix)\(key)"
    }

    // MARK: - Convenience Keys

    /// Standard key for storing the JWT access token.
    static let accessTokenKey = "accessToken"

    /// Standard key for storing the JWT refresh token.
    static let refreshTokenKey = "refreshToken"
}
