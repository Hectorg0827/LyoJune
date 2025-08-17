import Foundation

/// A namespace for creating API endpoints related to User Profiles.
enum ProfileEndpoint {

    /// Creates an endpoint to fetch a user's profile.
    /// - Parameter userId: The ID of the user whose profile to fetch.
    /// - Returns: An `Endpoint` configured to fetch a `UserProfile` object.
    static func getProfile(for userId: UUID) -> Endpoint<UserProfile> {
        return Endpoint(path: "/v1/profile/\(userId.uuidString)", method: .get)
    }

    /// Creates an endpoint for the current user to update their own profile.
    /// - Parameter updateRequest: The request body containing the fields to update.
    /// - Returns: An `Endpoint` configured to fetch the updated `UserProfile`.
    static func updateProfile(_ updateRequest: UpdateProfileRequest) -> Endpoint<UserProfile> {
        return try! Endpoint(
            path: "/v1/profile",
            method: .put,
            encodableBody: updateRequest
        )
    }

    /// Creates an endpoint to follow a user.
    /// - Parameter userId: The ID of the user to follow.
    /// - Returns: An `Endpoint` that expects an empty response.
    static func followUser(userId: UUID) -> Endpoint<EmptyResponse> {
        return Endpoint(path: "/v1/users/\(userId.uuidString)/follow", method: .post)
    }

    /// Creates an endpoint to unfollow a user.
    /// - Parameter userId: The ID of the user to unfollow.
    /// - Returns: An `Endpoint` that expects an empty response.
    static func unfollowUser(userId: UUID) -> Endpoint<EmptyResponse> {
        // Typically, this would be a DELETE request, but some APIs use POST for simplicity.
        // Assuming DELETE for RESTful correctness.
        return Endpoint(path: "/v1/users/\(userId.uuidString)/follow", method: .delete)
    }
}
