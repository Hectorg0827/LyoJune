
import Foundation

@MainActor
class MessagesAPIService: BaseAPIService {
    static let shared = MessagesAPIService()
    
    private override init(apiClient: APIClientProtocol = {
        return ConfigurationManager.shared.shouldUseMockBackend ? MockAPIClient.shared : APIClient.shared
    }()) {
        super.init(apiClient: apiClient)
    }

    init(apiClient: APIClientProtocol) {
        super.init(apiClient: apiClient)
    }

    func fetchConversations() async throws -> [Conversation] {
        let endpoint = Endpoint(path: "/conversations")
        return try await apiClient.request(endpoint)
    }

    func markConversationAsRead(_ conversationId: UUID) async throws {
        let endpoint = Endpoint(path: "/conversations/\(conversationId)/read", method: .post)
        let _: EmptyResponse = try await apiClient.request(endpoint)
    }

    func sendMessage(_ message: String, to conversationId: UUID) async throws -> Message {
        let request = SendMessageRequest(conversationId: conversationId.uuidString, content: message, type: "text")
        let endpoint = Endpoint(path: "/conversations/\(conversationId)/messages", method: .post, body: request)
        return try await apiClient.request(endpoint)
    }

    func createConversation(with userId: String) async throws -> Conversation {
        let request = CreateConversationRequest(participantIds: [userId])
        let endpoint = Endpoint(path: "/conversations", method: .post, body: request)
        return try await apiClient.request(endpoint)
    }
}
