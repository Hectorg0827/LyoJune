import Foundation

// MARK: - Notification Extensions for Real-time Updates
extension Notification.Name {
    // Network connectivity
    static let networkConnectivityChanged = Notification.Name("networkConnectivityChanged")
    
    // Authentication
    static let authenticationStateChanged = Notification.Name("authenticationStateChanged")
    static let userSessionExpired = Notification.Name("userSessionExpired")
    static let biometricAuthenticationAvailable = Notification.Name("biometricAuthenticationAvailable")
    
    // Real-time data updates
    static let postUpdated = Notification.Name("postUpdated")
    static let courseProgressUpdated = Notification.Name("courseProgressUpdated")
    static let newNotificationReceived = Notification.Name("newNotificationReceived")
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
    
    // Data synchronization
    static let dataSyncStarted = Notification.Name("dataSyncStarted")
    static let dataSyncCompleted = Notification.Name("dataSyncCompleted")
    static let dataSyncFailed = Notification.Name("dataSyncFailed")
    static let offlineDataAvailable = Notification.Name("offlineDataAvailable")
    
    // WebSocket connection
    static let webSocketConnected = Notification.Name("webSocketConnected")
    static let webSocketDisconnected = Notification.Name("webSocketDisconnected")
    static let webSocketReconnecting = Notification.Name("webSocketReconnecting")
}

// MARK: - Notification UserInfo Keys
struct NotificationUserInfoKeys {
    // Network
    static let isConnected = "isConnected"
    static let connectionType = "connectionType"
    
    // Authentication
    static let userId = "userId"
    static let authToken = "authToken"
    static let biometricType = "biometricType"
    
    // Real-time updates
    static let postId = "postId"
    static let courseId = "courseId"
    static let progressPercentage = "progressPercentage"
    static let achievementId = "achievementId"
    static let notificationId = "notificationId"
    
    // Data sync
    static let syncStatus = "syncStatus"
    static let syncError = "syncError"
    static let syncProgress = "syncProgress"
    static let pendingChanges = "pendingChanges"
    
    // WebSocket
    static let reconnectAttempt = "reconnectAttempt"
    static let errorMessage = "errorMessage"
}

// MARK: - Real-time Update Models
struct PostUpdate: Codable {
    let postId: String
    let type: PostUpdateType
    let post: Post?
    let likesCount: Int?
    let commentsCount: Int?
    let isLiked: Bool?
    let timestamp: Date
}

enum PostUpdateType: String, Codable {
    case newPost = "new_post"
    case likeUpdate = "like_update"
    case commentUpdate = "comment_update"
}

struct ProgressUpdate: Codable {
    let userId: String
    let courseId: String?
    let totalPoints: Int
    let currentStreak: Int
    let level: Int
    let courseProgress: Double
    let completedLessons: Int
    let timestamp: Date
}

struct CourseUpdate: Codable {
    let type: CourseUpdateType
    let course: LearningCourse?
    let timestamp: Date
}

enum CourseUpdateType: String, Codable {
    case newCourse = "new_course"
    case courseUpdated = "course_updated"
}

struct AchievementUpdate: Codable {
    let achievementId: String
    let userId: String
    let achievement: Achievement
    let timestamp: Date
}

// MARK: - Notification Helper
class NotificationHelper {
    static let shared = NotificationHelper()
    
    private init() {}
    
    // MARK: - Network Notifications
    func postNetworkConnectivityChanged(isConnected: Bool) {
        NotificationCenter.default.post(
            name: .networkConnectivityChanged,
            object: isConnected,
            userInfo: [NotificationUserInfoKeys.isConnected: isConnected]
        )
    }
    
    // MARK: - Authentication Notifications
    func postAuthenticationStateChanged(userId: String?) {
        NotificationCenter.default.post(
            name: .authenticationStateChanged,
            object: userId,
            userInfo: userId != nil ? [NotificationUserInfoKeys.userId: userId!] : [:]
        )
    }
    
    func postUserSessionExpired() {
        NotificationCenter.default.post(name: .userSessionExpired)
    }
    
    // MARK: - Real-time Update Notifications
    func postPostUpdate(_ update: PostUpdate) {
        NotificationCenter.default.post(
            name: .postUpdated,
            object: update,
            userInfo: [NotificationUserInfoKeys.postId: update.postId]
        )
    }
    
    func postProgressUpdate(_ update: ProgressUpdate) {
        NotificationCenter.default.post(
            name: .courseProgressUpdated,
            object: update,
            userInfo: [
                NotificationUserInfoKeys.userId: update.userId,
                NotificationUserInfoKeys.progressPercentage: update.courseProgress
            ]
        )
    }
    
    func postAchievementUnlocked(_ update: AchievementUpdate) {
        NotificationCenter.default.post(
            name: .achievementUnlocked,
            object: update,
            userInfo: [NotificationUserInfoKeys.achievementId: update.achievementId]
        )
    }
    
    // MARK: - Data Sync Notifications
    func postDataSyncStarted() {
        NotificationCenter.default.post(name: .dataSyncStarted)
    }
    
    func postDataSyncCompleted() {
        NotificationCenter.default.post(name: .dataSyncCompleted)
    }
    
    func postDataSyncFailed(error: Error) {
        NotificationCenter.default.post(
            name: .dataSyncFailed,
            object: error,
            userInfo: [NotificationUserInfoKeys.syncError: error.localizedDescription]
        )
    }
    
    // MARK: - WebSocket Notifications
    func postWebSocketConnected() {
        NotificationCenter.default.post(name: .webSocketConnected)
    }
    
    func postWebSocketDisconnected() {
        NotificationCenter.default.post(name: .webSocketDisconnected)
    }
    
    func postWebSocketReconnecting(attempt: Int) {
        NotificationCenter.default.post(
            name: .webSocketReconnecting,
            object: attempt,
            userInfo: [NotificationUserInfoKeys.reconnectAttempt: attempt]
        )
    }
}
