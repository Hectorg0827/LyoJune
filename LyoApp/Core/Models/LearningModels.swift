import Foundation
import Security

// MARK: - Learning Models defined here that work with AppModels.swift types
// Course is defined in AppModels.swift and can be used directly

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
    let category: String
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
    let category: String
    let memberCount: Int
    let maxMembers: Int
    let isPrivate: Bool
    let createdBy: UUID
    let createdAt: Date
    let imageURL: String?
    let tags: [String]
    let membershipStatus: MembershipStatus?
    
    public enum MembershipStatus: String, Codable {
        case member = "member"
        case pending = "pending"
        case invited = "invited"
        case banned = "banned"
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
}

public struct Conversation: Codable, Identifiable {
    public let id: UUID
    let participantIds: [UUID]
    let lastMessage: Message?
    let lastActivity: Date
    let unreadCount: Int
    let isGroup: Bool
    let title: String?
    let avatar: String?
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
    
    public init(totalCoursesEnrolled: Int, totalCoursesCompleted: Int, totalLessonsCompleted: Int, totalTimeSpent: TimeInterval, streakDays: Int, level: Int, xp: Int) {
        self.totalCoursesEnrolled = totalCoursesEnrolled
        self.totalCoursesCompleted = totalCoursesCompleted
        self.totalLessonsCompleted = totalLessonsCompleted
        self.totalTimeSpent = totalTimeSpent
        self.streakDays = streakDays
        self.level = level
        self.xp = xp
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

