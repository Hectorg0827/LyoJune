import Foundation
import Security

// MARK: - Keychain Helper
final class KeychainHelper {
    static let shared = KeychainHelper()
    
    private init() {}
    
    private let service = Bundle.main.bundleIdentifier ?? "com.lyo.app"
    
    // MARK: - Save
    @discardableResult
    func save(_ data: String, for key: String) -> Bool {
        guard let data = data.data(using: .utf8) else { return false }
        return save(data, for: key)
    }
    
    @discardableResult
    func save(_ data: Data, for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Retrieve
    func retrieve(for key: String) -> String? {
        guard let data = retrieveData(for: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func retrieveData(for key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        }
        
        return nil
    }
    
    // MARK: - Load (for backward compatibility)
    func load(for key: String) -> Data? {
        return retrieveData(for: key)
    }
    
    // MARK: - Delete
    @discardableResult
    func delete(for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    // MARK: - Convenience Methods (for backward compatibility)
    func saveString(_ string: String, for key: String) -> Bool {
        return save(string, for: key)
    }
    
    func loadString(for key: String) -> String? {
        return retrieve(for: key)
    }
}

// MARK: - Bundle Extension
extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
