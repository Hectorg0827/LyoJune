
import Foundation
import Combine

@MainActor
class CommunityAPIService: BaseAPIService {
    static let shared = CommunityAPIService()
    
    private override init(apiClient: APIClientProtocol = APIClient.shared) {
        super.init(apiClient: apiClient)
    }
    
    init(apiClient: APIClientProtocol) {
        super.init(apiClient: apiClient)
    }

    // MARK: - Posts
    func getPosts(filter: PostFilter? = nil) async throws -> [Post] {
        var endpoint = Endpoint(path: "/posts")
        // Add filter logic here
        return try await apiClient.request(endpoint)
    }

    func createPost(_ post: CreatePostRequest) async throws -> Post {
        let endpoint = Endpoint(path: "/posts", method: .post, body: post)
        return try await apiClient.request(endpoint)
    }

    func likePost(_ postId: String) async throws {
        let endpoint = Endpoint(path: "/posts/\(postId)/like", method: .post)
        let _: EmptyResponse = try await apiClient.request(endpoint)
    }

    func unlikePost(_ postId: String) async throws {
        let endpoint = Endpoint(path: "/posts/\(postId)/like", method: .delete)
        let _: EmptyResponse = try await apiClient.request(endpoint)
    }

    func addComment(_ postId: String, content: String) async throws -> Comment {
        let request = AddCommentRequest(postId: postId, content: content)
        let endpoint = Endpoint(path: "/posts/\(postId)/comments", method: .post, body: request)
        return try await apiClient.request(endpoint)
    }

    // MARK: - Study Groups
    func getStudyGroups() async throws -> [StudyGroup] {
        let endpoint = Endpoint(path: "/community/groups")
        return try await apiClient.request(endpoint)
    }

    func joinStudyGroup(_ groupId: String) async throws {
        let endpoint = Endpoint(path: "/community/groups/\(groupId)/join", method: .post)
        let _: EmptyResponse = try await apiClient.request(endpoint)
    }

    func leaveStudyGroup(_ groupId: String) async throws {
        let endpoint = Endpoint(path: "/community/groups/\(groupId)/leave", method: .delete)
        let _: EmptyResponse = try await apiClient.request(endpoint)
    }

    func createStudyGroup(_ group: CreateStudyGroupRequest) async throws -> StudyGroup {
        let endpoint = Endpoint(path: "/community/groups", method: .post, body: group)
        return try await apiClient.request(endpoint)
    }

    // MARK: - Events
    func getEvents() async throws -> [StudyEvent] {
        let endpoint = Endpoint(path: "/community/events")
        return try await apiClient.request(endpoint)
    }

    func joinEvent(_ eventId: String) async throws {
        let endpoint = Endpoint(path: "/community/events/\(eventId)/join", method: .post)
        let _: EmptyResponse = try await apiClient.request(endpoint)
    }
}
