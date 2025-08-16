import Foundation

/// A namespace for creating API endpoints related to the AI Content Generator.
enum AIGeneratorEndpoint {

    /// Creates an endpoint to request AI-generated content.
    /// - Parameter request: The request body containing the user's learning goal and context.
    /// - Returns: An `Endpoint` configured to fetch the polymorphic `AIGeneratedContent` object.
    static func generateContent(_ request: AIGenerationRequest) -> Endpoint<AIGeneratedContent> {
        return try! Endpoint(
            path: "/v1/ai/generate",
            method: .post,
            encodableBody: request
        )
    }
}
