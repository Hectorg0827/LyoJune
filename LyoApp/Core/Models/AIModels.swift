import Foundation

// MARK: - AI Models
public struct AIRequest: Codable {
    public let message: String
    public let context: [ConversationMessage]
    public let userId: String?
    
    public init(message: String, context: [ConversationMessage], userId: String?) {
        self.message = message
        self.context = context
        self.userId = userId
    }
}

public struct AIResponse: Codable {
    public let message: String
    public let timestamp: Date
    public let metadata: [String: String]?
    
    public init(message: String, timestamp: Date = Date(), metadata: [String: String]? = nil) {
        self.message = message
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

public struct ConversationMessage: Codable, Identifiable {
    public let id: UUID
    public let role: MessageRole
    public let content: String
    public let timestamp: Date
    
    public enum MessageRole: String, Codable {
        case user
        case assistant
        case system
    }
    
    public init(id: UUID = UUID(), role: MessageRole, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

// MARK: - AI Suggestion Models
public struct AISuggestion: Identifiable, Codable {
    public let id: UUID
    public let type: SuggestionType
    public let title: String
    public let content: String
    public let action: SuggestionAction
    public let timestamp: Date

    public init(id: UUID, type: SuggestionType, title: String, content: String, action: SuggestionAction) {
        self.id = id
        self.type = type
        self.title = title
        self.content = content
        self.action = action
        self.timestamp = Date()
    }
}

public enum SuggestionType: String, Codable {
    case tip
    case encouragement
    case help
    case celebration
    case reminder
}

public enum SuggestionAction: String, Codable {
    case startLearning
    case continueStreak
    case takeQuiz
    case getHelp
    case nextLesson
    case reviewProgress
}

// MARK: - User Activity Models
public struct CDUserActivity: Codable {
    public let type: ActivityType
    public let duration: TimeInterval
    public let context: [String: String]
    public let timestamp: Date

    public enum ActivityType: String, Codable {
        case courseViewing
        case struggling
        case completed
        case idle
    }
}