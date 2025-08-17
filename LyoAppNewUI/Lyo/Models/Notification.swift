import Foundation

/// Represents a single notification item.
public struct Notification: Codable, Identifiable, Equatable {

    /// The type of the notification, used to determine the icon and potentially the action.
    public enum NotificationType: String, Codable {
        case newMessage = "new_message"
        case newFollower = "new_follower"
        case postLike = "post_like"
        case postComment = "post_comment"
        case tutorMessage = "tutor_message"
        // Add other types as needed
    }

    public let id: UUID
    public let type: NotificationType

    /// The human-readable text for the notification.
    /// e.g., "Jules liked your post."
    public let text: String

    /// The timestamp when the notification was generated.
    public let timestamp: Date

    /// An optional string representing the navigation destination.
    /// e.g., "lyo://post/1234-abcd", "lyo://chat/5678-efgh"
    public let deepLink: String?
}
