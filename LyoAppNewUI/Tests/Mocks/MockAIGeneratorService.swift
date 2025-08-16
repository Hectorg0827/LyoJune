import Foundation
@testable import LyoApp

final class MockAIGeneratorService: AIGeneratorServicing {

    var generateContentResult: Result<AIGeneratedContent, APIError> = .failure(.unauthorized)
    private(set) var generateContentCallCount = 0

    func generateContent(_ request: AIGenerationRequest) async throws -> AIGeneratedContent {
        generateContentCallCount += 1
        return try generateContentResult.get()
    }
}
