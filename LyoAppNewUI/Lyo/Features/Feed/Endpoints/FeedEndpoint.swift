import Foundation

/// A namespace for creating API endpoints related to the main content feeds.
enum FeedEndpoint {

    /// Creates an endpoint to fetch the "For-You" feed.
    /// - Returns: An `Endpoint` configured to fetch an array of `Post` objects.
    static func getForYouFeed() -> Endpoint<[Post]> {
        return Endpoint(path: "/v1/feed/for-you", method: .get)
    }

    /// Creates an endpoint to fetch the "Following" feed.
    /// - Returns: An `Endpoint` configured to fetch an array of `Post` objects.
    static func getFollowingFeed() -> Endpoint<[Post]> {
        return Endpoint(path: "/v1/feed/following", method: .get)
    }
}
