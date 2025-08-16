import Foundation

/// A type-safe representation of all possible navigation destinations within the app.
/// This enum is used by the `Router` to manage the navigation stack.
enum DeepLink: Hashable, Codable {

    // Learn
    case courseOverview(courseId: String) // Using String for easier URL parsing
    case lessonDetail(lessonId: String)

    // Feed
    case post(postId: String)
    case profile(userId: String)

    // Messaging
    case chat(chatId: String)

    // Other top-level tabs
    case learn
    case tutor
    case feed
    case notifications
    case search
}
