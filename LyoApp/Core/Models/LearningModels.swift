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
    let id: String
    let postId: String
    let authorId: String
    let authorName: String
    let authorAvatar: String?
    let content: String
    let createdAt: Date
    let likesCount: Int
    let isLiked: Bool
}