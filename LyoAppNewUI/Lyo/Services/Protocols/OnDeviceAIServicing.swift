import Foundation

/// A protocol that defines the contract for an on-device AI service
/// that can generate text responses from a prompt.
public protocol OnDeviceAIServicing {

    /// Asynchronously generates a text response for a given prompt using a local model.
    /// - Parameter prompt: The input text to the model.
    /// - Returns: The generated text response as a `String`.
    /// - Throws: An error if the model fails to load or if inference fails.
    func generate(prompt: String) async throws -> String
}
