import Foundation

// MARK: - Request Models

public struct AwardXPRequest: Codable {
    let points: Int
    let reason: String
    let categoryId: String?
}

public struct UnlockAchievementRequest: Codable {
    let achievementId: String
}

public struct UpdateStreakRequest: Codable {
    let activityType: String
}

public struct JoinChallengeRequest: Codable {
    let challengeId: String
}

public struct UpdateChallengeProgressRequest: Codable {
    let challengeId: String
    let progress: Double
}

public struct AwardBadgeRequest: Codable {
    let badgeId: String
    let reason: String
}

// MARK: - Response Models

public struct UserXP: Codable {
    let totalXP: Int
    let currentLevel: Int
    let xpToNextLevel: Int
    let levelProgress: Double
    let recentAwards: [XPAward]
}

public struct XPAward: Codable {
    let id: String
    let points: Int
    let reason: String
    let categoryId: String?
    let awardedAt: Date
    let multiplier: Double
}

public struct StreakInfo: Codable {
    let activityType: StreakType
    let currentStreak: Int
    let longestStreak: Int
    let lastActivity: Date?
    let isActive: Bool
    let streakMultiplier: Double

    public enum StreakType: String, Codable {
        case daily = "daily"
        case weekly = "weekly"
        case learning = "learning"
        case engagement = "engagement"
    }
}

public typealias StreakType = StreakInfo.StreakType

public struct Leaderboard: Codable {
    let type: LeaderboardType
    let timeframe: TimeFrame
    let entries: [LeaderboardEntry]
    let totalParticipants: Int
    let lastUpdated: Date

    public enum LeaderboardType: String, Codable {
        case xp = "xp"
        case streak = "streak"
        case coursesCompleted = "courses_completed"
        case studyTime = "study_time"
        case achievements = "achievements"
    }
}

public typealias LeaderboardType = Leaderboard.LeaderboardType

public enum TimeFrame: String, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case allTime = "all_time"
}

public struct LeaderboardEntry: Codable {
    let rank: Int
    let userId: String
    let username: String
    let avatar: String?
    let score: Int
    let badge: String?
}

public struct UserRank: Codable {
    let rank: Int
    let score: Int
    let percentile: Double
    let nearbyUsers: [LeaderboardEntry]
}

public struct Challenge: Codable, Identifiable {
    public let id: String
    let title: String
    let description: String
    let category: String
    let difficulty: String
    let xpReward: Int
    let badgeReward: String?
    let startDate: Date
    let endDate: Date
    let targetValue: Int
    let participantCount: Int
    let isActive: Bool
    let imageURL: String?
}

public struct ChallengeParticipation: Codable {
    let challengeId: String
    let userId: String
    let progress: Double
    let currentValue: Int
    let isCompleted: Bool
    let joinedAt: Date
    let completedAt: Date?
}

public struct Badge: Codable, Identifiable {
    public let id: String
    let title: String
    let description: String
    let iconURL: String
    let rarity: BadgeRarity
    let category: String
    let earnedAt: Date?
    let isEarned: Bool

    public enum BadgeRarity: String, Codable {
        case common = "common"
        case uncommon = "uncommon"
        case rare = "rare"
        case epic = "epic"
        case legendary = "legendary"
    }
}

// Achievement is now defined in AppModels.swift

public struct StudyAnalytics: Codable {
    let totalTime: TimeInterval
    let averageSessionTime: TimeInterval
    let sessionsCount: Int
    let topCategories: [CategoryTime]
    let dailyProgress: [DailyProgress]
    let weeklyGoal: Int
    let weeklyProgress: Int
}

public struct CategoryTime: Codable {
    let category: String
    let timeSpent: TimeInterval
    let percentage: Double
}

public struct DailyProgress: Codable {
    let date: Date
    let timeSpent: TimeInterval
    let lessonsCompleted: Int
    let xpEarned: Int
}

public struct FeatureUsage: Codable {
    let featureName: String
    let usageCount: Int
    let timeSpent: TimeInterval
}
