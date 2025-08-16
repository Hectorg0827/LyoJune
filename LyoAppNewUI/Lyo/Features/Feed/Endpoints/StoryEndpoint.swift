import Foundation

/// A namespace for creating API endpoints related to Stories.
enum StoryEndpoint {

    /// Creates an endpoint to fetch the list of stories for the main feed tray.
    /// The response should be an array of `Story` objects, which contain the user
    /// and a list of story items.
    /// - Returns: An `Endpoint` configured to fetch an array of `Story` objects.
    static func getStories() -> Endpoint<[Story]> {
        return Endpoint(path: "/v1/stories", method: .get)
    }

    /// Creates an endpoint to fetch the full story reel for a specific user.
    /// This might be used if the initial stories payload is lightweight and
    /// the full reel is fetched on demand.
    /// - Parameter userId: The ID of the user whose story reel is being requested.
    /// - Returns: An `Endpoint` configured to fetch a `Story` object.
    static func getStoryReel(for userId: UUID) -> Endpoint<Story> {
        return Endpoint(path: "/v1/stories/reel/\(userId.uuidString)", method: .get)
    }
}
