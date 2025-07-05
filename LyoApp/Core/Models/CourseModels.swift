import Foundation
import SwiftUI

public struct CourseProgress: Codable {
    public let completionPercentage: Double
    public let lessonsCompleted: Int
    public let totalLessons: Int
    public let timeSpent: TimeInterval
    
    public init(completionPercentage: Double, lessonsCompleted: Int, totalLessons: Int, timeSpent: TimeInterval) {
        self.completionPercentage = completionPercentage
        self.lessonsCompleted = lessonsCompleted
        self.totalLessons = totalLessons
        self.timeSpent = timeSpent
    }
}

public struct CourseThumbnail: Codable {
    public let url: String
    
    public init(url: String) {
        self.url = url
    }
}

public struct Instructor: Codable, Identifiable {
    public let id: UUID
    public let name: String
    public let bio: String
    public let avatarURL: URL?
    public let expertise: [String]
    public let rating: Double
    public let totalStudents: Int
    public let totalCourses: Int
    public let isVerified: Bool
    public let socialLinks: [String: String]
    
    public init(id: UUID, name: String, bio: String, avatarURL: URL? = nil, expertise: [String] = [], rating: Double = 0.0, totalStudents: Int = 0, totalCourses: Int = 0, isVerified: Bool = false, socialLinks: [String: String] = [:]) {
        self.id = id
        self.name = name
        self.bio = bio
        self.avatarURL = avatarURL
        self.expertise = expertise
        self.rating = rating
        self.totalStudents = totalStudents
        self.totalCourses = totalCourses
        self.isVerified = isVerified
        self.socialLinks = socialLinks
    }
}

public enum CourseCategory: String, CaseIterable, Codable {
    case programming = "Programming"
    case development = "Development"
    case design = "Design" 
    case business = "Business"
    case marketing = "Marketing"
    case science = "Science"
    case math = "Mathematics"
    case language = "Language"
    case arts = "Art"
    case health = "Health"
    case other = "Other"
    
    var gradient: LinearGradient {
        switch self {
        case .programming:
            return LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .development:
            return LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .design:
            return LinearGradient(colors: [.pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .business:
            return LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .marketing:
            return LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .science:
            return LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .math:
            return LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .language:
            return LinearGradient(colors: [.mint, .green], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .arts:
            return LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .health:
            return LinearGradient(colors: [.red, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .other:
            return LinearGradient(colors: [.gray, .secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    var icon: String {
        switch self {
        case .programming: return "chevron.left.forwardslash.chevron.right"
        case .development: return "hammer.fill"
        case .design: return "paintbrush.fill"
        case .business: return "briefcase.fill"
        case .marketing: return "megaphone.fill"
        case .science: return "flask.fill"
        case .math: return "function"
        case .language: return "globe"
        case .arts: return "palette.fill"
        case .health: return "heart.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    // MARK: - CourseCategory Display Name
    var name: String { rawValue.capitalized }
}

public enum CourseDifficulty: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate" 
    case advanced = "Advanced"
    case expert = "Expert"
}

public struct Course: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let imageURL: String?
    public let userProgress: CourseProgress?
    public let thumbnail: CourseThumbnail?
    public let instructor: Instructor
    public let duration: TimeInterval
    public let category: CourseCategory
    public let difficulty: CourseDifficulty
    
    public init(id: UUID = UUID(), title: String, description: String, imageURL: String? = nil, userProgress: CourseProgress? = nil, thumbnail: CourseThumbnail? = nil, instructor: Instructor, category: CourseCategory = .programming, difficulty: CourseDifficulty = .beginner, duration: TimeInterval = 3600) {
        self.id = id
        self.title = title
        self.description = description
        self.imageURL = imageURL
        self.userProgress = userProgress
        self.thumbnail = thumbnail
        self.instructor = instructor
        self.category = category
        self.difficulty = difficulty
        self.duration = duration
    }

    public static func mockCourses() -> [Course] {
        let instructor1 = Instructor(
            id: UUID(),
            name: "Dr. Sarah Johnson",
            bio: "iOS Development Expert with 10+ years experience",
            avatarURL: nil,
            expertise: ["iOS", "SwiftUI", "Mobile Development"],
            rating: 4.8,
            totalStudents: 1250,
            totalCourses: 8,
            isVerified: true
        )
        
        let instructor2 = Instructor(
            id: UUID(),
            name: "Mark Thompson",
            bio: "Senior iOS Engineer at Apple",
            avatarURL: nil,
            expertise: ["iOS", "Swift", "App Architecture"],
            rating: 4.9,
            totalStudents: 2100,
            totalCourses: 12,
            isVerified: true
        )
        
        return [
            Course(
                id: UUID(),
                title: "Introduction to SwiftUI",
                description: "Learn the basics of building apps with SwiftUI.",
                imageURL: nil,
                userProgress: CourseProgress(completionPercentage: 0.75, lessonsCompleted: 15, totalLessons: 20, timeSpent: 3600),
                thumbnail: CourseThumbnail(url: "https://via.placeholder.com/300x200"),
                instructor: instructor1,
                category: .programming,
                difficulty: .beginner,
                duration: 7200
            ),
            Course(
                id: UUID(),
                title: "Advanced iOS Development",
                description: "Take your iOS skills to the next level.",
                imageURL: nil,
                userProgress: CourseProgress(completionPercentage: 0.30, lessonsCompleted: 6, totalLessons: 20, timeSpent: 1800),
                thumbnail: CourseThumbnail(url: "https://via.placeholder.com/300x200"),
                instructor: instructor2,
                category: .development,
                difficulty: .advanced,
                duration: 10800
            )
        ]
    }
}

// MARK: - Learning Course Models
// Use the Course from this file specifically to avoid ambiguity
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
    
    public init(userId: UUID, totalXP: Int, currentLevel: Int, coursesCompleted: Int, lessonsCompleted: Int, studyStreak: Int, averageSessionLength: TimeInterval, weeklyProgress: [WeeklyProgress]) {
        self.userId = userId
        self.totalXP = totalXP
        self.currentLevel = currentLevel
        self.coursesCompleted = coursesCompleted
        self.lessonsCompleted = lessonsCompleted
        self.studyStreak = studyStreak
        self.averageSessionLength = averageSessionLength
        self.weeklyProgress = weeklyProgress
    }
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

// Removed duplicate QuizQuestion - use the canonical one from AppModels.swift

public struct EnrollmentRequest: Codable {
    public let courseId: String
}

public struct ProgressUpdateRequest: Codable {
    public let courseId: String
    public let lessonId: String
    public let progress: Double
    public let completedAt: Date?
}

public struct ProgressResponse: Codable {
    public let success: Bool
    public let totalProgress: Double
}

public struct CourseCompletionRequest: Codable {
    public let courseId: String
    public let completedAt: Date
}

public struct CompletionResponse: Codable {
    public let success: Bool
    public let certificateUrl: String?
    public let points: Int
}
