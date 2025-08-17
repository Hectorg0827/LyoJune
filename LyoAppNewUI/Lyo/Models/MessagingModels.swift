import Foundation

/// Represents a single conversation thread in the user's inbox.
public struct ChatThread: Codable, Identifiable, Equatable {
    /// The unique identifier for the chat session.
    public let id: String

    /// The list of users participating in the chat, excluding the current user.
    public let participants: [User]

    /// The most recent message in the thread, for preview purposes.
    public let lastMessage: ChatMessage
}

/// Represents a single message within a chat conversation.
public struct ChatMessage: Codable, Identifiable, Equatable {
    public let id: UUID

    /// The user who sent the message.
    public let sender: User

    /// The text content of the message.
    public let text: String

    /// The timestamp when the message was sent.
    public let timestamp: Date
}
