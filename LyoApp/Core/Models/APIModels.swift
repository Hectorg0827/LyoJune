
import Foundation

// MARK: - Request/Response Models

public struct MarkStoryWatchedRequest: Codable {
    let storyId: String
}

public struct CreateStoryRequest: Codable {
    let content: String
    let mediaURL: String?
    let mediaType: String?
    let duration: Int?
}

public struct MarkConversationReadRequest: Codable {
    let conversationId: String
}

public struct SendMessageRequest: Codable {
    let conversationId: String
    let content: String
    let type: String
}

public struct CreateConversationRequest: Codable {
    let participantIds: [String]
}

public struct SearchFilters: Codable {
    let contentType: String?
    let category: String?
    let difficulty: String?
    let dateRange: String?
}

public struct SearchResults: Codable {
    let results: [SearchResult]
    let totalCount: Int
    let page: Int
    let pageSize: Int
    let hasMore: Bool
}

public struct SearchResult: Codable, Identifiable {
    public let id: UUID
    let title: String
    let description: String
    let type: ResultType
    let relevanceScore: Double
    let url: String?
    let thumbnailURL: String?
    let createdAt: String
    let author: String?

    public enum ResultType: String, CaseIterable, Codable {
        case course = "course"
        case video = "video"
        case article = "article"
        case book = "book"
        case user = "user"
        case discussion = "discussion"

        var icon: String {
            switch self {
            case .course:
                return "graduationcap"
            case .video:
                return "play.rectangle"
            case .article:
                return "doc.text"
            case .book:
                return "book"
            case .user:
                return "person"
            case .discussion:
                return "bubble.left.and.bubble.right"
            }
        }
    }
}

public struct SaveSearchRequest: Codable {
    let query: String
}

public struct AISearchRequest: Codable {
    let query: String
    let context: String?
    let filters: SearchFilters?

    public init(query: String, context: String? = nil, filters: SearchFilters? = nil) {
        self.query = query
        self.context = context
        self.filters = filters
    }
}

public struct AvatarUploadResponse: Codable {
    let url: String
}

public struct FollowUserRequest: Codable {
    let userId: String
}

// MARK: - Message Model
public struct Message: Codable, Identifiable {
    public let id: UUID
    let conversationId: UUID
    let senderId: String
    let content: String
    let type: String
    let timestamp: Date
    let isRead: Bool
    let editedAt: Date?
}
