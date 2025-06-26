import Foundation
import Combine

/// Enhanced API Service for Phase 3 with real backend integration
class EnhancedAPIService {
    
    private let networkManager = EnhancedNetworkManager.shared
    private let webSocketManager = WebSocketManager.shared
    
    init() {
        setupRealtimeSubscriptions()
    }
    
    // MARK: - Real-time Subscriptions
    
    private func setupRealtimeSubscriptions() {
        // Subscribe to WebSocket updates
        webSocketManager.subscribeToLearningProgress()
        webSocketManager.subscribeToFeedUpdates()
    }
    
    // MARK: - Learning API Methods
    
    func getCourses(
        page: Int = 1,
        limit: Int = 20,
        category: String? = nil,
        searchQuery: String? = nil
    ) -> Future<CoursesResponse, NetworkError> {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        
        if let searchQuery = searchQuery {
            queryItems.append(URLQueryItem(name: "search", value: searchQuery))
        }
        
        let endpoint = APIEndpoint(path: "/courses", queryItems: queryItems)
        let request = networkManager.buildRequest(for: endpoint)
        
        return networkManager.performRequest(request, responseType: CoursesResponse.self)
    }
    
    func getCourseDetails(_ courseId: String) -> Future<CourseDetail, NetworkError> {
        let endpoint = APIEndpoint(path: "/courses/\(courseId)")
        let request = networkManager.buildRequest(for: endpoint)
        
        return networkManager.performRequest(request, responseType: CourseDetail.self)
    }
    
    func enrollInCourse(_ courseId: String) -> Future<EnrollmentResponse, NetworkError> {
        let endpoint = APIEndpoint(path: "/courses/\(courseId)/enroll")
        let request = networkManager.buildRequest(for: endpoint, method: .POST)
        
        return networkManager.performRequest(request, responseType: EnrollmentResponse.self)
    }
    
    func updateLearningProgress(
        courseId: String,
        lessonId: String,
        progress: LearningProgressUpdate
    ) -> Future<ProgressResponse, NetworkError> {
        let endpoint = APIEndpoint(path: "/courses/\(courseId)/lessons/\(lessonId)/progress")
        
        guard let progressData = try? JSONEncoder().encode(progress) else {
            return Future { promise in
                promise(.failure(.invalidResponse))
            }
        }
        
        let request = networkManager.buildRequest(
            for: endpoint,
            method: .PUT,
            body: progressData
        )
        
        return networkManager.performRequest(request, responseType: ProgressResponse.self)
    }
    
    func getLearningPaths() -> Future<LearningPathsResponse, NetworkError> {
        let endpoint = APIEndpoint(path: "/learning-paths")
        let request = networkManager.buildRequest(for: endpoint)
        
        return networkManager.performRequest(request, responseType: LearningPathsResponse.self)
    }
    
    func getUserProgress() -> Future<UserProgressResponse, NetworkError> {
        let endpoint = APIEndpoint(path: "/user/progress")
        let request = networkManager.buildRequest(for: endpoint)
        
        return networkManager.performRequest(request, responseType: UserProgressResponse.self)
    }
    
    // MARK: - Feed API Methods
    
    func getFeed(
        page: Int = 1,
        limit: Int = 20,
        type: FeedType = .all
    ) -> Future<FeedResponse, NetworkError> {
        let queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "type", value: type.rawValue)
        ]
        
        let endpoint = APIEndpoint(path: "/feed", queryItems: queryItems)
        let request = networkManager.buildRequest(for: endpoint)
        
        return networkManager.performRequest(request, responseType: FeedResponse.self)
    }
    
    func createPost(_ post: CreatePostRequest) -> Future<PostResponse, NetworkError> {
        let endpoint = APIEndpoint(path: "/posts")
        
        guard let postData = try? JSONEncoder().encode(post) else {
            return Future { promise in
                promise(.failure(.invalidResponse))
            }
        }
        
        let request = networkManager.buildRequest(
            for: endpoint,
            method: .POST,
            body: postData
        )
        
        return networkManager.performRequest(request, responseType: PostResponse.self)
    }
    
    func likePost(_ postId: String) -> Future<LikeResponse, NetworkError> {
        let endpoint = APIEndpoint(path: "/posts/\(postId)/like")
        let request = networkManager.buildRequest(for: endpoint, method: .POST)
        
        return networkManager.performRequest(request, responseType: LikeResponse.self)
    }
    
    func unlikePost(_ postId: String) -> Future<LikeResponse, NetworkError> {
        let endpoint = APIEndpoint(path: "/posts/\(postId)/like")
        let request = networkManager.buildRequest(for: endpoint, method: .DELETE)
        
        return networkManager.performRequest(request, responseType: LikeResponse.self)
    }
    
    func commentOnPost(_ postId: String, comment: String) -> Future<CommentResponse, NetworkError> {
        let commentRequest = CommentRequest(content: comment)
        
        guard let commentData = try? JSONEncoder().encode(commentRequest) else {
            return Future { promise in
                promise(.failure(.invalidResponse))
            }
        }
        
        let endpoint = APIEndpoint(path: "/posts/\(postId)/comments")
        let request = networkManager.buildRequest(
            for: endpoint,
            method: .POST,
            body: commentData
        )
        
        return networkManager.performRequest(request, responseType: CommentResponse.self)
    }
    
    // MARK: - User API Methods
    
    func getUserProfile(_ userId: String? = nil) -> Future<UserProfile, NetworkError> {
        let path = userId != nil ? "/users/\(userId!)" : "/user/profile"
        let endpoint = APIEndpoint(path: path)
        let request = networkManager.buildRequest(for: endpoint)
        
        return networkManager.performRequest(request, responseType: UserProfile.self)
    }
    
    func updateUserProfile(_ updates: UserProfileUpdate) -> Future<UserProfile, NetworkError> {
        let endpoint = APIEndpoint(path: "/user/profile")
        
        guard let updateData = try? JSONEncoder().encode(updates) else {
            return Future { promise in
                promise(.failure(.invalidResponse))
            }
        }
        
        let request = networkManager.buildRequest(
            for: endpoint,
            method: .PUT,
            body: updateData
        )
        
        return networkManager.performRequest(request, responseType: UserProfile.self)
    }
    
    func uploadProfileImage(_ imageData: Data) -> Future<ImageUploadResponse, NetworkError> {
        let endpoint = APIEndpoint(path: "/user/profile/avatar")
        
        return networkManager.uploadFile(
            to: endpoint,
            fileData: imageData,
            fileName: "avatar.jpg",
            mimeType: "image/jpeg"
        ).map { uploadResponse in
            ImageUploadResponse(url: uploadResponse.url)
        }.eraseToAnyPublisher()
        .setFailureType(to: NetworkError.self)
        .eraseToFuture()
    }
    
    // MARK: - Search API Methods
    
    func search(
        query: String,
        type: SearchType = .all,
        page: Int = 1,
        limit: Int = 20
    ) -> Future<SearchResponse, NetworkError> {
        let queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: type.rawValue),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        let endpoint = APIEndpoint(path: "/search", queryItems: queryItems)
        let request = networkManager.buildRequest(for: endpoint)
        
        return networkManager.performRequest(request, responseType: SearchResponse.self)
    }
    
    func getSearchSuggestions(query: String) -> Future<SearchSuggestionsResponse, NetworkError> {
        let queryItems = [URLQueryItem(name: "q", value: query)]
        let endpoint = APIEndpoint(path: "/search/suggestions", queryItems: queryItems)
        let request = networkManager.buildRequest(for: endpoint)
        
        return networkManager.performRequest(request, responseType: SearchSuggestionsResponse.self)
    }
    
    // MARK: - Analytics API Methods
    
    func trackEvent(_ event: AnalyticsEvent) -> Future<AnalyticsResponse, NetworkError> {
        let endpoint = APIEndpoint(path: "/analytics/events")
        
        guard let eventData = try? JSONEncoder().encode(event) else {
            return Future { promise in
                promise(.failure(.invalidResponse))
            }
        }
        
        let request = networkManager.buildRequest(
            for: endpoint,
            method: .POST,
            body: eventData
        )
        
        return networkManager.performRequest(request, responseType: AnalyticsResponse.self)
    }
    
    // MARK: - Notifications API Methods
    
    func getNotifications(
        page: Int = 1,
        limit: Int = 20,
        unreadOnly: Bool = false
    ) -> Future<NotificationsResponse, NetworkError> {
        let queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "unread_only", value: String(unreadOnly))
        ]
        
        let endpoint = APIEndpoint(path: "/notifications", queryItems: queryItems)
        let request = networkManager.buildRequest(for: endpoint)
        
        return networkManager.performRequest(request, responseType: NotificationsResponse.self)
    }
    
    func markNotificationAsRead(_ notificationId: String) -> Future<NotificationResponse, NetworkError> {
        let endpoint = APIEndpoint(path: "/notifications/\(notificationId)/read")
        let request = networkManager.buildRequest(for: endpoint, method: .PUT)
        
        return networkManager.performRequest(request, responseType: NotificationResponse.self)
    }
    
    func updateNotificationSettings(_ settings: NotificationSettings) -> Future<NotificationSettingsResponse, NetworkError> {
        let endpoint = APIEndpoint(path: "/user/notification-settings")
        
        guard let settingsData = try? JSONEncoder().encode(settings) else {
            return Future { promise in
                promise(.failure(.invalidResponse))
            }
        }
        
        let request = networkManager.buildRequest(
            for: endpoint,
            method: .PUT,
            body: settingsData
        )
        
        return networkManager.performRequest(request, responseType: NotificationSettingsResponse.self)
    }
}

// MARK: - Supporting Types

// MARK: - API Endpoint Extension
extension APIEndpoint {
    init(path: String, queryItems: [URLQueryItem] = []) {
        self.path = path
        if !queryItems.isEmpty {
            var urlComponents = URLComponents()
            urlComponents.queryItems = queryItems
            if let queryString = urlComponents.percentEncodedQuery {
                self.path += "?" + queryString
            }
        }
    }
}

// MARK: - Request Types
struct CreatePostRequest: Codable {
    let content: String
    let mediaUrls: [String]?
    let courseId: String?
    let tags: [String]?
}

struct CommentRequest: Codable {
    let content: String
}

struct LearningProgressUpdate: Codable {
    let percentage: Double
    let timeSpent: TimeInterval
    let completed: Bool
    let answers: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case percentage, timeSpent, completed, answers
    }
    
    init(percentage: Double, timeSpent: TimeInterval, completed: Bool, answers: [String: Any]? = nil) {
        self.percentage = percentage
        self.timeSpent = timeSpent
        self.completed = completed
        self.answers = answers
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        percentage = try container.decode(Double.self, forKey: .percentage)
        timeSpent = try container.decode(TimeInterval.self, forKey: .timeSpent)
        completed = try container.decode(Bool.self, forKey: .completed)
        
        // Handle answers as flexible JSON
        if container.contains(.answers) {
            answers = try container.decode([String: AnyCodable].self, forKey: .answers).mapValues { $0.value }
        } else {
            answers = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(percentage, forKey: .percentage)
        try container.encode(timeSpent, forKey: .timeSpent)
        try container.encode(completed, forKey: .completed)
        
        if let answers = answers {
            let encodableAnswers = answers.mapValues { AnyCodable($0) }
            try container.encode(encodableAnswers, forKey: .answers)
        }
    }
}

struct UserProfileUpdate: Codable {
    let fullName: String?
    let bio: String?
    let location: String?
    let website: String?
    let learningGoals: [String]?
    let interests: [String]?
}

// Note: AnalyticsEvent is now defined in Core/Models/AppModels.swift

struct NotificationSettings: Codable {
    let pushEnabled: Bool
    let emailEnabled: Bool
    let learningReminders: Bool
    let socialUpdates: Bool
    let courseUpdates: Bool
    let achievementNotifications: Bool
}

// MARK: - Response Types
struct CoursesResponse: Codable {
    let courses: [CourseModel]
    let pagination: PaginationInfo
    let totalCount: Int
}

struct CourseDetail: Codable {
    let course: CourseModel
    let lessons: [LessonModel]
    let instructor: UserProfile
    let enrollment: EnrollmentInfo?
    let userProgress: LessonProgress?
}

struct EnrollmentResponse: Codable {
    let enrollment: EnrollmentInfo
    let course: CourseModel
}

struct ProgressResponse: Codable {
    let progress: LessonProgress
    let nextLesson: LessonModel?
    let achievements: [Achievement]?
}

struct LearningPathsResponse: Codable {
    let paths: [LearningPath]
    let recommendations: [LearningPath]
}

struct UserProgressResponse: Codable {
    let overallProgress: UserProgress
    let recentCourses: [CourseProgress]
    let achievements: [Achievement]
    let streaks: StreakInfo
}

struct FeedResponse: Codable {
    let posts: [FeedPost]
    let pagination: PaginationInfo
    let hasMore: Bool
}

struct PostResponse: Codable {
    let post: FeedPost
}

struct LikeResponse: Codable {
    let isLiked: Bool
    let totalLikes: Int
}

struct CommentResponse: Codable {
    let comment: Comment
    let totalComments: Int
}

struct UserProfile: Codable {
    let id: String
    let email: String
    let fullName: String
    let username: String?
    let avatarUrl: String?
    let bio: String?
    let location: String?
    let website: String?
    let createdAt: Date
    let stats: UserStats
    let learningGoals: [String]
    let interests: [String]
    let badges: [Badge]
}

struct ImageUploadResponse: Codable {
    let url: String
}

struct SearchResponse: Codable {
    let results: SearchResults
    let pagination: PaginationInfo
    let totalCount: Int
    let suggestions: [String]
}

struct SearchResults: Codable {
    let courses: [CourseModel]
    let users: [UserProfile]
    let posts: [FeedPost]
    let paths: [LearningPath]
}

struct SearchSuggestionsResponse: Codable {
    let suggestions: [String]
    let trending: [String]
    let recent: [String]
}

struct AnalyticsResponse: Codable {
    let success: Bool
    let eventId: String
}

struct NotificationsResponse: Codable {
    let notifications: [NotificationModel]
    let pagination: PaginationInfo
    let unreadCount: Int
}

struct NotificationResponse: Codable {
    let notification: NotificationModel
}

struct NotificationSettingsResponse: Codable {
    let settings: NotificationSettings
}

// MARK: - Enum Types
enum FeedType: String, Codable {
    case all = "all"
    case following = "following"
    case trending = "trending"
    case recent = "recent"
}

enum SearchType: String, Codable {
    case all = "all"
    case courses = "courses"
    case users = "users"
    case posts = "posts"
    case paths = "paths"
}

// MARK: - Helper Types
struct PaginationInfo: Codable {
    let currentPage: Int
    let totalPages: Int
    let pageSize: Int
    let hasNext: Bool
    let hasPrevious: Bool
}

struct EnrollmentInfo: Codable {
    let id: String
    let courseId: String
    let userId: String
    let enrolledAt: Date
    let completedAt: Date?
    let progress: Double
    let currentLesson: String?
}

struct LessonProgress: Codable {
    let lessonId: String
    let percentage: Double
    let timeSpent: TimeInterval
    let completed: Bool
    let lastAccessed: Date
}

struct CourseProgress: Codable {
    let course: CourseModel
    let progress: Double
    let lastAccessed: Date
    let timeSpent: TimeInterval
}

struct StreakInfo: Codable {
    let current: Int
    let longest: Int
    let lastActivity: Date
}

struct UserStats: Codable {
    let coursesCompleted: Int
    let totalLearningTime: TimeInterval
    let certificatesEarned: Int
    let socialConnections: Int
    let postsCreated: Int
    let commentsPosted: Int
}

struct Badge: Codable {
    let id: String
    let name: String
    let description: String
    let iconUrl: String
    let earnedAt: Date
    let rarity: BadgeRarity
}

enum BadgeRarity: String, Codable {
    case common = "common"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
}

struct NotificationModel: Codable {
    let id: String
    let type: NotificationType
    let title: String
    let message: String
    let isRead: Bool
    let createdAt: Date
    let actionUrl: String?
    let metadata: [String: AnyCodable]?
}

enum NotificationType: String, Codable {
    case courseUpdate = "course_update"
    case achievement = "achievement"
    case social = "social"
    case system = "system"
    case reminder = "reminder"
}

// Note: AnyCodable is now defined in Core/Utilities/AnyCodable.swift

// MARK: - Publisher Extension
extension Publisher {
    func eraseToFuture() -> Future<Output, Failure> {
        return Future<Output, Failure> { promise in
            var cancellable: AnyCancellable?
            cancellable = self.sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        promise(.failure(error))
                    }
                    cancellable?.cancel()
                },
                receiveValue: { value in
                    promise(.success(value))
                    cancellable?.cancel()
                }
            )
        }
    }
}
