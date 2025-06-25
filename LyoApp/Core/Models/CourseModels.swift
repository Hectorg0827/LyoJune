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

// MARK: - Learning Course Models
public typealias LearningCourse = Course

public struct UserCourse: Codable, Identifiable {
    public let id: UUID
    public let courseId: UUID
    public let userId: UUID
    public let enrolledAt: Date
    public let progress: Double
    public let completedAt: Date?
    public let lastAccessedAt: Date
}

public struct Lesson: Codable, Identifiable {
    public let id: UUID
    public let courseId: UUID
    public let title: String
    public let description: String
    public let content: String
    public let duration: TimeInterval
    public let order: Int
    public let videoURL: URL?
    public let resourceURLs: [URL]
}

public struct UserProgress: Codable {
    public let userId: UUID
    public let totalXP: Int
    public let currentLevel: Int
    public let coursesCompleted: Int
    public let lessonsCompleted: Int
    public let studyStreak: Int
    public let averageSessionLength: TimeInterval
    public let weeklyProgress: [WeeklyProgress]
}

public struct WeeklyProgress: Codable {
    public let week: Date
    public let xpEarned: Int
    public let lessonsCompleted: Int
    public let timeSpent: TimeInterval
}

public struct Quiz: Codable, Identifiable {
    public let id: UUID
    public let topicId: UUID
    public let title: String
    public let description: String
    public let questions: [QuizQuestion]
    public let timeLimit: TimeInterval?
    public let passingScore: Double
}

public struct QuizQuestion: Codable, Identifiable {
    public let id: UUID
    public let question: String
    public let options: [String]
    public let correctAnswer: String
    public let explanation: String?
    public let points: Int
}
