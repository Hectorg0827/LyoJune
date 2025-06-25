import Foundation
import Combine

// MARK: - Course API Service
@MainActor
class CourseAPIService: ObservableObject {
    static let shared = CourseAPIService()
    
    private init() {}
    
    func getCourses() async throws -> [LearningCourse] {
        return try await NetworkManager.shared.get(endpoint: Constants.API.Endpoints.courses)
    }
    
    func getCourse(id: String) async throws -> LearningCourse {
        return try await NetworkManager.shared.get(endpoint: "\(Constants.API.Endpoints.courses)/\(id)")
    }
    
    func enrollInCourse(courseId: String) async throws -> EnrollmentResponse {
        let request = EnrollmentRequest(courseId: courseId)
        return try await NetworkManager.shared.post(
            endpoint: "\(Constants.API.Endpoints.courses)/\(courseId)/enroll",
            body: request
        )
    }
    
    func updateProgress(courseId: String, lessonId: String, progress: Double) async throws -> ProgressResponse {
        let request = ProgressUpdateRequest(
            courseId: courseId,
            lessonId: lessonId,
            progress: progress,
            completedAt: progress >= 1.0 ? Date() : nil
        )
        return try await NetworkManager.shared.post(
            endpoint: "\(Constants.API.Endpoints.courses)/\(courseId)/progress",
            body: request
        )
    }
    
    func completeCourse(courseId: String) async throws -> CompletionResponse {
        let request = CourseCompletionRequest(courseId: courseId, completedAt: Date())
        return try await NetworkManager.shared.post(
            endpoint: "\(Constants.API.Endpoints.courses)/\(courseId)/complete",
            body: request
        )
    }
    
    func searchCourses(query: String, category: String? = nil) async throws -> [LearningCourse] {
        var endpoint = "\(Constants.API.Endpoints.courses)/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let category = category {
            endpoint += "&category=\(category)"
        }
        return try await NetworkManager.shared.get(endpoint: endpoint)
    }
    
    func getUserCourses() async throws -> [UserCourse] {
        return try await NetworkManager.shared.get(endpoint: "\(Constants.API.Endpoints.courses)/user")
    }
}

// MARK: - Post API Service
@MainActor
class PostAPIService: ObservableObject {
    static let shared = PostAPIService()
    
    private init() {}
    
    func getFeed(page: Int = 1, limit: Int = 20) async throws -> FeedResponse {
        return try await NetworkManager.shared.get(
            endpoint: "\(Constants.API.Endpoints.posts)/feed?page=\(page)&limit=\(limit)"
        )
    }
    
    func getPost(id: String) async throws -> Post {
        return try await NetworkManager.shared.get(endpoint: "\(Constants.API.Endpoints.posts)/\(id)")
    }
    
    func createPost(content: String, mediaUrls: [String] = [], courseId: String? = nil) async throws -> Post {
        let request = CreatePostRequest(
            content: content,
            mediaUrls: mediaUrls,
            courseId: courseId
        )
        return try await NetworkManager.shared.post(endpoint: Constants.API.Endpoints.posts, body: request)
    }
    
    func likePost(postId: String) async throws -> LikeResponse {
        return try await NetworkManager.shared.post(
            endpoint: "\(Constants.API.Endpoints.posts)/\(postId)/like",
            body: EmptyRequest()
        )
    }
    
    func unlikePost(postId: String) async throws -> LikeResponse {
        return try await NetworkManager.shared.delete(
            endpoint: "\(Constants.API.Endpoints.posts)/\(postId)/like"
        )
    }
    
    func addComment(postId: String, content: String) async throws -> Comment {
        let request = CreateCommentRequest(content: content)
        return try await NetworkManager.shared.post(
            endpoint: "\(Constants.API.Endpoints.posts)/\(postId)/comments",
            body: request
        )
    }
    
    func getComments(postId: String, page: Int = 1) async throws -> CommentsResponse {
        return try await NetworkManager.shared.get(
            endpoint: "\(Constants.API.Endpoints.posts)/\(postId)/comments?page=\(page)"
        )
    }
    
    func sharePost(postId: String, message: String? = nil) async throws -> ShareResponse {
        let request = SharePostRequest(postId: postId, message: message)
        return try await NetworkManager.shared.post(
            endpoint: "\(Constants.API.Endpoints.posts)/\(postId)/share",
            body: request
        )
    }
    
    func reportPost(postId: String, reason: String) async throws -> ReportResponse {
        let request = ReportPostRequest(reason: reason)
        return try await NetworkManager.shared.post(
            endpoint: "\(Constants.API.Endpoints.posts)/\(postId)/report",
            body: request
        )
    }
    
    func uploadMedia(data: Data, type: MediaType) async throws -> MediaUploadResponse {
        let fileName = "media.\(type.fileExtension)"
        return try await NetworkManager.shared.uploadFile(
            endpoint: "\(Constants.API.Endpoints.posts)/media",
            fileData: data,
            fileName: fileName,
            mimeType: type.mimeType
        )
    }
}

// MARK: - Video API Service
@MainActor
class VideoAPIService: ObservableObject {
    static let shared = VideoAPIService()
    
    private init() {}
    
    func getVideoDetails(id: String) async throws -> Video {
        return try await NetworkManager.shared.get(endpoint: "\(Constants.API.Endpoints.videos)/\(id)")
    }
    
    func updateWatchProgress(videoId: String, progress: Double, currentTime: Double) async throws -> WatchProgressResponse {
        let request = UpdateWatchProgressRequest(
            videoId: videoId,
            progress: progress,
            currentTime: currentTime,
            watchedAt: Date()
        )
        return try await NetworkManager.shared.post(
            endpoint: "\(Constants.API.Endpoints.videos)/\(videoId)/progress",
            body: request
        )
    }
    
    func getVideoTranscript(videoId: String) async throws -> VideoTranscript {
        return try await NetworkManager.shared.get(
            endpoint: "\(Constants.API.Endpoints.videos)/\(videoId)/transcript"
        )
    }
    
    func addVideoNote(videoId: String, content: String, timestamp: Double) async throws -> VideoNote {
        let request = CreateVideoNoteRequest(
            content: content,
            timestamp: timestamp
        )
        return try await NetworkManager.shared.post(
            endpoint: "\(Constants.API.Endpoints.videos)/\(videoId)/notes",
            body: request
        )
    }
    
    func getVideoNotes(videoId: String) async throws -> [VideoNote] {
        return try await NetworkManager.shared.get(
            endpoint: "\(Constants.API.Endpoints.videos)/\(videoId)/notes"
        )
    }
}

// MARK: - Analytics API Service
@MainActor
class AnalyticsAPIService: ObservableObject {
    static let shared = AnalyticsAPIService()
    
    private init() {}
    
    func trackEvent(_ event: String, parameters: [String: Any] = [:]) async {
        guard Constants.FeatureFlags.enableAnalytics else { return }
        
        let request = AnalyticsEventRequest(
            event: event,
            parameters: parameters,
            timestamp: Date(),
            sessionId: getSessionId()
        )
        
        do {
            let _: EmptyResponse = try await NetworkManager.shared.post(
                endpoint: Constants.API.Endpoints.analytics,
                body: request
            )
        } catch {
            // Silently fail analytics - don't interrupt user experience
            print("Analytics tracking failed: \(error)")
        }
    }
    
    func trackEvent(_ event: AnalyticsEvent) async throws {
        guard Constants.FeatureFlags.enableAnalytics else { return }
        
        let _: EmptyResponse = try await NetworkManager.shared.post(
            endpoint: "\(Constants.API.Endpoints.analytics)/events",
            body: event
        )
    }
    
    func getUserAnalytics() async throws -> UserAnalytics {
        return try await NetworkManager.shared.get(endpoint: "\(Constants.API.Endpoints.analytics)/user")
    }
    
    func getEngagementMetrics() async throws -> EngagementMetrics {
        return try await NetworkManager.shared.get(endpoint: "\(Constants.API.Endpoints.analytics)/engagement")
    }
    
    private func getSessionId() -> String {
        // Generate or retrieve session ID
        if let sessionId = UserDefaults.standard.string(forKey: "currentSessionId") {
            return sessionId
        } else {
            let sessionId = UUID().uuidString
            UserDefaults.standard.set(sessionId, forKey: "currentSessionId")
            return sessionId
        }
    }
}

// MARK: - Request/Response Models
struct EnrollmentRequest: Codable {
    let courseId: String
}

struct EnrollmentResponse: Codable {
    let success: Bool
    let enrollmentDate: Date
}

struct ProgressUpdateRequest: Codable {
    let courseId: String
    let lessonId: String
    let progress: Double
    let completedAt: Date?
}

struct ProgressResponse: Codable {
    let success: Bool
    let totalProgress: Double
}

struct CourseCompletionRequest: Codable {
    let courseId: String
    let completedAt: Date
}

struct CompletionResponse: Codable {
    let success: Bool
    let certificateUrl: String?
    let points: Int
}

// Duplicate request/response models moved to LearningAPIService.swift
// MediaType moved to PostModels.swift

struct MediaUploadResponse: Codable {
    let url: String
    let id: String
}

struct FeedResponse: Codable {
    let posts: [Post]
    let pagination: PaginationInfo
}

struct CommentsResponse: Codable {
    let comments: [Comment]
    let pagination: PaginationInfo
}

struct PaginationInfo: Codable {
    let currentPage: Int
    let totalPages: Int
    let hasNextPage: Bool
    let totalCount: Int
}

struct LikeResponse: Codable {
    let liked: Bool
    let likeCount: Int
}

struct ShareResponse: Codable {
    let shared: Bool
    let shareCount: Int
}

struct ReportResponse: Codable {
    let reported: Bool
    let message: String
}

struct JoinGroupResponse: Codable {
    let success: Bool
    let memberCount: Int
}

struct JoinEventResponse: Codable {
    let success: Bool
    let attendeeCount: Int
}

struct LeaderboardResponse: Codable {
    let users: [LeaderboardUser]
    let currentUser: LeaderboardUser?
    let totalUsers: Int
    let timeframe: String
}

struct LeaderboardUser: Codable, Identifiable {
    let id: String
    let username: String
    let avatar: String?
    let points: Int
    let rank: Int
}

struct UpdateWatchProgressRequest: Codable {
    let videoId: String
    let progress: Double
    let currentTime: Double
    let watchedAt: Date
}

struct WatchProgressResponse: Codable {
    let success: Bool
    let totalWatchTime: Double
}

struct CreateVideoNoteRequest: Codable {
    let content: String
    let timestamp: Double
}

struct AnalyticsEventRequest: Codable {
    let event: String
    let parameters: [String: AnyCodable]
    let timestamp: Date
    let sessionId: String
}

struct UserAnalytics: Codable {
    let totalStudyTime: Double
    let coursesCompleted: Int
    let videosWatched: Int
    let postsCreated: Int
    let achievementsEarned: Int
    let currentStreak: Int
    let longestStreak: Int
    let totalSessions: Int
    let averageSessionLength: TimeInterval
    let lastActiveDate: Date
}

struct AnalyticsEvent: Codable {
    let eventName: String
    let properties: [String: String]
    let timestamp: Date
    let userId: String?
}

struct EngagementMetrics: Codable {
    let dailyActiveUsers: Int
    let weeklyActiveUsers: Int
    let monthlyActiveUsers: Int
    let averageSessionDuration: TimeInterval
    let retentionRate: Double
    let engagementScore: Double
}

// Helper for encoding any type
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else {
            value = try container.decode([String: AnyCodable].self)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let dict as [String: Any]:
            let codableDict = dict.mapValues { AnyCodable($0) }
            try container.encode(codableDict)
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Invalid type"))
        }
    }
}
