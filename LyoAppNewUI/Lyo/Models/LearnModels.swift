import Foundation

// MARK: - Course

/// Represents a course available to the user.
public struct Course: Codable, Identifiable, Equatable {
    public let id: UUID
    public let title: String
    public let description: String
    public let thumbnailURL: URL?
}

// MARK: - Lesson

/// Represents a single lesson within a course.
public struct Lesson: Codable, Identifiable, Equatable {
    public let id: UUID
    public let title: String

    /// The main content of the lesson, which could be Markdown, plain text, or HTML.
    public let content: String

    /// The estimated time to complete the lesson, in minutes.
    public let durationMinutes: Int
}

// MARK: - Resource

/// Represents a piece of content in the Resource Hub.
public struct Resource: Codable, Identifiable, Equatable {

    /// The type of the resource content.
    public enum ResourceType: String, Codable {
        case video, article, ebook, podcast, course
    }

    public let id: UUID
    public let type: ResourceType
    public let title: String
    public let description: String

    /// The source or publisher of the content (e.g., "YouTube", "Lyo Originals").
    public let source: String

    /// The direct URL to the resource.
    public let url: URL

    /// An optional duration for time-based media, in minutes.
    public let durationMinutes: Int?
}
