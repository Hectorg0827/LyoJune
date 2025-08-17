import Foundation

// MARK: - Course

/// Represents a course available to the user.
public struct Course: Codable, Identifiable, Equatable {
    public let id: UUID
    public let title: String
    public let description: String
    public let thumbnailURL: URL?
}

// MARK: - Lesson & Content Blocks

/// Represents a single lesson within a course, composed of various content blocks.
public struct Lesson: Codable, Identifiable, Equatable {
    public let id: UUID
    public let title: String
    public let contentBlocks: [LessonBlock]

    // Custom coding keys to handle the change from `content` to `contentBlocks`
    enum CodingKeys: String, CodingKey {
        case id, title, contentBlocks = "content"
    }
}

/// A polymorphic enum representing a single block of content within a lesson.
public enum LessonBlock: Decodable, Hashable {
    case heading(String)
    case paragraph(String)
    case youtubeVideo(videoId: String)
    case link(title: String, url: URL)

    // Custom Decodable initializer
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(BlockType.self, forKey: .type)

        switch type {
        case .heading:
            let text = try container.decode(String.self, forKey: .text)
            self = .heading(text)
        case .paragraph:
            let text = try container.decode(String.self, forKey: .text)
            self = .paragraph(text)
        case .youtubeVideo:
            let videoId = try container.decode(String.self, forKey: .videoId)
            self = .youtubeVideo(videoId: videoId)
        case .link:
            let title = try container.decode(String.self, forKey: .title)
            let url = try container.decode(URL.self, forKey: .url)
            self = .link(title: title, url: url)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type, text, videoId, title, url
    }

    private enum BlockType: String, Decodable {
        case heading, paragraph, youtubeVideo, link
    }
}


// MARK: - Resource

/// Represents a piece of content in the Resource Hub.
public struct Resource: Codable, Identifiable, Equatable {
    // ... (same as before)
    public enum ResourceType: String, Codable {
        case video, article, ebook, podcast, course
    }
    public let id: UUID
    public let type: ResourceType
    public let title: String
    public let description: String
    public let source: String
    public let url: URL
    public let durationMinutes: Int?
}
