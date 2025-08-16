import Foundation

/// The live implementation of the `FeedServicing` protocol.
/// This class uses an `HTTPClient` to fetch all data related to the feed, stories, and post creation.
public final class FeedService: FeedServicing {

    private let httpClient: HTTPClienting

    public init(httpClient: HTTPClienting) {
        self.httpClient = httpClient
    }

    // MARK: - Feed

    public func getForYouFeed() async throws -> [Post] {
        let endpoint = FeedEndpoint.getForYouFeed()
        return try await httpClient.request(endpoint)
    }

    public func getFollowingFeed() async throws -> [Post] {
        let endpoint = FeedEndpoint.getFollowingFeed()
        return try await httpClient.request(endpoint)
    }

    // MARK: - Stories

    public func getStories() async throws -> [Story] {
        let endpoint = StoryEndpoint.getStories()
        return try await httpClient.request(endpoint)
    }

    // MARK: - Media Upload

    public func getPresignedURL(contentType: String, fileExtension: String) async throws -> PresignedURLResponse {
        let endpoint = MediaEndpoint.getPresignedURL(contentType: contentType, fileExtension: fileExtension)
        return try await httpClient.request(endpoint)
    }

    public func commitMedia(assetKey: String) async throws {
        let endpoint = MediaEndpoint.commitMedia(assetKey: assetKey)
        _ = try await httpClient.request(endpoint)
    }

    // MARK: - Post Creation

    public func createPost(caption: String, mediaAssetUrl: String) async throws -> Post {
        let endpoint = PostEndpoint.createPost(caption: caption, mediaAssetUrl: mediaAssetUrl)
        return try await httpClient.request(endpoint)
    }
}
