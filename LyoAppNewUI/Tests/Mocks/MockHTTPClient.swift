import Foundation
@testable import LyoApp // Using @testable to access internal types if needed

/// A mock implementation of the `HTTPClienting` protocol for use in unit tests.
final class MockHTTPClient: HTTPClienting {

    /// The result to return when the `request` method is called.
    /// Set this to `.success(yourDecodableObject)` or `.failure(yourAPIError)`
    /// before calling the method under test.
    var result: Result<Decodable, APIError>?

    private(set) var lastEndpointCalled: Any?

    func request<T>(_ endpoint: Endpoint<T>) async throws -> T where T : Decodable {
        lastEndpointCalled = endpoint

        guard let result = result else {
            fatalError("MockHTTPClient result was not set before calling `request`.")
        }

        switch result {
        case .success(let value):
            guard let typedValue = value as? T else {
                fatalError("MockHTTPClient success value was of the wrong type.")
            }
            return typedValue
        case .failure(let error):
            throw error
        }
    }
}
