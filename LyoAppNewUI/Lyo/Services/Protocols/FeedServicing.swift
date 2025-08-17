import Foundation

/// A protocol that defines the contract for a service that handles all data
/// for the Feed, Stories, and Post Composer features.
public protocol FeedServicing {

    // MARK: - Feed

    /// Fetches the "For-You" feed from the backend.
    func getForYouFeed() async throws -> [Post]

    /// Fetches the "Following" feed from the backend.
    func getFollowingFeed() async throws -> [Post]

    // MARK: - Stories

    /// Fetches the list of stories for the main feed tray.
    func getStories() async throws -> [Story]

    // MARK: - Media Upload

    /// Requests a presigned URL from the backend for a direct-to-storage file upload.
    func getPresignedURL(contentType: String, fileExtension: String) async throws -> PresignedURLResponse

    /// Notifies the backend that the file has been successfully uploaded to the presigned URL.
    func commitMedia(assetKey: String) async throws

    // MARK: - Post Creation

    /// Creates a new post after the media has been uploaded and committed.
    func createPost(caption: String, mediaAssetUrl: String) async throws -> Post
}
