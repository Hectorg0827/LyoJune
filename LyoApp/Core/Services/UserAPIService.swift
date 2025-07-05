
import Foundation

@MainActor
class CDUserAPIService: BaseAPIService {
    static let shared = CDUserAPIService()
    
    private override init(apiClient: APIClientProtocol = APIClient.shared) {
        super.init(apiClient: apiClient)
    }

    init(apiClient: APIClientProtocol) {
        super.init(apiClient: apiClient)
    }

    func fetchCDUserProfile(_ userId: String? = nil) async throws -> CDUserProfile {
        let path = userId != nil ? "/profile/\(userId!)" : "/profile"
        let endpoint = Endpoint(path: path)
        return try await apiClient.request(endpoint)
    }

    func updateCDUserProfile(_ profile: UpdateCDUserProfileRequest) async throws -> CDUserProfile {
        let endpoint = Endpoint(path: "/profile", method: .put, body: profile)
        return try await apiClient.request(endpoint)
    }

    func uploadAvatar(_ imageData: Data) async throws -> String {
        let endpoint = Endpoint(path: "/profile/avatar", method: .post, body: imageData)
        let response: AvatarUploadResponse = try await apiClient.request(endpoint)
        return response.url
    }

    func followCDUser(_ userId: String) async throws {
        let endpoint = Endpoint(path: "/profile/follow", method: .post, body: FollowCDUserRequest(userId: userId))
        let _: EmptyResponse = try await apiClient.request(endpoint)
    }

    func unfollowCDUser(_ userId: String) async throws {
        let endpoint = Endpoint(path: "/profile/follow/\(userId)", method: .delete)
        let _: EmptyResponse = try await apiClient.request(endpoint)
    }
}
