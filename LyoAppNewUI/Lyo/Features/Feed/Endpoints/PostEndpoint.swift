import Foundation

/// A namespace for creating API endpoints related to Posts.
enum PostEndpoint {

    /// Creates an endpoint to create a new post.
    /// This should be called after the media has been successfully uploaded and committed.
    /// - Parameters:
    ///   - caption: The user-provided caption for the post.
    ///   - mediaAssetUrl: The URL or key of the committed media asset.
    /// - Returns: An `Endpoint` configured to fetch the newly created `Post` object.
    static func createPost(caption: String, mediaAssetUrl: String) -> Endpoint<Post> {
        let requestBody = CreatePostRequest(caption: caption, mediaAssetUrl: mediaAssetUrl)
        return try! Endpoint(
            path: "/v1/posts",
            method: .post,
            encodableBody: requestBody
        )
    }
}
