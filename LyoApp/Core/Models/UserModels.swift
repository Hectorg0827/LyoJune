

import Foundation

public struct User: Codable, Identifiable {
    public let id: String
    public let email: String
    public let firstName: String
    public let lastName: String
    public let username: String
    public let avatar: String?
    public let bio: String?
    public let isVerified: Bool
    public let createdAt: String
    public let updatedAt: String

    public var fullName: String {
        return "\(firstName) \(lastName)"
    }
}

