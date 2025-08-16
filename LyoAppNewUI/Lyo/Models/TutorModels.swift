import Foundation

// MARK: - Core Chat Model

/// Represents a single message in the chat conversation with the Tutor.
public struct TutorMessage: Codable, Identifiable, Equatable {

    /// The sender of the message.
    public enum Sender: String, Codable {
        case user, tutor
    }

    /// The specific type of content contained in the message from the tutor.
    public enum ContentType: String, Codable {
        case text, hint, explanation, question, planUpdate, remediation, tutorial, stepByStepGuide
    }

    public let id: UUID
    public let sender: Sender
    public let type: ContentType
    public let text: String

    // Optional content blocks
    public let question: Question?
    public let tutorial: Tutorial?
    public let stepByStepGuide: StepByStepGuide?
}

/// Represents a multiple-choice question sent by the Tutor.
public struct Question: Codable, Identifiable, Equatable {
    public let id: UUID
    public let text: String
    public let options: [Option]

    /// Represents a single choice in a multiple-choice question.
    public struct Option: Codable, Identifiable, Equatable {
        public let id: String // A, B, C, etc.
        public let text: String
    }
}

// MARK: - API Models

/// The request body for posting a user's turn to the tutor.
public struct TutorTurnRequest: Codable {
    let text: String
    let selectedOptionId: String?
}

/// The response from the tutor after a user's turn, containing one or more new messages.
public typealias TutorTurnResponse = [TutorMessage]

/// Represents the saved state of a tutor session for a learner.
public struct TutorState: Codable {
    let learnerId: String
    let history: [TutorMessage]
}
