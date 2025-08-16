import Foundation
@testable import LyoApp

/// A mock implementation of `SecureStoring` for use in tests.
/// It stores values in a simple dictionary.
class MockSecureStorage: SecureStoring {
    var storage: [String: String] = [:]

    func save(value: String, forKey key: String) throws {
        storage[key] = value
    }

    func read(forKey key: String) throws -> String? {
        return storage[key]
    }

    func delete(forKey key: String) throws {
        storage.removeValue(forKey: key)
    }
}


/// A mock implementation of `AuthService` that subclasses the original.
/// This allows us to override methods and track interactions during tests.
final class MockAuthService: AuthService {

    private(set) var saveTokensCallCount = 0
    private(set) var savedAccessToken: String?
    private(set) var savedRefreshToken: String?

    private(set) var clearTokensCallCount = 0

    var shouldThrowOnSave: Error?

    // We must call the superclass initializer. We can use dummy values since
    // we will override the methods we care about.
    init() {
        super.init(
            baseURL: URL(string: "https://fake-url.com")!,
            session: .shared,
            storage: MockSecureStorage()
        )
    }

    override func saveTokens(accessToken: String, refreshToken: String) throws {
        if let error = shouldThrowOnSave {
            throw error
        }
        saveTokensCallCount += 1
        savedAccessToken = accessToken
        savedRefreshToken = refreshToken
    }

    override func clearTokens() throws {
        clearTokensCallCount += 1
    }
}
