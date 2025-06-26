import Foundation

// Test file to check type availability
struct TypeTest {
    func testTypes() {
        let _ = User(id: "test", email: "test@example.com")
        let _ = APIEndpoint(path: "/test", method: .GET)
        let _ = AuthError.invalidCredentials
        let _ = KeychainHelper.shared
        let _ = EmptyResponse()
        let _ = NetworkError.noInternetConnection
    }
}
