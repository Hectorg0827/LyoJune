import Foundation
import Combine
import SwiftUI
import CoreGraphics

// MARK: - Type Aliases for Backward Compatibility
public typealias CourseModel = Course
public typealias CourseInstructor = Instructor

// MARK: - Sync Protocol for Backend Integration
public protocol Syncable {
    var syncStatus: SyncStatus { get }
    var lastSyncedAt: Date? { get }
    var needsSync: Bool { get }
}

public enum SyncStatus: String, Codable, CaseIterable {
    case synced = "synced"
    case pending = "pending"
    case syncing = "syncing"
    case failed = "failed"
    case conflict = "conflict"
}

// MARK: - Network Models
public struct NetworkInfo: Codable {
    public let isConnected: Bool
    public let connectionType: ConnectionType
    public let bandwidth: Bandwidth?
    public let lastChecked: Date
    
    public init(isConnected: Bool, connectionType: ConnectionType, bandwidth: Bandwidth? = nil, lastChecked: Date = Date()) {
        self.isConnected = isConnected
        self.connectionType = connectionType
        self.bandwidth = bandwidth
        self.lastChecked = lastChecked
    }
}

public enum ConnectionType: String, Codable, CaseIterable {
    case wifi = "wifi"
    case cellular = "cellular"
    case ethernet = "ethernet"
    case none = "none"
}

public enum Bandwidth: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

// MARK: - Enhanced User Models with Backend Support
public struct User: Identifiable, Codable, Hashable, Syncable {
    public let id: UUID
    public let username: String
    public let email: String
    public let firstName: String
    public let lastName: String
    public let avatar: UserAvatar
    public let preferences: UserPreferences
    public let profile: UserProfile
    public let subscriptionTier: SubscriptionTier
    public let achievements: [Achievement]
    public let learningStats: LearningStats
    public let createdAt: Date
    public let updatedAt: Date
    
    // Backend Integration Properties
    public let serverID: String?
    public let syncStatus: SyncStatus
    public let lastSyncedAt: Date?
    public let version: Int
    public let etag: String?
    
    public var needsSync: Bool {
        return syncStatus == .pending || syncStatus == .failed
    }
    
    // API Endpoints
    public static let endpoints = UserEndpoints()
    
    public struct UserEndpoints {
        public let profile = "/api/v1/users/profile"
        public let preferences = "/api/v1/users/preferences"
        public let avatar = "/api/v1/users/avatar"
        public let achievements = "/api/v1/users/achievements"
        public let progress = "/api/v1/users/progress"
    }
    
    // Enhanced initializer with backend support
    public init(
        id: UUID = UUID(),
        username: String,
        email: String,
        firstName: String,
        lastName: String,
        avatar: UserAvatar = UserAvatar(),
        preferences: UserPreferences = UserPreferences(),
        profile: UserProfile = UserProfile(),
        subscriptionTier: SubscriptionTier = .free,
        achievements: [Achievement] = [],
        learningStats: LearningStats = LearningStats(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        serverID: String? = nil,
        syncStatus: SyncStatus = .pending,
        lastSyncedAt: Date? = nil,
        version: Int = 1,
        etag: String? = nil
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.avatar = avatar
        self.preferences = preferences
        self.profile = profile
        self.subscriptionTier = subscriptionTier
        self.achievements = achievements
        self.learningStats = learningStats
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.serverID = serverID
        self.syncStatus = syncStatus
        self.lastSyncedAt = lastSyncedAt
        self.version = version
        self.etag = etag
    }
    
    // Backend Integration Methods
    public func toAPIPayload() -> [String: Any] {
        return [
            "id": id.uuidString,
            "username": username,
            "email": email,
            "firstName": firstName,
            "lastName": lastName,
            "avatar": avatar.toAPIPayload(),
            "preferences": preferences.toAPIPayload(),
            "profile": profile.toAPIPayload(),
            "subscriptionTier": subscriptionTier.rawValue,
            "version": version,
            "updatedAt": ISO8601DateFormatter().string(from: updatedAt)
        ]
    }
    
    public static func fromAPIResponse(_ data: [String: Any]) -> User? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let username = data["username"] as? String,
              let email = data["email"] as? String,
              let firstName = data["firstName"] as? String,
              let lastName = data["lastName"] as? String else {
            return nil
        }
        
        let dateFormatter = ISO8601DateFormatter()
        let createdAt = (data["createdAt"] as? String).flatMap { dateFormatter.date(from: $0) } ?? Date()
        let updatedAt = (data["updatedAt"] as? String).flatMap { dateFormatter.date(from: $0) } ?? Date()
        let lastSyncedAt = (data["lastSyncedAt"] as? String).flatMap { dateFormatter.date(from: $0) }
        
        return User(
            id: id,
            username: username,
            email: email,
            firstName: firstName,
            lastName: lastName,
            avatar: UserAvatar.fromAPIResponse(data["avatar"] as? [String: Any] ?? [:]) ?? UserAvatar(),
            preferences: UserPreferences.fromAPIResponse(data["preferences"] as? [String: Any] ?? [:]) ?? UserPreferences(),
            profile: UserProfile.fromAPIResponse(data["profile"] as? [String: Any] ?? [:]) ?? UserProfile(),
            subscriptionTier: SubscriptionTier(rawValue: data["subscriptionTier"] as? String ?? "") ?? .free,
            achievements: (data["achievements"] as? [[String: Any]] ?? []).compactMap { Achievement.fromAPIResponse($0) },
            learningStats: LearningStats.fromAPIResponse(data["learningStats"] as? [String: Any] ?? [:]) ?? LearningStats(),
            createdAt: createdAt,
            updatedAt: updatedAt,
            serverID: data["serverID"] as? String,
            syncStatus: SyncStatus(rawValue: data["syncStatus"] as? String ?? "pending") ?? .pending,
            lastSyncedAt: lastSyncedAt,
            version: data["version"] as? Int ?? 1,
            etag: data["etag"] as? String
        )
    }
}

public enum UserRole: String, Codable, CaseIterable {
    case student = "student"
    case instructor = "instructor"
    case admin = "admin"
}

public enum UserStatus: String, Codable, CaseIterable {
    case active = "active"
    case inactive = "inactive"
    case suspended = "suspended"
}

public struct UserPreferences: Codable, Hashable {
    public let notifications: Bool
    public let darkMode: Bool
    public let language: String
    public let biometricAuth: Bool
    public let pushNotifications: Bool
    public let emailNotifications: Bool
    
    public init(notifications: Bool = true, darkMode: Bool = false, language: String = "en",
                biometricAuth: Bool = false, pushNotifications: Bool = true, 
                emailNotifications: Bool = true) {
        self.notifications = notifications
        self.darkMode = darkMode
        self.language = language
        self.biometricAuth = biometricAuth
        self.pushNotifications = pushNotifications
        self.emailNotifications = emailNotifications
    }
    
    // Backend Integration Methods
    public func toAPIPayload() -> [String: Any] {
        return [
            "notifications": notifications,
            "darkMode": darkMode,
            "language": language,
            "biometricAuth": biometricAuth,
            "pushNotifications": pushNotifications,
            "emailNotifications": emailNotifications
        ]
    }
    
    public static func fromAPIResponse(_ data: [String: Any]) -> UserPreferences? {
        let notifications = data["notifications"] as? Bool ?? true
        let darkMode = data["darkMode"] as? Bool ?? false
        let language = data["language"] as? String ?? "en"
        let biometricAuth = data["biometricAuth"] as? Bool ?? false
        let pushNotifications = data["pushNotifications"] as? Bool ?? true
        let emailNotifications = data["emailNotifications"] as? Bool ?? true
        
        return UserPreferences(
            notifications: notifications,
            darkMode: darkMode,
            language: language,
            biometricAuth: biometricAuth,
            pushNotifications: pushNotifications,
            emailNotifications: emailNotifications
        )
    }
}

public struct UserProfile: Codable, Hashable {
    public let bio: String?
    public let location: String?
    public let website: URL?
    public let socialLinks: [String: URL]
    public let interests: [String]
    public let skills: [UserSkill]
    public let birthDate: Date?
    public let timezone: String
    public let isPublic: Bool
    public let showProgress: Bool
    public let allowMessages: Bool
    
    public init(
        bio: String? = nil,
        location: String? = nil,
        website: URL? = nil,
        socialLinks: [String: URL] = [:],
        interests: [String] = [],
        skills: [UserSkill] = [],
        birthDate: Date? = nil,
        timezone: String = TimeZone.current.identifier,
        isPublic: Bool = false,
        showProgress: Bool = true,
        allowMessages: Bool = true
    ) {
        self.bio = bio
        self.location = location
        self.website = website
        self.socialLinks = socialLinks
        self.interests = interests
        self.skills = skills
        self.birthDate = birthDate
        self.timezone = timezone
        self.isPublic = isPublic
        self.showProgress = showProgress
        self.allowMessages = allowMessages
    }
    
    // Backend Integration Methods
    public func toAPIPayload() -> [String: Any] {
        var payload: [String: Any] = [
            "bio": bio ?? "",
            "location": location ?? "",
            "website": website?.absoluteString ?? "",
            "socialLinks": socialLinks.mapValues { $0.absoluteString },
            "interests": interests,
            "skills": skills.map { $0.toAPIPayload() },
            "timezone": timezone,
            "isPublic": isPublic,
            "showProgress": showProgress,
            "allowMessages": allowMessages
        ]
        
        if let birthDate = birthDate {
            payload["birthDate"] = ISO8601DateFormatter().string(from: birthDate)
        }
        
        return payload
    }
    
    public static func fromAPIResponse(_ data: [String: Any]) -> UserProfile? {
        let bio = data["bio"] as? String
        let location = data["location"] as? String
        let website = (data["website"] as? String).flatMap { URL(string: $0) }
        let socialLinksData = data["socialLinks"] as? [String: String] ?? [:]
        let socialLinks = socialLinksData.compactMapValues { URL(string: $0) }
        let interests = data["interests"] as? [String] ?? []
        let skillsData = data["skills"] as? [[String: Any]] ?? []
        let skills = skillsData.compactMap { UserSkill.fromAPIResponse($0) }
        let timezone = data["timezone"] as? String ?? TimeZone.current.identifier
        let isPublic = data["isPublic"] as? Bool ?? false
        let showProgress = data["showProgress"] as? Bool ?? true
        let allowMessages = data["allowMessages"] as? Bool ?? true
        let birthDate = (data["birthDate"] as? String).flatMap { ISO8601DateFormatter().date(from: $0) }
        
        return UserProfile(
            bio: bio,
            location: location,
            website: website,
            socialLinks: socialLinks,
            interests: interests,
            skills: skills,
            birthDate: birthDate,
            timezone: timezone,
            isPublic: isPublic,
            showProgress: showProgress,
            allowMessages: allowMessages
        )
    }
}

// MARK: - Login Response
public struct LoginResponse: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let user: UserProfile
    public let expiresIn: TimeInterval
    
    public init(accessToken: String, refreshToken: String, user: UserProfile, expiresIn: TimeInterval) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.user = user
        self.expiresIn = expiresIn
    }
}

// MARK: - Course Support Types
public enum CourseCategory: String, Codable, CaseIterable {
    case programming = "programming"
    case design = "design"
    case business = "business"
    case marketing = "marketing"
    case science = "science"
    case math = "math"
    case language = "language"
    case arts = "arts"
    case health = "health"
    case other = "other"
}

public enum CourseDifficulty: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"
}

public struct CourseMedia: Codable, Hashable {
    public let url: String
    public let type: MediaType
    public let duration: TimeInterval?
    public let thumbnail: String?
    
    public init(url: String, type: MediaType, duration: TimeInterval? = nil, thumbnail: String? = nil) {
        self.url = url
        self.type = type
        self.duration = duration
        self.thumbnail = thumbnail
    }
    
    public func toAPIPayload() -> [String: Any] {
        var payload: [String: Any] = [
            "url": url,
            "type": type.rawValue
        ]
        
        if let duration = duration {
            payload["duration"] = duration
        }
        
        if let thumbnail = thumbnail {
            payload["thumbnail"] = thumbnail
        }
        
        return payload
    }
    
    public static func fromAPIResponse(_ data: [String: Any]) -> CourseMedia? {
        guard let url = data["url"] as? String,
              let typeString = data["type"] as? String,
              let type = MediaType(rawValue: typeString) else {
            return nil
        }
        
        return CourseMedia(
            url: url,
            type: type,
            duration: data["duration"] as? TimeInterval,
            thumbnail: data["thumbnail"] as? String
        )
    }
}

public enum MediaType: String, Codable, CaseIterable {
    case video = "video"
    case audio = "audio"
    case image = "image"
    case document = "document"
    
    var icon: String {
        switch self {
        case .video: return "video.fill"
        case .audio: return "speaker.wave.2.fill"
        case .image: return "photo.fill"
        case .document: return "doc.fill"
        }
    }
    
    var title: String {
        switch self {
        case .video: return "Video"
        case .audio: return "Audio"
        case .image: return "Image"
        case .document: return "Document"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .video: return "mp4"
        case .audio: return "mp3"
        case .image: return "jpg"
        case .document: return "pdf"
        }
    }
    
    var mimeType: String {
        switch self {
        case .video: return "video/mp4"
        case .audio: return "audio/mpeg"
        case .image: return "image/jpeg"
        case .document: return "application/pdf"
        }
    }
}

public struct CoursePrice: Codable, Hashable {
    public let amount: Double
    public let currency: String
    public let discountAmount: Double?
    public let isDiscounted: Bool
    
    public init(amount: Double = 0.0, currency: String = "USD", discountAmount: Double? = nil, isDiscounted: Bool = false) {
        self.amount = amount
        self.currency = currency
        self.discountAmount = discountAmount
        self.isDiscounted = isDiscounted
    }
    
    public func toAPIPayload() -> [String: Any] {
        var payload: [String: Any] = [
            "amount": amount,
            "currency": currency,
            "isDiscounted": isDiscounted
        ]
        
        if let discountAmount = discountAmount {
            payload["discountAmount"] = discountAmount
        }
        
        return payload
    }
    
    public static func fromAPIResponse(_ data: [String: Any]) -> CoursePrice? {
        let amount = data["amount"] as? Double ?? 0.0
        let currency = data["currency"] as? String ?? "USD"
        let discountAmount = data["discountAmount"] as? Double
        let isDiscounted = data["isDiscounted"] as? Bool ?? false
        
        return CoursePrice(
            amount: amount,
            currency: currency,
            discountAmount: discountAmount,
            isDiscounted: isDiscounted
        )
    }
}

public struct CourseRating: Codable, Hashable {
    public let average: Double
    public let count: Int
    public let distribution: [Int: Int] // Star rating (1-5) -> count
    
    public init(average: Double = 0.0, count: Int = 0, distribution: [Int: Int] = [:]) {
        self.average = average
        self.count = count
        self.distribution = distribution
    }
    
    public func toAPIPayload() -> [String: Any] {
        return [
            "average": average,
            "count": count,
            "distribution": distribution
        ]
    }
    
    public static func fromAPIResponse(_ data: [String: Any]) -> CourseRating? {
        let average = data["average"] as? Double ?? 0.0
        let count = data["count"] as? Int ?? 0
        let distribution = data["distribution"] as? [Int: Int] ?? [:]
        
        return CourseRating(
            average: average,
            count: count,
            distribution: distribution
        )
    }
}

// MARK: - Course Models
public struct Course: Identifiable, Codable, Hashable, Syncable {
    public let id: UUID
    public let title: String
    public let description: String
    public let instructor: Instructor
    public let duration: TimeInterval
    public let difficulty: CourseDifficulty
    public let category: CourseCategory
    public let thumbnail: CourseMedia?
    public let previewVideo: CourseMedia?
    public let lessons: [Lesson]
    public let tags: [String]
    public let language: String
    public let price: CoursePrice
    public let rating: CourseRating
    public let createdAt: Date
    public let updatedAt: Date
    public let isPublished: Bool
    public let publishedAt: Date?
    
    // Backend Integration Properties
    public let serverID: String?
    public let syncStatus: SyncStatus
    public let lastSyncedAt: Date?
    public let version: Int
    public let etag: String?
    public let downloadStatus: DownloadStatus
    public let downloadProgress: Double
    public let downloadSize: Int64?
    
    public var needsSync: Bool {
        return syncStatus == .pending || syncStatus == .failed
    }
    
    public var isDownloaded: Bool {
        return downloadStatus == .completed
    }
    
    public var canDownload: Bool {
        return downloadStatus == .notDownloaded && downloadSize != nil
    }
    
    // API Endpoints
    public static let endpoints = CourseEndpoints()
    
    public struct CourseEndpoints {
        public let list = "/api/v1/courses"
        public let details = "/api/v1/courses/{id}"
        public let enroll = "/api/v1/courses/{id}/enroll"
        public let unenroll = "/api/v1/courses/{id}/unenroll"
        public let progress = "/api/v1/courses/{id}/progress"
        public let download = "/api/v1/courses/{id}/download"
        public let lessons = "/api/v1/courses/{id}/lessons"
        public let reviews = "/api/v1/courses/{id}/reviews"
    }
    
    // Enhanced initializer with backend support
    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        instructor: Instructor,
        category: CourseCategory,
        difficulty: CourseDifficulty,
        duration: TimeInterval,
        lessons: [Lesson] = [],
        thumbnail: CourseMedia? = nil,
        previewVideo: CourseMedia? = nil,
        tags: [String] = [],
        language: String = "en",
        price: CoursePrice = CoursePrice(),
        rating: CourseRating = CourseRating(),
        isPublished: Bool = false,
        publishedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        serverID: String? = nil,
        syncStatus: SyncStatus = .pending,
        lastSyncedAt: Date? = nil,
        version: Int = 1,
        etag: String? = nil,
        downloadStatus: DownloadStatus = .notDownloaded,
        downloadProgress: Double = 0.0,
        downloadSize: Int64? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.instructor = instructor
        self.category = category
        self.difficulty = difficulty
        self.duration = duration
        self.lessons = lessons
        self.thumbnail = thumbnail
        self.previewVideo = previewVideo
        self.tags = tags
        self.language = language
        self.price = price
        self.rating = rating
        self.isPublished = isPublished
        self.publishedAt = publishedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.serverID = serverID
        self.syncStatus = syncStatus
        self.lastSyncedAt = lastSyncedAt
        self.version = version
        self.etag = etag
        self.downloadStatus = downloadStatus
        self.downloadProgress = downloadProgress
        self.downloadSize = downloadSize
    }
    
    // Backend Integration Methods
    public func toAPIPayload() -> [String: Any] {
        var payload: [String: Any] = [
            "id": id.uuidString,
            "title": title,
            "description": description,
            "instructor": instructor.toAPIPayload(),
            "category": category.rawValue,
            "difficulty": difficulty.rawValue,
            "duration": duration,
            "tags": tags,
            "language": language,
            "price": price.toAPIPayload(),
            "isPublished": isPublished,
            "version": version,
            "updatedAt": ISO8601DateFormatter().string(from: updatedAt)
        ]
        
        if let publishedAt = publishedAt {
            payload["publishedAt"] = ISO8601DateFormatter().string(from: publishedAt)
        }
        
        if let thumbnail = thumbnail {
            payload["thumbnail"] = thumbnail.toAPIPayload()
        }
        
        if let previewVideo = previewVideo {
            payload["previewVideo"] = previewVideo.toAPIPayload()
        }
        
        return payload
    }
    
    public static func fromAPIResponse(_ data: [String: Any]) -> Course? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let title = data["title"] as? String,
              let description = data["description"] as? String,
              let instructorData = data["instructor"] as? [String: Any],
              let instructor = Instructor.fromAPIResponse(instructorData),
              let categoryString = data["category"] as? String,
              let category = CourseCategory(rawValue: categoryString),
              let difficultyString = data["difficulty"] as? String,
              let difficulty = CourseDifficulty(rawValue: difficultyString),
              let duration = data["duration"] as? TimeInterval else {
            return nil
        }
        
        let dateFormatter = ISO8601DateFormatter()
        let createdAt = (data["createdAt"] as? String).flatMap { dateFormatter.date(from: $0) } ?? Date()
        let updatedAt = (data["updatedAt"] as? String).flatMap { dateFormatter.date(from: $0) } ?? Date()
        let publishedAt = (data["publishedAt"] as? String).flatMap { dateFormatter.date(from: $0) }
        let lastSyncedAt = (data["lastSyncedAt"] as? String).flatMap { dateFormatter.date(from: $0) }
        
        return Course(
            id: id,
            title: title,
            description: description,
            instructor: instructor,
            category: category,
            difficulty: difficulty,
            duration: duration,
            lessons: (data["lessons"] as? [[String: Any]] ?? []).compactMap { Lesson.fromAPIResponse($0) },
            thumbnail: CourseMedia.fromAPIResponse(data["thumbnail"] as? [String: Any] ?? [:]),
            previewVideo: CourseMedia.fromAPIResponse(data["previewVideo"] as? [String: Any] ?? [:]),
            tags: data["tags"] as? [String] ?? [],
            language: data["language"] as? String ?? "en",
            price: CoursePrice.fromAPIResponse(data["price"] as? [String: Any] ?? [:]) ?? CoursePrice(),
            rating: CourseRating.fromAPIResponse(data["rating"] as? [String: Any] ?? [:]) ?? CourseRating(),
            isPublished: data["isPublished"] as? Bool ?? false,
            publishedAt: publishedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            serverID: data["serverID"] as? String,
            syncStatus: SyncStatus(rawValue: data["syncStatus"] as? String ?? "pending") ?? .pending,
            lastSyncedAt: lastSyncedAt,
            version: data["version"] as? Int ?? 1,
            etag: data["etag"] as? String,
            downloadStatus: DownloadStatus(rawValue: data["downloadStatus"] as? String ?? "notDownloaded") ?? .notDownloaded,
            downloadProgress: data["downloadProgress"] as? Double ?? 0.0,
            downloadSize: data["downloadSize"] as? Int64
        )
    }
}

// MARK: - Download Status Enum
public enum DownloadStatus: String, Codable, CaseIterable {
    case notDownloaded = "notDownloaded"
    case queued = "queued"
    case downloading = "downloading"
    case paused = "paused"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
}

// MARK: - Post Models
public struct Post: Codable, Identifiable, Syncable {
    public let id: String
    public let authorId: String
    public let authorName: String
    public let authorAvatar: String?
    public let content: String
    public let imageURL: String?
    public let videoURL: String?
    public let likes: Int
    public let comments: Int
    public let shares: Int
    public let isLiked: Bool
    public let isBookmarked: Bool
    public let createdAt: Date
    public let updatedAt: Date
    public let tags: [String]
    public let category: PostCategory
    public let visibility: PostVisibility
    
    // Backend Integration Properties
    public let serverID: String?
    public let syncStatus: SyncStatus
    public let lastSyncedAt: Date?
    public let version: Int
    public let etag: String?
    
    public var needsSync: Bool {
        return syncStatus == .pending || syncStatus == .failed
    }
    
    public init(id: String, authorId: String, authorName: String, authorAvatar: String? = nil,
                content: String, imageURL: String? = nil, videoURL: String? = nil,
                likes: Int = 0, comments: Int = 0, shares: Int = 0,
                isLiked: Bool = false, isBookmarked: Bool = false, 
                createdAt: Date = Date(), updatedAt: Date = Date(), 
                tags: [String] = [], category: PostCategory = .general,
                visibility: PostVisibility = .public,
                serverID: String? = nil, syncStatus: SyncStatus = .synced,
                lastSyncedAt: Date? = nil, version: Int = 1, etag: String? = nil) {
        self.id = id
        self.authorId = authorId
        self.authorName = authorName
        self.authorAvatar = authorAvatar
        self.content = content
        self.imageURL = imageURL
        self.videoURL = videoURL
        self.likes = likes
        self.comments = comments
        self.shares = shares
        self.isLiked = isLiked
        self.isBookmarked = isBookmarked
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tags = tags
        self.category = category
        self.visibility = visibility
        self.serverID = serverID
        self.syncStatus = syncStatus
        self.lastSyncedAt = lastSyncedAt
        self.version = version
        self.etag = etag
    }
    
    // Backend Integration Methods
    public func toAPIPayload() -> [String: Any] {
        var payload: [String: Any] = [
            "id": id,
            "authorId": authorId,
            "authorName": authorName,
            "content": content,
            "likes": likes,
            "comments": comments,
            "shares": shares,
            "isLiked": isLiked,
            "isBookmarked": isBookmarked,
            "createdAt": ISO8601DateFormatter().string(from: createdAt),
            "updatedAt": ISO8601DateFormatter().string(from: updatedAt),
            "tags": tags,
            "category": category.rawValue,
            "visibility": visibility.rawValue,
            "version": version
        ]
        
        if let authorAvatar = authorAvatar {
            payload["authorAvatar"] = authorAvatar
        }
        
        if let imageURL = imageURL {
            payload["imageURL"] = imageURL
        }
        
        if let videoURL = videoURL {
            payload["videoURL"] = videoURL
        }
        
        if let serverID = serverID {
            payload["serverID"] = serverID
        }
        
        if let etag = etag {
            payload["etag"] = etag
        }
        
        return payload
    }
    
    public static func fromAPIResponse(_ data: [String: Any]) -> Post? {
        guard let id = data["id"] as? String,
              let authorId = data["authorId"] as? String,
              let authorName = data["authorName"] as? String,
              let content = data["content"] as? String,
              let likes = data["likes"] as? Int,
              let comments = data["comments"] as? Int,
              let shares = data["shares"] as? Int,
              let isLiked = data["isLiked"] as? Bool,
              let isBookmarked = data["isBookmarked"] as? Bool,
              let createdAtString = data["createdAt"] as? String,
              let updatedAtString = data["updatedAt"] as? String,
              let createdAt = ISO8601DateFormatter().date(from: createdAtString),
              let updatedAt = ISO8601DateFormatter().date(from: updatedAtString),
              let tags = data["tags"] as? [String],
              let categoryString = data["category"] as? String,
              let category = PostCategory(rawValue: categoryString),
              let visibilityString = data["visibility"] as? String,
              let visibility = PostVisibility(rawValue: visibilityString),
              let version = data["version"] as? Int else {
            return nil
        }
        
        return Post(
            id: id,
            authorId: authorId,
            authorName: authorName,
            authorAvatar: data["authorAvatar"] as? String,
            content: content,
            imageURL: data["imageURL"] as? String,
            videoURL: data["videoURL"] as? String,
            likes: likes,
            comments: comments,
            shares: shares,
            isLiked: isLiked,
            isBookmarked: isBookmarked,
            createdAt: createdAt,
            updatedAt: updatedAt,
            tags: tags,
            category: category,
            visibility: visibility,
            serverID: data["serverID"] as? String,
            syncStatus: SyncStatus(rawValue: data["syncStatus"] as? String ?? "") ?? .synced,
            lastSyncedAt: data["lastSyncedAt"] as? Date,
            version: version,
            etag: data["etag"] as? String
        )
    }
}

public enum PostCategory: String, Codable, CaseIterable {
    case general = "general"
    case question = "question"
    case achievement = "achievement"
    case tip = "tip"
    case resource = "resource"
    case discussion = "discussion"
}

public enum PostVisibility: String, Codable, CaseIterable {
    case `public` = "public"
    case friends = "friends"
    case `private` = "private"
}

public struct Comment: Codable, Identifiable {
    public let id: String
    public let postId: String
    public let authorId: String
    public let authorName: String
    public let authorAvatar: String?
    public let content: String
    public let likes: Int
    public let replies: [Comment]
    public let isLiked: Bool
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(id: String, postId: String, authorId: String, authorName: String,
                authorAvatar: String? = nil, content: String, likes: Int = 0,
                replies: [Comment] = [], isLiked: Bool = false, 
                createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.postId = postId
        self.authorId = authorId
        self.authorName = authorName
        self.authorAvatar = authorAvatar
        self.content = content
        self.likes = likes
        self.replies = replies
        self.isLiked = isLiked
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Backend Integration Methods
    public func toAPIPayload() -> [String: Any] {
        var payload: [String: Any] = [
            "id": id,
            "postId": postId,
            "authorId": authorId,
            "authorName": authorName,
            "content": content,
            "likes": likes,
            "replies": replies.map { $0.toAPIPayload() },
            "isLiked": isLiked,
            "createdAt": ISO8601DateFormatter().string(from: createdAt),
            "updatedAt": ISO8601DateFormatter().string(from: updatedAt)
        ]
        
        if let authorAvatar = authorAvatar {
            payload["authorAvatar"] = authorAvatar
        }
        
        return payload
    }
    
    public static func fromAPIResponse(_ data: [String: Any]) -> Comment? {
        guard let id = data["id"] as? String,
              let postId = data["postId"] as? String,
              let authorId = data["authorId"] as? String,
              let authorName = data["authorName"] as? String,
              let content = data["content"] as? String,
              let likes = data["likes"] as? Int,
              let repliesData = data["replies"] as? [[String: Any]],
              let isLiked = data["isLiked"] as? Bool,
              let createdAtString = data["createdAt"] as? String,
              let updatedAtString = data["updatedAt"] as? String,
              let createdAt = ISO8601DateFormatter().date(from: createdAtString),
              let updatedAt = ISO8601DateFormatter().date(from: updatedAtString) else {
            return nil
        }
        
        let replies = repliesData.compactMap { Comment.fromAPIResponse($0) }
        
        return Comment(
            id: id,
            postId: postId,
            authorId: authorId,
            authorName: authorName,
            authorAvatar: data["authorAvatar"] as? String,
            content: content,
            likes: likes,
            replies: replies,
            isLiked: isLiked,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - Achievement Models
public struct Achievement: Identifiable, Codable, Hashable {
    public let id: String
    public let title: String
    public let description: String
    public let iconURL: String?
    public let points: Int
    public let isUnlocked: Bool
    public let unlockedAt: Date?
    public let category: AchievementCategory
    public let rarity: AchievementRarity
    public let requirements: [String]
    public let progress: Double
    
    public init(id: String, title: String, description: String, iconURL: String? = nil,
                points: Int, isUnlocked: Bool = false, unlockedAt: Date? = nil,
                category: AchievementCategory, rarity: AchievementRarity = .common,
                requirements: [String] = [], progress: Double = 0.0) {
        self.id = id
        self.title = title
        self.description = description
        self.iconURL = iconURL
        self.points = points
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
        self.category = category
        self.rarity = rarity
        self.requirements = requirements
        self.progress = progress
    }
    
    // Backend Integration Methods
    public func toAPIPayload() -> [String: Any] {
        var payload: [String: Any] = [
            "id": id,
            "title": title,
            "description": description,
            "category": category.rawValue,
            "points": points,
            "rarity": rarity.rawValue,
            "isUnlocked": isUnlocked,
            "progress": progress,
            "requirements": requirements
        ]
        
        if let iconURL = iconURL {
            payload["iconURL"] = iconURL
        }
        
        if let unlockedAt = unlockedAt {
            payload["unlockedAt"] = ISO8601DateFormatter().string(from: unlockedAt)
        }
        
        return payload
    }
    
    public static func fromAPIResponse(_ data: [String: Any]) -> Achievement? {
        guard let id = data["id"] as? String,
              let title = data["title"] as? String,
              let description = data["description"] as? String,
              let categoryString = data["category"] as? String,
              let category = AchievementCategory(rawValue: categoryString),
              let points = data["points"] as? Int,
              let rarityString = data["rarity"] as? String,
              let rarity = AchievementRarity(rawValue: rarityString) else {
            return nil
        }
        
        let isUnlocked = data["isUnlocked"] as? Bool ?? false
        let progress = data["progress"] as? Double ?? 0.0
        let requirements = data["requirements"] as? [String] ?? []
        let unlockedAt = (data["unlockedAt"] as? String).flatMap { ISO8601DateFormatter().date(from: $0) }
        
        return Achievement(
            id: id,
            title: title,
            description: description,
            iconURL: data["iconURL"] as? String,
            points: points,
            isUnlocked: isUnlocked,
            unlockedAt: unlockedAt,
            category: category,
            rarity: rarity,
            requirements: requirements,
            progress: progress
        )
    }
}

public enum AchievementCategory: String, Codable, CaseIterable {
    case learning = "learning"
    case social = "social"
    case streak = "streak"
    case completion = "completion"
    case engagement = "engagement"
    case special = "special"
}

public enum AchievementRarity: String, Codable, CaseIterable {
    case common = "common"
    case uncommon = "uncommon"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
}

// MARK: - Community Models
public struct CommunityGroup: Codable, Identifiable {
    public let id: String
    public let name: String
    public let description: String
    public let imageURL: String?
    public let memberCount: Int
    public let category: GroupCategory
    public let isPrivate: Bool
    public let createdAt: Date
    public let adminIds: [String]
    
    public init(id: String, name: String, description: String, imageURL: String? = nil,
                memberCount: Int = 0, category: GroupCategory, isPrivate: Bool = false,
                createdAt: Date = Date(), adminIds: [String] = []) {
        self.id = id
        self.name = name
        self.description = description
        self.imageURL = imageURL
        self.memberCount = memberCount
        self.category = category
        self.isPrivate = isPrivate
        self.createdAt = createdAt
        self.adminIds = adminIds
    }
    
    // Backend Integration Methods
    public func toAPIPayload() -> [String: Any] {
        var payload: [String: Any] = [
            "id": id,
            "name": name,
            "description": description,
            "memberCount": memberCount,
            "category": category.rawValue,
            "isPrivate": isPrivate,
            "createdAt": ISO8601DateFormatter().string(from: createdAt),
            "adminIds": adminIds
        ]
        
        if let imageURL = imageURL {
            payload["imageURL"] = imageURL
        }
        
        return payload
    }
    
    public static func fromAPIResponse(_ data: [String: Any]) -> CommunityGroup? {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let description = data["description"] as? String,
              let memberCount = data["memberCount"] as? Int,
              let categoryString = data["category"] as? String,
              let category = GroupCategory(rawValue: categoryString),
              let isPrivate = data["isPrivate"] as? Bool,
              let createdAtString = data["createdAt"] as? String,
              let createdAt = ISO8601DateFormatter().date(from: createdAtString),
              let adminIds = data["adminIds"] as? [String] else {
            return nil
        }
        
        return CommunityGroup(
            id: id,
            name: name,
            description: description,
            imageURL: data["imageURL"] as? String,
            memberCount: memberCount,
            category: category,
            isPrivate: isPrivate,
            createdAt: createdAt,
            adminIds: adminIds
        )
    }
}

public enum GroupCategory: String, Codable, CaseIterable {
    case studyGroup = "study_group"
    case courseDiscussion = "course_discussion"
    case general = "general"
    case hobby = "hobby"
    case career = "career"
}

// MARK: - Notification Models
public struct NotificationModel: Codable, Identifiable {
    public let id: String
    public let userId: String
    public let title: String
    public let message: String
    public let type: NotificationType
    public let isRead: Bool
    public let createdAt: Date
    public let actionURL: String?
    public let metadata: [String: String]
    
    public init(id: String, userId: String, title: String, message: String,
                type: NotificationType, isRead: Bool = false, createdAt: Date = Date(),
                actionURL: String? = nil, metadata: [String: String] = [:]) {
        self.id = id
        self.userId = userId
        self.title = title
        self.message = message
        self.type = type
        self.isRead = isRead
        self.createdAt = createdAt
        self.actionURL = actionURL
        self.metadata = metadata
    }
    
    // Backend Integration Methods
    public func toAPIPayload() -> [String: Any] {
        var payload: [String: Any] = [
            "id": id,
            "userId": userId,
            "title": title,
            "message": message,
            "type": type.rawValue,
            "isRead": isRead,
            "createdAt": ISO8601DateFormatter().string(from: createdAt),
            "metadata": metadata
        ]
        
        if let actionURL = actionURL {
            payload["actionURL"] = actionURL
        }
        
        return payload
    }
    
    public static func fromAPIResponse(_ data: [String: Any]) -> NotificationModel? {
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let title = data["title"] as? String,
              let message = data["message"] as? String,
              let typeString = data["type"] as? String,
              let type = NotificationType(rawValue: typeString),
              let isRead = data["isRead"] as? Bool,
              let createdAtString = data["createdAt"] as? String,
              let createdAt = ISO8601DateFormatter().date(from: createdAtString),
              let metadata = data["metadata"] as? [String: String] else {
            return nil
        }
        
        return NotificationModel(
            id: id,
            userId: userId,
            title: title,
            message: message,
            type: type,
            isRead: isRead,
            createdAt: createdAt,
            actionURL: data["actionURL"] as? String,
            metadata: metadata
        )
    }
}

public enum NotificationType: String, Codable, CaseIterable {
    case courseUpdate = "course_update"
    case achievement = "achievement"
    case social = "social"
    case reminder = "reminder"
    case system = "system"
    case marketing = "marketing"
}

// MARK: - Analytics Models
public struct AnalyticsEvent: Codable {
    public let eventName: String
    public let userId: String?
    public let properties: [String: String] // Changed from [String: Any] to [String: String] for Codable compliance
    public let timestamp: Date
    public let sessionId: String
    
    enum CodingKeys: String, CodingKey {
        case eventName, userId, properties, timestamp, sessionId
    }
    
    public init(eventName: String, userId: String? = nil, properties: [String: String] = [:], 
                timestamp: Date = Date(), sessionId: String = UUID().uuidString) {
        self.eventName = eventName
        self.userId = userId
        self.properties = properties
        self.timestamp = timestamp
        self.sessionId = sessionId
    }
    
    // Convenience initializer for [String: Any] that converts to [String: String]
    public init(eventName: String, userId: String? = nil, propertiesAny: [String: Any] = [:], 
                timestamp: Date = Date(), sessionId: String = UUID().uuidString) {
        self.eventName = eventName
        self.userId = userId
        // Convert Any values to String representations
        self.properties = propertiesAny.mapValues { "\($0)" }
        self.timestamp = timestamp
        self.sessionId = sessionId
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        eventName = try container.decode(String.self, forKey: .eventName)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        properties = try container.decode([String: String].self, forKey: .properties)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(eventName, forKey: .eventName)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encode(properties, forKey: .properties)
    }
    
    // Backend Integration Methods
    public func toAPIPayload() -> [String: Any] {
        var payload: [String: Any] = [
            "eventName": eventName,
            "properties": properties,
            "timestamp": ISO8601DateFormatter().string(from: timestamp),
            "sessionId": sessionId
        ]
        
        if let userId = userId {
            payload["userId"] = userId
        }
        
        return payload
    }
    
    public static func fromAPIResponse(_ data: [String: Any]) -> AnalyticsEvent? {
        guard let eventName = data["eventName"] as? String,
              let properties = data["properties"] as? [String: String],
              let timestampString = data["timestamp"] as? String,
              let timestamp = ISO8601DateFormatter().date(from: timestampString),
              let sessionId = data["sessionId"] as? String else {
            return nil
        }
        
        return AnalyticsEvent(
            eventName: eventName,
            userId: data["userId"] as? String,
            properties: properties,
            timestamp: timestamp,
            sessionId: sessionId
        )
    }
}

public struct Instructor: Identifiable, Codable, Hashable {
    public let id: UUID
    public let name: String
    public let bio: String
    public let avatarURL: URL?
    public let expertise: [String]
    public let rating: Double
    public let totalStudents: Int
    public let totalCourses: Int
    public let isVerified: Bool
    public let socialLinks: [String: URL]
    
    // Backend Integration Methods
    public func toAPIPayload() -> [String: Any] {
        var payload: [String: Any] = [
            "id": id.uuidString,
            "name": name,
            "bio": bio,
            "expertise": expertise,
            "rating": rating,
            "totalStudents": totalStudents,
            "totalCourses": totalCourses,
            "isVerified": isVerified,
            "socialLinks": socialLinks.mapValues { $0.absoluteString }
        ]
        
        if let avatarURL = avatarURL {
            payload["avatarURL"] = avatarURL.absoluteString
        }
        
        return payload
    }
    
    public static func fromAPIResponse(_ data: [String: Any]) -> Instructor? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = data["name"] as? String,
              let bio = data["bio"] as? String else {
            return nil
        }
        
        let avatarURL = (data["avatarURL"] as? String).flatMap { URL(string: $0) }
        let expertise = data["expertise"] as? [String] ?? []
        let rating = data["rating"] as? Double ?? 0.0
        let totalStudents = data["totalStudents"] as? Int ?? 0
        let totalCourses = data["totalCourses"] as? Int ?? 0
        let isVerified = data["isVerified"] as? Bool ?? false
        let socialLinksData = data["socialLinks"] as? [String: String] ?? [:]
        let socialLinks = socialLinksData.compactMapValues { URL(string: $0) }
        
        return Instructor(
            id: id,
            name: name,
            bio: bio,
            avatarURL: avatarURL,
            expertise: expertise,
            rating: rating,
            totalStudents: totalStudents,
            totalCourses: totalCourses,
            isVerified: isVerified,
            socialLinks: socialLinks
        )
    }
}

// MARK: - Monthly Stats Model
public struct MonthlyStats: Codable, Hashable {
    public let month: String
    public let studyTime: TimeInterval
    public let coursesCompleted: Int
    public let lessonsCompleted: Int
    public let pointsEarned: Int
    
    public init(month: String, studyTime: TimeInterval = 0, coursesCompleted: Int = 0,
                lessonsCompleted: Int = 0, pointsEarned: Int = 0) {
        self.month = month
        self.studyTime = studyTime
        self.coursesCompleted = coursesCompleted
        self.lessonsCompleted = lessonsCompleted
        self.pointsEarned = pointsEarned
    }
    
    // Backend Integration Methods
    public func toAPIPayload() -> [String: Any] {
        return [
            "month": month,
            "studyTime": studyTime,
            "coursesCompleted": coursesCompleted,
            "lessonsCompleted": lessonsCompleted,
            "pointsEarned": pointsEarned
        ]
    }
    
    public static func fromAPIResponse(_ data: [String: Any]) -> MonthlyStats? {
        let month = data["month"] as? String ?? ""
        let studyTime = data["studyTime"] as? TimeInterval ?? 0
        let coursesCompleted = data["coursesCompleted"] as? Int ?? 0
        let lessonsCompleted = data["lessonsCompleted"] as? Int ?? 0
        let pointsEarned = data["pointsEarned"] as? Int ?? 0
        
        return MonthlyStats(
            month: month,
            studyTime: studyTime,
            coursesCompleted: coursesCompleted,
            lessonsCompleted: lessonsCompleted,
            pointsEarned: pointsEarned
        )
    }
}

// MARK: - Learning Stats Model
public struct LearningStats: Codable, Hashable {
    public let totalStudyTime: TimeInterval
    public let coursesCompleted: Int
    public let coursesInProgress: Int
    public let lessonsCompleted: Int
    public let currentStreak: Int
    public let longestStreak: Int
    public let totalPoints: Int
    public let averageScore: Double
    public let skillLevels: [String: SkillLevel]
    public let weeklyGoal: TimeInterval
    public let weeklyProgress: TimeInterval
    public let monthlyStats: [String: MonthlyStats]
    
    public init(totalStudyTime: TimeInterval = 0, coursesCompleted: Int = 0,
                coursesInProgress: Int = 0, lessonsCompleted: Int = 0,
                currentStreak: Int = 0, longestStreak: Int = 0,
                totalPoints: Int = 0, averageScore: Double = 0.0,
                skillLevels: [String: SkillLevel] = [:],
                weeklyGoal: TimeInterval = 0, weeklyProgress: TimeInterval = 0,
                monthlyStats: [String: MonthlyStats] = [:]) {
        self.totalStudyTime = totalStudyTime
        self.coursesCompleted = coursesCompleted
        self.coursesInProgress = coursesInProgress
        self.lessonsCompleted = lessonsCompleted
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalPoints = totalPoints
        self.averageScore = averageScore
        self.skillLevels = skillLevels
        self.weeklyGoal = weeklyGoal
        self.weeklyProgress = weeklyProgress
        self.monthlyStats = monthlyStats
    }
    
    // Backend Integration Methods
    public func toAPIPayload() -> [String: Any] {
        return [
            "totalStudyTime": totalStudyTime,
            "coursesCompleted": coursesCompleted,
            "coursesInProgress": coursesInProgress,
            "lessonsCompleted": lessonsCompleted,
            "currentStreak": currentStreak,
            "longestStreak": longestStreak,
            "totalPoints": totalPoints,
            "averageScore": averageScore,
            "skillLevels": skillLevels.mapValues { $0.rawValue },
            "weeklyGoal": weeklyGoal,
            "weeklyProgress": weeklyProgress,
            "monthlyStats": monthlyStats.mapValues { $0.toAPIPayload() }
        ]
    }
    
    public static func fromAPIResponse(_ data: [String: Any]) -> LearningStats? {
        let totalStudyTime = data["totalStudyTime"] as? TimeInterval ?? 0
        let coursesCompleted = data["coursesCompleted"] as? Int ?? 0
        let coursesInProgress = data["coursesInProgress"] as? Int ?? 0
        let lessonsCompleted = data["lessonsCompleted"] as? Int ?? 0
        let currentStreak = data["currentStreak"] as? Int ?? 0
        let longestStreak = data["longestStreak"] as? Int ?? 0
        let totalPoints = data["totalPoints"] as? Int ?? 0
        let averageScore = data["averageScore"] as? Double ?? 0.0
        let skillLevelsData = data["skillLevels"] as? [String: String] ?? [:]
        let skillLevels = skillLevelsData.compactMapValues { SkillLevel(rawValue: $0) }
        let weeklyGoal = data["weeklyGoal"] as? TimeInterval ?? 0
        let weeklyProgress = data["weeklyProgress"] as? TimeInterval ?? 0
        let monthlyStatsData = data["monthlyStats"] as? [String: [String: Any]] ?? [:]
        let monthlyStats = monthlyStatsData.compactMapValues { MonthlyStats.fromAPIResponse($0) }
        
        return LearningStats(
            totalStudyTime: totalStudyTime,
            coursesCompleted: coursesCompleted,
            coursesInProgress: coursesInProgress,
            lessonsCompleted: lessonsCompleted,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalPoints: totalPoints,
            averageScore: averageScore,
            skillLevels: skillLevels,
            weeklyGoal: weeklyGoal,
            weeklyProgress: weeklyProgress,
            monthlyStats: monthlyStats
        )
    }
}

// MARK: - Extensions for Backend Integration

extension Color {
    public func toHex() -> String {
        let components = self.cgColor?.components ?? [0, 0, 0, 1]
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    
    /*
    public init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    */
}

// MARK: - API Response Helpers
extension Array where Element == Any {
    public func toAPIPayload() -> [[String: Any]] {
        return self.compactMap { element in
            if let apiPayloadConvertible = element as? APIPayloadConvertible {
                return apiPayloadConvertible.toAPIPayload()
            }
            return nil
        }
    }
}

extension Dictionary where Key == String, Value == Any {
    public func toModel<T: APIResponseConvertible>(_ type: T.Type) -> T? {
        return T.fromAPIResponse(self)
    }
}

// MARK: - API Protocols
public protocol APIPayloadConvertible {
    func toAPIPayload() -> [String: Any]
}

public protocol APIResponseConvertible {
    static func fromAPIResponse(_ data: [String: Any]) -> Self?
}

// MARK: - Sync Queue Models for Offline Support
public struct SyncQueueItem: Codable, Identifiable {
    public let id: UUID
    public let entityType: String
    public let entityID: String
    public let operation: SyncOperation
    public let payload: Data
    public let priority: SyncPriority
    public let createdAt: Date
    public let retryCount: Int
    public let maxRetries: Int
    
    public init(
        id: UUID = UUID(),
        entityType: String,
        entityID: String,
        operation: SyncOperation,
        payload: Data,
        priority: SyncPriority = .normal,
        createdAt: Date = Date(),
        retryCount: Int = 0,
        maxRetries: Int = 3
    ) {
        self.id = id
        self.entityType = entityType
        self.entityID = entityID
        self.operation = operation
        self.payload = payload
        self.priority = priority
        self.createdAt = createdAt
        self.retryCount = retryCount
        self.maxRetries = maxRetries
    }
}

public enum SyncOperation: String, Codable, CaseIterable {
    case create = "create"
    case update = "update"
    case delete = "delete"
    case upload = "upload"
}

public enum SyncPriority: Int, Codable, CaseIterable, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3
    
    public static func < (lhs: SyncPriority, rhs: SyncPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Missing Models for API Integration

// MARK: - User Avatar
public struct UserAvatar: Codable, Hashable {
    public let id: UUID
    public let url: String?
    public let initials: String
    public let backgroundColor: String
    public let size: AvatarSize
    public let isCustom: Bool
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        url: String? = nil,
        initials: String = "",
        backgroundColor: String = "#6366F1",
        size: AvatarSize = .medium,
        isCustom: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.url = url
        self.initials = initials
        self.backgroundColor = backgroundColor
        self.size = size
        self.isCustom = isCustom
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Backend Integration Methods
    public func toAPIPayload() -> [String: Any] {
        var payload: [String: Any] = [
            "id": id.uuidString,
            "initials": initials,
            "backgroundColor": backgroundColor,
            "size": size.rawValue,
            "isCustom": isCustom,
            "createdAt": ISO8601DateFormatter().string(from: createdAt),
            "updatedAt": ISO8601DateFormatter().string(from: updatedAt)
        ]
        
        if let url = url {
            payload["url"] = url
        }
        
        return payload
    }
    
    public static func fromAPIResponse(_ data: [String: Any]) -> UserAvatar? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let initials = data["initials"] as? String,
              let backgroundColor = data["backgroundColor"] as? String,
              let sizeString = data["size"] as? String,
              let size = AvatarSize(rawValue: sizeString),
              let isCustom = data["isCustom"] as? Bool,
              let createdAtString = data["createdAt"] as? String,
              let updatedAtString = data["updatedAt"] as? String,
              let createdAt = ISO8601DateFormatter().date(from: createdAtString),
              let updatedAt = ISO8601DateFormatter().date(from: updatedAtString) else {
            return nil
        }
        
        return UserAvatar(
            id: id,
            url: data["url"] as? String,
            initials: initials,
            backgroundColor: backgroundColor,
            size: size,
            isCustom: isCustom,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

public enum AvatarSize: String, Codable, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    
    public var dimension: CGFloat {
        switch self {
        case .small: return 32
        case .medium: return 48
        case .large: return 64
        }
    }
}

// MARK: - Subscription Tier
public enum SubscriptionTier: String, Codable, CaseIterable, Hashable {
    case free = "free"
    case basic = "basic"
    case premium = "premium"
    case enterprise = "enterprise"
    
    public var displayName: String {
        switch self {
        case .free: return "Free"
        case .basic: return "Basic"
        case .premium: return "Premium"
        case .enterprise: return "Enterprise"
        }
    }
    
    public var features: [String] {
        switch self {
        case .free:
            return ["5 courses", "Basic support", "Community access"]
        case .basic:
            return ["20 courses", "Email support", "Basic analytics", "Offline viewing"]
        case .premium:
            return ["Unlimited courses", "Priority support", "Advanced analytics", "Download courses", "Certificates"]
        case .enterprise:
            return ["All premium features", "Custom content", "Team management", "API access", "White-label solution"]
        }
    }
}

// MARK: - User Skill
public struct UserSkill: Codable, Hashable, Identifiable {
    public let id: UUID
    public let name: String
    public let category: SkillCategory
    public let level: SkillLevel
    public let progress: Double // 0.0 to 1.0
    public let endorsements: Int
    public let courses: [String] // Course IDs
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        category: SkillCategory,
        level: SkillLevel = .beginner,
        progress: Double = 0.0,
        endorsements: Int = 0,
        courses: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.level = level
        self.progress = progress
        self.endorsements = endorsements
        self.courses = courses
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Backend Integration Methods
    public func toAPIPayload() -> [String: Any] {
        return [
            "id": id.uuidString,
            "name": name,
            "category": category.rawValue,
            "level": level.rawValue,
            "progress": progress,
            "endorsements": endorsements,
            "courses": courses,
            "createdAt": ISO8601DateFormatter().string(from: createdAt),
            "updatedAt": ISO8601DateFormatter().string(from: updatedAt)
        ]
    }
    
    public static func fromAPIResponse(_ data: [String: Any]) -> UserSkill? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = data["name"] as? String,
              let categoryString = data["category"] as? String,
              let category = SkillCategory(rawValue: categoryString),
              let levelString = data["level"] as? String,
              let level = SkillLevel(rawValue: levelString),
              let progress = data["progress"] as? Double,
              let endorsements = data["endorsements"] as? Int,
              let courses = data["courses"] as? [String],
              let createdAtString = data["createdAt"] as? String,
              let updatedAtString = data["updatedAt"] as? String,
              let createdAt = ISO8601DateFormatter().date(from: createdAtString),
              let updatedAt = ISO8601DateFormatter().date(from: updatedAtString) else {
            return nil
        }
        
        return UserSkill(
            id: id,
            name: name,
            category: category,
            level: level,
            progress: progress,
            endorsements: endorsements,
            courses: courses,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

public enum SkillCategory: String, Codable, CaseIterable {
    case programming = "programming"
    case design = "design"
    case marketing = "marketing"
    case business = "business"
    case language = "language"
    case science = "science"
    case arts = "arts"
    case health = "health"
    case other = "other"
}

public enum SkillLevel: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"
    
    public var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .expert: return "Expert"
        }
    }
}

// MARK: - Lesson Model
public struct Lesson: Identifiable, Codable, Hashable, Syncable {
    public let id: UUID
    public let title: String
    public let description: String
    public let content: String
    public let videoURL: String?
    public let audioURL: String?
    public let duration: TimeInterval
    public let order: Int
    public let isCompleted: Bool
    public let isLocked: Bool
    public let prerequisites: [UUID]
    public let resources: [LessonResource]
    public let quiz: Quiz?
    public let createdAt: Date
    public let updatedAt: Date
    
    // Backend Integration Properties
    public let serverID: String?
    public let syncStatus: SyncStatus
    public let lastSyncedAt: Date?
    public let version: Int
    public let etag: String?
    
    public var needsSync: Bool {
        return syncStatus == .pending || syncStatus == .failed
    }
    
    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        content: String,
        videoURL: String? = nil,
        audioURL: String? = nil,
        duration: TimeInterval,
        order: Int,
        isCompleted: Bool = false,
        isLocked: Bool = false,
        prerequisites: [UUID] = [],
        resources: [LessonResource] = [],
        quiz: Quiz? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        serverID: String? = nil,
        syncStatus: SyncStatus = .synced,
        lastSyncedAt: Date? = nil,
        version: Int = 1,
        etag: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.content = content
        self.videoURL = videoURL
        self.audioURL = audioURL
        self.duration = duration
        self.order = order
        self.isCompleted = isCompleted
        self.isLocked = isLocked
        self.prerequisites = prerequisites
        self.resources = resources
        self.quiz = quiz
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.serverID = serverID
        self.syncStatus = syncStatus
        self.lastSyncedAt = lastSyncedAt
        self.version = version
        self.etag = etag
    }
    
    // Backend Integration Methods
    public func toAPIPayload() -> [String: Any] {
        var payload: [String: Any] = [
            "id": id.uuidString,
            "title": title,
            "description": description,
            "content": content,
            "duration": duration,
            "order": order,
            "isCompleted": isCompleted,
            "isLocked": isLocked,
            "prerequisites": prerequisites.map { $0.uuidString },
            "resources": resources.map { $0.toAPIPayload() },
            "createdAt": ISO8601DateFormatter().string(from: createdAt),
            "updatedAt": ISO8601DateFormatter().string(from: updatedAt),
            "version": version
        ]
        
        if let videoURL = videoURL {
            payload["videoURL"] = videoURL
        }
        
        if let audioURL = audioURL {
            payload["audioURL"] = audioURL
        }
        
        if let quiz = quiz {
            payload["quiz"] = quiz.toAPIPayload()
        }
        
        if let serverID = serverID {
            payload["serverID"] = serverID
        }
        
        if let etag = etag {
            payload["etag"] = etag
        }
        
        return payload
    }
    
    public static func fromAPIResponse(_ data: [String: Any]) -> Lesson? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let title = data["title"] as? String,
              let description = data["description"] as? String,
              let content = data["content"] as? String,
              let duration = data["duration"] as? TimeInterval,
              let order = data["order"] as? Int,
              let isCompleted = data["isCompleted"] as? Bool,
              let isLocked = data["isLocked"] as? Bool,
              let prerequisitesStrings = data["prerequisites"] as? [String],
              let createdAtString = data["createdAt"] as? String,
              let updatedAtString = data["updatedAt"] as? String,
              let createdAt = ISO8601DateFormatter().date(from: createdAtString),
              let updatedAt = ISO8601DateFormatter().date(from: updatedAtString),
              let version = data["version"] as? Int else {
            return nil
        }
        
        let prerequisites = prerequisitesStrings.compactMap { UUID(uuidString: $0) }
        let resourcesData = data["resources"] as? [[String: Any]] ?? []
        let resources = resourcesData.compactMap { LessonResource.fromAPIResponse($0) }
        
        var quiz: Quiz?
        if let quizData = data["quiz"] as? [String: Any] {
            quiz = Quiz.fromAPIResponse(quizData)
        }
        
        return Lesson(
            id: id,
            title: title,
            description: description,
            content: content,
            videoURL: data["videoURL"] as? String,
            audioURL: data["audioURL"] as? String,
            duration: duration,
            order: order,
            isCompleted: isCompleted,
            isLocked: isLocked,
            prerequisites: prerequisites,
            resources: resources,
            quiz: quiz,
            createdAt: createdAt,
            updatedAt: updatedAt,
            serverID: data["serverID"] as? String,
            syncStatus: SyncStatus(rawValue: data["syncStatus"] as? String ?? "") ?? .synced,
            lastSyncedAt: data["lastSyncedAt"] as? Date,
            version: version,
            etag: data["etag"] as? String
        )
    }
}

// MARK: - Lesson Resource
public struct LessonResource: Codable, Hashable, Identifiable {
    public let id: UUID
    public let name: String
    public let type: ResourceType
    public let url: String
    public let size: Int64? // in bytes
    public let isDownloaded: Bool
    public let createdAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        type: ResourceType,
        url: String,
        size: Int64? = nil,
        isDownloaded: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.url = url
        self.size = size
        self.isDownloaded = isDownloaded
        self.createdAt = createdAt
    }
    
    // Backend Integration Methods
    public func toAPIPayload() -> [String: Any] {
        var payload: [String: Any] = [
            "id": id.uuidString,
            "name": name,
            "type": type.rawValue,
            "url": url,
            "isDownloaded": isDownloaded,
            "createdAt": ISO8601DateFormatter().string(from: createdAt)
        ]
        
        if let size = size {
            payload["size"] = size
        }
        
        return payload
    }
    
    public static func fromAPIResponse(_ data: [String: Any]) -> LessonResource? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = data["name"] as? String,
              let typeString = data["type"] as? String,
              let type = ResourceType(rawValue: typeString),
              let url = data["url"] as? String,
              let isDownloaded = data["isDownloaded"] as? Bool,
              let createdAtString = data["createdAt"] as? String,
              let createdAt = ISO8601DateFormatter().date(from: createdAtString) else {
            return nil
        }
        
        return LessonResource(
            id: id,
            name: name,
            type: type,
            url: url,
            size: data["size"] as? Int64,
            isDownloaded: isDownloaded,
            createdAt: createdAt
        )
    }
}

public enum ResourceType: String, Codable, CaseIterable {
    case pdf = "pdf"
    case video = "video"
    case audio = "audio"
    case document = "document"
    case image = "image"
    case code = "code"
    case link = "link"
    case other = "other"
}

// MARK: - Quiz Model
public struct Quiz: Identifiable, Codable, Hashable, Syncable {
    public let id: UUID
    public let title: String
    public let description: String
    public let questions: [QuizQuestion]
    public let timeLimit: TimeInterval? // in seconds
    public let passingScore: Double // 0.0 to 1.0
    public let maxAttempts: Int
    public let isCompleted: Bool
    public let bestScore: Double?
    public let attempts: [QuizAttempt]
    public let createdAt: Date
    public let updatedAt: Date
    
    // Backend Integration Properties
    public let serverID: String?
    public let syncStatus: SyncStatus
    public let lastSyncedAt: Date?
    public let version: Int
    public let etag: String?
    
    public var needsSync: Bool {
        return syncStatus == .pending || syncStatus == .failed
    }
    
    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        questions: [QuizQuestion] = [],
        timeLimit: TimeInterval? = nil,
        passingScore: Double = 0.7,
        maxAttempts: Int = 3,
        isCompleted: Bool = false,
        bestScore: Double? = nil,
        attempts: [QuizAttempt] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        serverID: String? = nil,
        syncStatus: SyncStatus = .synced,
        lastSyncedAt: Date? = nil,
        version: Int = 1,
        etag: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.questions = questions
        self.timeLimit = timeLimit
        self.passingScore = passingScore
        self.maxAttempts = maxAttempts
        self.isCompleted = isCompleted
        self.bestScore = bestScore
        self.attempts = attempts
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.serverID = serverID
        self.syncStatus = syncStatus
        self.lastSyncedAt = lastSyncedAt
        self.version = version
        self.etag = etag
    }
    
    // Backend Integration Methods
    public func toAPIPayload() -> [String: Any] {
        var payload: [String: Any] = [
            "id": id.uuidString,
            "title": title,
            "description": description,
            "questions": questions.map { $0.toAPIPayload() },
            "passingScore": passingScore,
            "maxAttempts": maxAttempts,
            "isCompleted": isCompleted,
            "attempts": attempts.map { $0.toAPIPayload() },
            "createdAt": ISO8601DateFormatter().string(from: createdAt),
            "updatedAt": ISO8601DateFormatter().string(from: updatedAt),
            "version": version
        ]
        
        if let timeLimit = timeLimit {
            payload["timeLimit"] = timeLimit
        }
        
        if let bestScore = bestScore {
            payload["bestScore"] = bestScore
        }
        
        if let serverID = serverID {
            payload["serverID"] = serverID
        }
        
        if let etag = etag {
            payload["etag"] = etag
        }
        
        return payload
    }
    
    public static func fromAPIResponse(_ data: [String: Any]) -> Quiz? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let title = data["title"] as? String,
              let description = data["description"] as? String,
              let questionsData = data["questions"] as? [[String: Any]],
              let passingScore = data["passingScore"] as? Double,
              let maxAttempts = data["maxAttempts"] as? Int,
              let isCompleted = data["isCompleted"] as? Bool,
              let attemptsData = data["attempts"] as? [[String: Any]],
              let createdAtString = data["createdAt"] as? String,
              let updatedAtString = data["updatedAt"] as? String,
              let createdAt = ISO8601DateFormatter().date(from: createdAtString),
              let updatedAt = ISO8601DateFormatter().date(from: updatedAtString),
              let version = data["version"] as? Int else {
            return nil
        }
        
        let questions = questionsData.compactMap { QuizQuestion.fromAPIResponse($0) }
        let attempts = attemptsData.compactMap { QuizAttempt.fromAPIResponse($0) }
        
        return Quiz(
            id: id,
            title: title,
            description: description,
            questions: questions,
            timeLimit: data["timeLimit"] as? TimeInterval,
            passingScore: passingScore,
            maxAttempts: maxAttempts,
            isCompleted: isCompleted,
            bestScore: data["bestScore"] as? Double,
            attempts: attempts,
            createdAt: createdAt,
            updatedAt: updatedAt,
            serverID: data["serverID"] as? String,
            syncStatus: SyncStatus(rawValue: data["syncStatus"] as? String ?? "") ?? .synced,
            lastSyncedAt: data["lastSyncedAt"] as? Date,
            version: version,
            etag: data["etag"] as? String
        )
    }
}

// MARK: - Quiz Question
public struct QuizQuestion: Identifiable, Codable, Hashable {
    public let id: UUID
    public let question: String
    public let type: QuestionType
    public let options: [String]
    public let correctAnswer: String
    public let explanation: String?
    public let points: Int
    public let order: Int
    public let createdAt: Date
    
    public init(
        id: UUID = UUID(),
        question: String,
        type: QuestionType,
        options: [String],
        correctAnswer: String,
        explanation: String? = nil,
        points: Int = 1,
        order: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.question = question
        self.type = type
        self.options = options
        self.correctAnswer = correctAnswer
        self.explanation = explanation
        self.points = points
        self.order = order
        self.createdAt = createdAt
    }
    
    // Backend Integration Methods
    public func toAPIPayload() -> [String: Any] {
        var payload: [String: Any] = [
            "id": id.uuidString,
            "question": question,
            "type": type.rawValue,
            "options": options,
            "correctAnswer": correctAnswer,
            "points": points,
            "order": order,
            "createdAt": ISO8601DateFormatter().string(from: createdAt)
        ]
        
        if let explanation = explanation {
            payload["explanation"] = explanation
        }
        
        return payload
    }
    
    public static func fromAPIResponse(_ data: [String: Any]) -> QuizQuestion? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let question = data["question"] as? String,
              let typeString = data["type"] as? String,
              let type = QuestionType(rawValue: typeString),
              let options = data["options"] as? [String],
              let correctAnswer = data["correctAnswer"] as? String,
              let points = data["points"] as? Int,
              let order = data["order"] as? Int,
              let createdAtString = data["createdAt"] as? String,
              let createdAt = ISO8601DateFormatter().date(from: createdAtString) else {
            return nil
        }
        
        return QuizQuestion(
            id: id,
            question: question,
            type: type,
            options: options,
            correctAnswer: correctAnswer,
            explanation: data["explanation"] as? String,
            points: points,
            order: order,
            createdAt: createdAt
        )
    }
}

public enum QuestionType: String, Codable, CaseIterable {
    case multipleChoice = "multipleChoice"
    case trueFalse = "trueFalse"
    case shortAnswer = "shortAnswer"
    case essay = "essay"
    case fillInTheBlank = "fillInTheBlank"
}

// MARK: - Quiz Attempt
public struct QuizAttempt: Identifiable, Codable, Hashable {
    public let id: UUID
    public let startedAt: Date
    public let completedAt: Date?
    public let score: Double? // 0.0 to 1.0
    public let answers: [QuizAnswer]
    public let timeSpent: TimeInterval?
    public let isCompleted: Bool
    public let createdAt: Date
    
    public init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        completedAt: Date? = nil,
        score: Double? = nil,
        answers: [QuizAnswer] = [],
        timeSpent: TimeInterval? = nil,
        isCompleted: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.score = score
        self.answers = answers
        self.timeSpent = timeSpent
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
    
    // Backend Integration Methods
    public func toAPIPayload() -> [String: Any] {
        var payload: [String: Any] = [
            "id": id.uuidString,
            "startedAt": ISO8601DateFormatter().string(from: startedAt),
            "answers": answers.map { $0.toAPIPayload() },
            "isCompleted": isCompleted,
            "createdAt": ISO8601DateFormatter().string(from: createdAt)
        ]
        
        if let completedAt = completedAt {
            payload["completedAt"] = ISO8601DateFormatter().string(from: completedAt)
        }
        
        if let score = score {
            payload["score"] = score
        }
        
        if let timeSpent = timeSpent {
            payload["timeSpent"] = timeSpent
        }
        
        return payload
    }
    
    public static func fromAPIResponse(_ data: [String: Any]) -> QuizAttempt? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let startedAtString = data["startedAt"] as? String,
              let startedAt = ISO8601DateFormatter().date(from: startedAtString),
              let answersData = data["answers"] as? [[String: Any]],
              let isCompleted = data["isCompleted"] as? Bool,
              let createdAtString = data["createdAt"] as? String,
              let createdAt = ISO8601DateFormatter().date(from: createdAtString) else {
            return nil
        }
        
        let answers = answersData.compactMap { QuizAnswer.fromAPIResponse($0) }
        
        var completedAt: Date?
        if let completedAtString = data["completedAt"] as? String {
            completedAt = ISO8601DateFormatter().date(from: completedAtString)
        }
        
        return QuizAttempt(
            id: id,
            startedAt: startedAt,
            completedAt: completedAt,
            score: data["score"] as? Double,
            answers: answers,
            timeSpent: data["timeSpent"] as? TimeInterval,
            isCompleted: isCompleted,
            createdAt: createdAt
        )
    }
}

// MARK: - Quiz Answer
public struct QuizAnswer: Identifiable, Codable, Hashable {
    public let id: UUID
    public let questionId: UUID
    public let answer: String
    public let isCorrect: Bool
    public let timeSpent: TimeInterval?
    public let createdAt: Date
    
    public init(
        id: UUID = UUID(),
        questionId: UUID,
        answer: String,
        isCorrect: Bool,
        timeSpent: TimeInterval? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.questionId = questionId
        self.answer = answer
        self.isCorrect = isCorrect
        self.timeSpent = timeSpent
        self.createdAt = createdAt
    }
    
    // Backend Integration Methods
    public func toAPIPayload() -> [String: Any] {
        var payload: [String: Any] = [
            "id": id.uuidString,
            "questionId": questionId.uuidString,
            "answer": answer,
            "isCorrect": isCorrect,
            "createdAt": ISO8601DateFormatter().string(from: createdAt)
        ]
        
        if let timeSpent = timeSpent {
            payload["timeSpent"] = timeSpent
        }
        
        return payload
    }
    
    public static func fromAPIResponse(_ data: [String: Any]) -> QuizAnswer? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let questionIdString = data["questionId"] as? String,
              let questionId = UUID(uuidString: questionIdString),
              let answer = data["answer"] as? String,
              let isCorrect = data["isCorrect"] as? Bool,
              let createdAtString = data["createdAt"] as? String,
              let createdAt = ISO8601DateFormatter().date(from: createdAtString) else {
            return nil
        }
        
        return QuizAnswer(
            id: id,
            questionId: questionId,
            answer: answer,
            isCorrect: isCorrect,
            timeSpent: data["timeSpent"] as? TimeInterval,
            createdAt: createdAt
        )
    }
}

// MARK: - User Course Progress
public struct UserCourseProgress: Identifiable, Codable, Hashable {
    public let id: UUID
    public let courseId: String
    public let userId: String
    public let completedLessons: [String]
    public let completionPercentage: Double
    public let lastAccessedAt: Date
    public let timeSpent: TimeInterval
    
    public init(
        id: UUID = UUID(),
        courseId: String,
        userId: String,
        completedLessons: [String],
        completionPercentage: Double,
        lastAccessedAt: Date,
        timeSpent: TimeInterval
    ) {
        self.id = id
        self.courseId = courseId
        self.userId = userId
        self.completedLessons = completedLessons
        self.completionPercentage = completionPercentage
        self.lastAccessedAt = lastAccessedAt
        self.timeSpent = timeSpent
    }
}


