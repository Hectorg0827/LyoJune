import Foundation

/// Represents a single post in the user's feed, designed for a full-screen video experience.
public struct Post: Codable, Identifiable, Equatable {
    public let id: UUID
    public let user: User
    public let videoURL: URL
    public let caption: String

    public let likeCount: Int
    public let commentCount: Int
    public let shareCount: Int
}

// MARK: - API Models for Post Creation

/// The request body for creating a new post.
public struct CreatePostRequest: Codable {
    let caption: String

    /// The URL or key of the media asset that has already been uploaded and committed.
    let mediaAssetUrl: String
}
