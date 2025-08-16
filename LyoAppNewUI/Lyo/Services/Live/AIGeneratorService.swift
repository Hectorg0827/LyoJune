import Foundation

/// The live implementation of the `AIGeneratorServicing` protocol.
/// This class uses an `HTTPClient` to fetch AI-generated content from the backend.
public final class AIGeneratorService: AIGeneratorServicing {

    private let httpClient: HTTPClienting

    public init(httpClient: HTTPClienting) {
        self.httpClient = httpClient
    }

    public func generateContent(_ request: AIGenerationRequest) async throws -> AIGeneratedContent {
        let endpoint = AIGeneratorEndpoint.generateContent(request)
        return try await httpClient.request(endpoint)
    }
}
