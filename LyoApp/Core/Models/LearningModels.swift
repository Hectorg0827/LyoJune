import Foundation
import Security
import SwiftUI

// MARK: - Learning Models defined here that work with AppModels.swift types
// Course is defined in AppModels.swift and can be used directly

// MARK: - MediaType is defined in AppModels.swift

// Learning requests
public struct EnrollCourseRequest: Codable {
    let courseId: String
}

public struct CompleteLessonRequest: Codable {
    let lessonId: String
    let timeSpent: TimeInterval
    let score: Double?
    let completedAt: Date
}

public struct GenerateStudyPlanRequest: Codable {
    let learningGoals: [String]
    let hoursPerWeek: Int
    let preferredDifficulty: String
}

public struct UpdateStudyPlanRequest: Codable {
    let planId: String
    let progress: StudyPlanProgress
}

public struct GenerateQuizRequest: Codable {
    let topicId: String
    let difficulty: String
    let questionCount: Int
}

public struct SubmitQuizAnswerRequest: Codable {
    let quizId: String
    let questionId: String
    let answer: String
}

// Community requests
public struct PostFilter: Codable {
    let category: String?
    let sortBy: String?
    let timeframe: String?
}

public struct CreatePostRequest: Codable {
    let title: String
    let content: String
    let category: String
    let tags: [String]
    let mediaURLs: [String]?
}

public struct LikePostRequest: Codable {
    let postId: String
}

public struct AddCommentRequest: Codable {
    let postId: String
    let content: String
}

public struct CreateCommentRequest: Codable {
    let content: String
}

public struct SharePostRequest: Codable {
    let postId: String
    let message: String?
}

public struct ReportPostRequest: Codable {
    let reason: String
}

public struct JoinGroupRequest: Codable {
    let groupId: String
}

public struct CreateStudyGroupRequest: Codable {
    let name: String
    let description: String
    let category: CourseCategory
    let isPrivate: Bool
    let maxMembers: Int?
}

public struct JoinEventRequest: Codable {
    let eventId: String
}

// Response models
public struct LessonProgress: Codable {
    let lessonId: String
    let completed: Bool
    let score: Double?
    let timeSpent: TimeInterval
    let completedAt: Date
}

public struct StudyPlan: Codable {
    let id: String
    let userId: String
    let goals: [String]
    let timeline: StudyTimeline
    let recommendations: [LearningRecommendation]
    let progress: StudyPlanProgress
    let createdAt: Date
    let updatedAt: Date
}

public struct StudyTimeline: Codable {
    let startDate: Date
    let endDate: Date
    let milestones: [StudyMilestone]
}

public struct StudyMilestone: Codable {
    let id: String
    let title: String
    let description: String
    let targetDate: Date
    let isCompleted: Bool
    let coursesRequired: [String]
}

public struct StudyPlanProgress: Codable {
    let completedMilestones: [String]
    let currentMilestone: String?
    let overallProgress: Double
    let weeklyHours: Int
    let streakDays: Int
}

public struct QuizFeedback: Codable {
    let questionId: String
    let isCorrect: Bool
    let explanation: String
    let correctAnswer: String?
    let score: Int
    let aiTips: [String]?
}

public struct LearningRecommendation: Codable {
    let id: String
    let type: RecommendationType
    let title: String
    let description: String
    let targetId: String
    let relevanceScore: Double
    let reason: String

    public enum RecommendationType: String, Codable {
        case course = "course"
        case lesson = "lesson"
        case video = "video"
        case article = "article"
        case practice = "practice"
        case review = "review"
    }
}



// MARK: - Community Models
public struct StudyGroup: Codable, Identifiable {
    public let id: UUID
    let name: String
    let description: String
    let category: CourseCategory
    var memberCount: Int
    let maxMembers: Int
    let isPrivate: Bool
    let createdBy: UUID
    let createdAt: Date
    let imageURL: String?
    let tags: [String]
    let membershipStatus: MembershipStatus?
    var isUserMember: Bool = false
    
    public init(id: UUID = UUID(), name: String, description: String, category: CourseCategory, memberCount: Int = 1, maxMembers: Int = 20, isPrivate: Bool = false, createdBy: UUID, createdAt: Date = Date(), imageURL: String? = nil, tags: [String] = [], membershipStatus: MembershipStatus? = nil, isUserMember: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.memberCount = memberCount
        self.maxMembers = maxMembers
        self.isPrivate = isPrivate
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.imageURL = imageURL
        self.tags = tags
        self.membershipStatus = membershipStatus
        self.isUserMember = isUserMember
    }
    
    public enum MembershipStatus: String, Codable {
        case member = "member"
        case pending = "pending"
        case invited = "invited"
        case banned = "banned"
    }
}

// MARK: - String Category Extensions
extension String {
    var gradient: LinearGradient {
        switch self.lowercased() {
        case "programming", "tech", "coding":
            return LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "design", "art", "creative":
            return LinearGradient(colors: [.pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "science", "research":
            return LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "business", "management":
            return LinearGradient(colors: [.indigo, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "language", "communication":
            return LinearGradient(colors: [.mint, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [.gray, .secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    var icon: String {
        switch self.lowercased() {
        case "programming", "tech", "coding":
            return "laptopcomputer"
        case "design", "art", "creative":
            return "paintbrush"
        case "science", "research":
            return "flask"
        case "business", "management":
            return "briefcase"
        case "language", "communication":
            return "bubble.left.and.bubble.right"
        default:
            return "folder"
        }
    }
}

public struct LearningStory: Codable, Identifiable {
    public let id: UUID
    let userId: UUID
    let username: String
    let userAvatar: String?
    let mediaURL: String
    let mediaType: MediaType
    let duration: TimeInterval?
    let caption: String?
    let createdAt: Date
    let viewsCount: Int
    let isViewed: Bool
    
    // Computed properties
    public var colorGradient: LinearGradient {
        let colors = [Color.blue, Color.purple, Color.green, Color.orange, Color.red, Color.pink]
        let index = abs(id.hashValue) % colors.count
        return LinearGradient(
            gradient: Gradient(colors: [colors[index], colors[(index + 1) % colors.count]]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// Note: Using LearningStory directly since Story struct exists in AppModels.swift

public struct Conversation: Codable, Identifiable {
    public let id: UUID
    let participantIds: [UUID]
    let lastMessage: Message?
    let lastActivity: Date
    let unreadCount: Int
    let isGroup: Bool
    let title: String?
    let avatar: String?
    
    // Computed properties
    public var hasUnreadMessages: Bool {
        return unreadCount > 0
    }
    
    public var initials: String {
        if let title = title, !title.isEmpty {
            let words = title.split(separator: " ")
            return String(words.prefix(2).compactMap { $0.first }).uppercased()
        }
        return "?"
    }
    
    public var colorGradient: LinearGradient {
        let colors = [Color.blue, Color.purple, Color.green, Color.orange, Color.red]
        let index = abs(id.hashValue) % colors.count
        return LinearGradient(
            gradient: Gradient(colors: [colors[index], colors[(index + 1) % colors.count]]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

public struct Message: Codable, Identifiable {
    public let id: UUID
    let conversationId: UUID
    let senderId: UUID
    let content: String
    let messageType: MessageType
    let sentAt: Date
    let readAt: Date?
    let mediaURL: String?
    
    public enum MessageType: String, Codable {
        case text = "text"
        case image = "image"
        case video = "video"
        case file = "file"
        case voice = "voice"
    }
}

public struct AvatarUploadResponse: Codable {
    let avatarURL: String
    let message: String
}

// MARK: - Additional Types for Compilation

// Network Connection Type
public enum NetworkConnectionType: String, Codable, CaseIterable {
    case wifi = "wifi"
    case cellular = "cellular"
    case ethernet = "ethernet"
    case none = "none"
}

// Auth Error Types
// Service Protocols
public protocol EnhancedAPIService {
    func request<T: Codable>(_ endpoint: APIEndpoint, responseType: T.Type) async throws -> T
}

public protocol CoreDataManager: AnyObject {
    func save() throws
}

// Basic implementation for CoreDataManager
public class BasicCoreDataManager: CoreDataManager {
    public static let shared = BasicCoreDataManager()
    
    private init() {}
    
    public func save() throws {
        // Basic implementation - would need actual Core Data context
        print("Core Data save called")
    }
    
    public func startBackgroundSync() async {
        // Start background synchronization
        print("Background sync started")
        // Implementation would include actual Core Data sync logic
    }
    
    public func syncPendingChanges() async {
        print("Syncing pending changes")
        // Implementation would sync any pending Core Data changes
    }
    
    // Cache methods
    public func cacheCommunityEvents(_ events: [CommunityEvent]) {
        print("Cached \(events.count) community events")
    }
    
    public func cacheStudyGroups(_ groups: [StudyGroup]) {
        print("Cached \(groups.count) study groups")
    }
    
    public func cacheLeaderboard(_ leaderboard: [LeaderboardUser]) {
        print("Cached \(leaderboard.count) leaderboard entries")
    }
    
    public func fetchCachedCommunityEvents() -> [CommunityEvent]? {
        return []
    }
    
    public func fetchCachedStudyGroups() -> [StudyGroup]? {
        return []
    }
    
    public func fetchCachedLeaderboard() -> [LeaderboardUser]? {
        return []
    }
    
    public func fetchCachedUserStats() -> UserStats? {
        return nil
    }
}

// Keychain Helper
public final class KeychainHelper {
    public static let shared = KeychainHelper()
    
    private init() {}
    
    private let service = Bundle.main.bundleIdentifier ?? "com.lyo.app"
    
    // MARK: - Save
    @discardableResult
    public func save(_ data: String, for key: String) -> Bool {
        guard let data = data.data(using: .utf8) else { return false }
        return save(data, for: key)
    }
    
    @discardableResult
    public func save(_ data: Data, for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Retrieve
    public func retrieve(for key: String) -> String? {
        guard let data = retrieveData(for: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    public func retrieveData(for key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        return status == errSecSuccess ? (dataTypeRef as? Data) : nil
    }
    
    // MARK: - Delete
    @discardableResult
    public func delete(for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    // MARK: - Clear All
    @discardableResult
    public func clearAll() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
}

// MARK: - Course Type Alias
// Course model is available from AppModels.swift

// MARK: - API Response Models
// Models needed by API services that don't exist elsewhere

public struct UserProgress: Codable {
    public let totalCoursesEnrolled: Int
    public let totalCoursesCompleted: Int
    public let totalLessonsCompleted: Int
    public let totalTimeSpent: TimeInterval
    public let streakDays: Int
    public let level: Int
    public let xp: Int
    public let recentAchievements: [Achievement]
    public let completedCourses: Int
    public let totalHours: TimeInterval
    public let currentStreak: Int
    public let inProgressCourses: Int
    public let totalLearningHours: Int
    
    public init(totalCoursesEnrolled: Int, totalCoursesCompleted: Int, totalLessonsCompleted: Int, totalTimeSpent: TimeInterval, streakDays: Int, level: Int, xp: Int, recentAchievements: [Achievement] = [], completedCourses: Int = 0, totalHours: TimeInterval = 0, currentStreak: Int = 0, inProgressCourses: Int = 0, totalLearningHours: Int = 0) {
        self.totalCoursesEnrolled = totalCoursesEnrolled
        self.totalCoursesCompleted = totalCoursesCompleted
        self.totalLessonsCompleted = totalLessonsCompleted
        self.totalTimeSpent = totalTimeSpent
        self.streakDays = streakDays
        self.level = level
        self.xp = xp
        self.recentAchievements = recentAchievements
        self.completedCourses = completedCourses
        self.totalHours = totalHours
        self.currentStreak = currentStreak
        self.inProgressCourses = inProgressCourses
        self.totalLearningHours = totalLearningHours
    }
}

public struct EnrollmentResponse: Codable {
    public let success: Bool
    public let enrollmentId: String
    public let message: String
    
    public init(success: Bool, enrollmentId: String, message: String) {
        self.success = success
        self.enrollmentId = enrollmentId
        self.message = message
    }
}

