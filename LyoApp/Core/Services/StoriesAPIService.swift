
import Foundation

@MainActor
class StoriesAPIService: BaseAPIService {
    static let shared = StoriesAPIService()
    
    private override init(apiClient: APIClientProtocol = APIClient.shared) {
        super.init(apiClient: apiClient)
    }

    init(apiClient: APIClientProtocol) {
        super.init(apiClient: apiClient)
    }

    func fetchStories() async throws -> [Story] {
        let endpoint = Endpoint(path: "/stories")
        return try await apiClient.request(endpoint)
    }

    func markStoryAsWatched(_ storyId: UUID) async throws {
        let endpoint = Endpoint(path: "/stories/\(storyId)/watched", method: .post)
        let _: EmptyResponse = try await apiClient.request(endpoint)
    }

    func createStory(_ story: CreateStoryRequest) async throws -> Story {
        let endpoint = Endpoint(path: "/stories", method: .post, body: story)
        return try await apiClient.request(endpoint)
    }
}
