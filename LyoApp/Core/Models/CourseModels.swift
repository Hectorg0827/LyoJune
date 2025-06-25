
import Foundation

public struct Course: Codable, Identifiable {
    public let id: UUID
    public let title: String
    public let description: String

    public static func mockCourses() -> [Course] {
        return [
            Course(id: UUID(), title: "Introduction to SwiftUI", description: "Learn the basics of building apps with SwiftUI."),
            Course(id: UUID(), title: "Advanced iOS Development", description: "Take your iOS skills to the next level.")
        ]
    }
}
