import Foundation

/// A protocol that defines the contract for a service that interacts with the AI content generation API.
public protocol AIGeneratorServicing {

    /// Asynchronously requests AI-generated content based on a user's goal.
    /// - Parameter request: The `AIGenerationRequest` containing the user's goal and context.
    /// - Returns: A polymorphic `AIGeneratedContent` object.
    /// - Throws: An `APIError` if the network request or decoding fails.
    func generateContent(_ request: AIGenerationRequest) async throws -> AIGeneratedContent
}
