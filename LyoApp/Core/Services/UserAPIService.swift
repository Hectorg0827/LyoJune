
import Foundation

@MainActor
class UserAPIService: APIService {
    static let shared = UserAPIService()
    let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }

    func fetchUserProfile(_ userId: String? = nil) async throws -> UserProfile {
        let path = userId != nil ? "/profile/\(userId!)" : "/profile"
        let endpoint = Endpoint(path: path)
        return try await apiClient.request(endpoint)
    }

    func updateUserProfile(_ profile: UpdateUserProfileRequest) async throws -> UserProfile {
        let endpoint = Endpoint(path: "/profile", method: .put, body: profile)
        return try await apiClient.request(endpoint)
    }

    func uploadAvatar(_ imageData: Data) async throws -> String {
        let endpoint = Endpoint(path: "/profile/avatar", method: .post, body: imageData)
        let response: AvatarUploadResponse = try await apiClient.request(endpoint)
        return response.url
    }

    func followUser(_ userId: String) async throws {
        let endpoint = Endpoint(path: "/profile/follow", method: .post, body: FollowUserRequest(userId: userId))
        let _: EmptyResponse = try await apiClient.request(endpoint)
    }

    func unfollowUser(_ userId: String) async throws {
        let endpoint = Endpoint(path: "/profile/follow/\(userId)", method: .delete)
        let _: EmptyResponse = try await apiClient.request(endpoint)
    }
}
