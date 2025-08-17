import Foundation

// MARK: - Profile Models

/// Represents the full profile data for a user, extending the basic `User` model.
public struct UserProfile: Codable, Equatable {
    let id: UUID
    let username: String
    let profileImageURL: URL?
    let bio: String?
    let followerCount: Int
    let followingCount: Int
    let isCurrentUser: Bool // Indicates if this profile is the logged-in user's
    let isFollowedByCurrentUser: Bool // Indicates if the logged-in user follows this profile
}

/// The request body for updating a user's profile.
/// All properties are optional to allow for partial updates.
public struct UpdateProfileRequest: Codable {
    let username: String?
    let bio: String?
}

// MARK: - Settings Models

/// Represents the user's notification preferences.
public struct NotificationSettings: Codable, Equatable {
    let likes: Bool
    let comments: Bool
    let newFollowers: Bool
}

/// Represents the user's privacy preferences.
public struct PrivacySettings: Codable, Equatable {
    let isPrivateAccount: Bool
}

/// A wrapper struct for all user settings, used for GET/PUT requests.
public struct UserSettings: Codable, Equatable {
    let notifications: NotificationSettings
    let privacy: PrivacySettings
}

// MARK: - Moderation Models

/// The request body for reporting a piece of content.
public struct ReportContentRequest: Codable {
    enum ContentType: String, Codable {
        case post, user, comment
    }

    let contentId: String
    let contentType: ContentType
    let reason: String
}
