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

public struct Comment: Codable {
    let id: UUID
    let postId: UUID
    let userId: UUID
    let content: String
    let createdAt: Date
    let likesCount: Int
    let isLiked: Bool
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

public struct Story: Codable, Identifiable {
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
    
    public enum MediaType: String, Codable {
        case image = "image"
        case video = "video"
    }
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

public struct UserProfile: Codable, Identifiable {
    public let id: UUID
    let username: String
    let displayName: String
    let bio: String?
    let avatar: String?
    let level: Int
    let xp: Int
    let joinedAt: Date
    let coursesCompleted: Int
    let badgesEarned: Int
    let followersCount: Int
    let followingCount: Int
    let isFollowing: Bool?
}

public struct AvatarUploadResponse: Codable {
    let avatarURL: String
    let message: String
}

// MARK: - Additional Types for Compilation

// HTTP Method
public enum HTTPMethod: String, CaseIterable {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// API Endpoint
public struct APIEndpoint {
    public let path: String
    public let method: HTTPMethod
    public let headers: [String: String]
    public let queryParameters: [String: String]
    public let queryItems: [URLQueryItem]?
    public let body: Data?
    
    public init(
        path: String, 
        method: HTTPMethod = .GET, 
        headers: [String: String] = [:], 
        queryParameters: [String: String] = [:],
        queryItems: [URLQueryItem]? = nil,
        body: Data? = nil
    ) {
        self.path = path
        self.method = method
        self.headers = headers
        self.queryParameters = queryParameters
        self.queryItems = queryItems
        self.body = body
    }
}

// Network Connection Type
public enum NetworkConnectionType: String, Codable, CaseIterable {
    case wifi = "wifi"
    case cellular = "cellular"
    case ethernet = "ethernet"
    case none = "none"
}

// Empty Response
public struct EmptyResponse: Codable {
    public init() {}
}

// Network Errors
public enum NetworkError: Error, LocalizedError {
    case noInternetConnection
    case requestTimeout
    case serverError(statusCode: Int)
    case invalidResponse
    case decodingError(String)
    case encodingError(String)
    case invalidURL
    case unauthorizedAccess
    case rateLimitExceeded
    case networkUnavailable
    case sslError
    case networkError(String)
    case timeout
    case unauthorized
    case forbidden
    case notFound
    case noData
    case custom(String)
    
    public var errorDescription: String? {
        switch self {
        case .noInternetConnection:
            return "No internet connection available"
        case .requestTimeout, .timeout:
            return "Request timed out"
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)"
        case .invalidResponse:
            return "Invalid response received"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .encodingError(let message):
            return "Failed to encode request: \(message)"
        case .invalidURL:
            return "Invalid URL"
        case .unauthorizedAccess, .unauthorized:
            return "Unauthorized access"
        case .forbidden:
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        case .noData:
            return "No data received from server"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .networkUnavailable:
            return "Network unavailable"
        case .sslError:
            return "SSL connection error"
        case .networkError(let message):
            return "Network error: \(message)"
        case .custom(let message):
            return message
        }
    }
}

// User Model (Basic)
public struct User: Codable, Identifiable, Hashable {
    public let id: String
    public let email: String
    public let firstName: String?
    public let lastName: String?
    public let username: String?
    public let profileImageURL: String?
    public let isVerified: Bool
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(
        id: String,
        email: String,
        firstName: String? = nil,
        lastName: String? = nil,
        username: String? = nil,
        profileImageURL: String? = nil,
        isVerified: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.username = username
        self.profileImageURL = profileImageURL
        self.isVerified = isVerified
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public var fullName: String {
        let components = [firstName, lastName].compactMap { $0 }
        return components.isEmpty ? (username ?? email) : components.joined(separator: " ")
    }
}

// Auth Error Types
public enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case networkError
    case serverError(String)
    case invalidToken
    case tokenInvalid
    case userNotFound
    case emailAlreadyExists
    case weakPassword
    case validationFailed(String)
    case biometricNotAvailable
    case biometricNotEnabled
    case biometricNotEnrolled
    case biometricAuthFailed
    case sessionExpired
    case twoFactorRequired
    case accountLocked
    case registrationFailed
    case loginFailed(String)
    case tokenRefreshFailed
    case noRefreshToken
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Network connection error"
        case .serverError(let message):
            return "Server error: \(message)"
        case .invalidToken, .tokenInvalid:
            return "Invalid authentication token"
        case .userNotFound:
            return "User not found"
        case .emailAlreadyExists:
            return "Email already exists"
        case .weakPassword:
            return "Password is too weak"
        case .validationFailed(let message):
            return "Authentication validation failed: \(message)"
        case .biometricNotAvailable:
            return "Biometric authentication is not available on this device"
        case .biometricNotEnabled:
            return "Biometric authentication is not enabled"
        case .biometricNotEnrolled:
            return "Biometric authentication is not enrolled"
        case .biometricAuthFailed:
            return "Biometric authentication failed"
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .twoFactorRequired:
            return "Two-factor authentication is required"
        case .accountLocked:
            return "Account is temporarily locked. Please try again later."
        case .registrationFailed:
            return "Account registration failed"
        case .loginFailed(let message):
            return "Login failed: \(message)"
        case .tokenRefreshFailed:
            return "Token refresh failed"
        case .noRefreshToken:
            return "No refresh token available"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

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

// Bundle extension for app version
extension Bundle {
    public var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    public var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
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

