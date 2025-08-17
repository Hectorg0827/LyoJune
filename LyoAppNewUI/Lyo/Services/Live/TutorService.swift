import Foundation

/// The live implementation of the `TutorServicing` protocol.
/// This class uses an `HTTPClient` to communicate with the backend Tutor API.
public final class TutorService: TutorServicing {

    private let httpClient: HTTPClienting

    /// Initializes a new `TutorService`.
    /// - Parameter httpClient: The `HTTPClient` to use for making network requests.
    public init(httpClient: HTTPClienting) {
        self.httpClient = httpClient
    }

    public func postTurn(text: String, selectedOptionId: String?) async throws -> TutorTurnResponse {
        let endpoint = TutorEndpoint.postTurn(text: text, selectedOptionId: selectedOptionId)
        return try await httpClient.request(endpoint)
    }

    public func getState(for learnerId: String) async throws -> TutorState {
        let endpoint = TutorEndpoint.getState(for: learnerId)
        return try await httpClient.request(endpoint)
    }

    public func saveState(for learnerId: String, state: TutorState) async throws {
        let endpoint = TutorEndpoint.saveState(for: learnerId, state: state)
        // The response type is `EmptyResponse`, so we discard the result.
        _ = try await httpClient.request(endpoint)
    }
}
