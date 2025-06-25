import Foundation

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