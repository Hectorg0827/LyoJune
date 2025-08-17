import Foundation

// MARK: - Trending Item

public struct TrendingItem: Codable, Hashable, Identifiable {
    public var id: String { topic }
    let topic: String
    let description: String
}

// MARK: - Search Result

/// A wrapper for a single search result, which can be of various types.
public struct SearchResult: Decodable, Identifiable {
    public var id: UUID { item.id }

    public let item: SearchResultItem
    public let whyMatched: String?

    // Custom Decodable initializer
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.whyMatched = try container.decodeIfPresent(String.self, forKey: .whyMatched)

        let type = try container.decode(ResultType.self, forKey: .type)
        let contentContainer = try container.superDecoder(forKey: .content)

        switch type {
        case .user:
            self.item = .user(try User(from: contentContainer))
        case .post:
            self.item = .post(try Post(from: contentContainer))
        case .course:
            self.item = .course(try Course(from: contentContainer))
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type, content, whyMatched
    }

    private enum ResultType: String, Decodable {
        case user, post, course
    }
}

/// An enum representing the actual content of a search result.
public enum SearchResultItem {
    case user(User)
    case post(Post)
    case course(Course)

    var id: UUID {
        switch self {
        case .user(let user): return user.id
        case .post(let post): return post.id
        case .course(let course): return course.id
        }
    }
}
