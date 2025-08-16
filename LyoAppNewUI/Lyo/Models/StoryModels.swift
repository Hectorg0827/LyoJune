import Foundation
import CoreMedia

/// Represents a user's story, which is a collection of items.
public struct Story: Codable, Identifiable, Equatable {
    public let id: UUID
    public let user: User
    public let items: [StoryItem]
}

/// Represents a single piece of media within a story.
public struct StoryItem: Codable, Identifiable, Equatable {

    /// The type of media for the story item.
    public enum MediaType: String, Codable {
        case image, video
    }

    public let id: UUID
    public let mediaURL: URL
    public let type: MediaType

    /// The duration in seconds for which the story item should be displayed.
    public let duration: TimeInterval
}
