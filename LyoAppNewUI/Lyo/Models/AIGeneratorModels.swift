import Foundation

// MARK: - API Request

/// The request body sent to the AI orchestrator to generate content.
public struct AIGenerationRequest: Codable {
    /// The user's stated learning goal, determined from the chat conversation.
    let learningGoal: String

    /// The full history of the conversation, to provide context.
    let chatHistory: [TutorMessage]
}


// MARK: - API Response Models

/// A simple model for a tutorial, which might be a single block of rich text.
public struct Tutorial: Codable, Equatable {
    let title: String
    let content: String // e.g., Markdown
}

/// A simple model for a step-by-step guide.
public struct StepByStepGuide: Codable, Equatable {
    let title: String
    let steps: [String]
}

/// A polymorphic enum that represents the different types of content the AI can generate.
public enum AIGeneratedContent: Decodable {
    case fullCourse(Course)
    case tutorial(Tutorial)
    case stepByStepGuide(StepByStepGuide)

    // Custom Decodable initializer to handle the different types from JSON.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ContentType.self, forKey: .type)
        let contentContainer = try container.superDecoder(forKey: .content)

        switch type {
        case .fullCourse:
            self = .fullCourse(try Course(from: contentContainer))
        case .tutorial:
            self = .tutorial(try Tutorial(from: contentContainer))
        case .stepByStepGuide:
            self = .stepByStepGuide(try StepByStepGuide(from: contentContainer))
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type, content
    }

    private enum ContentType: String, Decodable {
        case fullCourse, tutorial, stepByStepGuide
    }
}
