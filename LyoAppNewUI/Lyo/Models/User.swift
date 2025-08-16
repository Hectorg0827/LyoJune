import Foundation

/// A simple model representing a user in the system.
public struct User: Codable, Identifiable, Equatable {
    public let id: UUID
    public let username: String
    public let profileImageURL: URL?
}
