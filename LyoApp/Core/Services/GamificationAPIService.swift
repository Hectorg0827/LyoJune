import Foundation
import Combine

// MARK: - Local Type Definitions for Gamification API
public enum GamificationAPI {
    public struct UserXP: Codable {
        public let totalXP: Int
        public let level: Int
        public let xpToNextLevel: Int
        public let currentLevelXP: Int
    }
    
    public struct XPAward: Codable {
        public let points: Int
        public let reason: String
        public let totalXP: Int
        public let newLevel: Int?
    }
    
    public struct Achievement: Codable, Identifiable {
        public let id: String
        public let title: String
        public let description: String
        public let iconName: String
        public let isUnlocked: Bool
        public let unlockedAt: Date?
        public let xpReward: Int
    }
    
    public struct StreakInfo: Codable {
        public let currentStreak: Int
        public let longestStreak: Int
        public let lastActivityDate: Date
        public let type: StreakType
    }
    
    public enum StreakType: String, Codable {
        case dailyLogin = "daily_login"
        case lessonsCompleted = "lessons_completed"
        case quizzesCompleted = "quizzes_completed"
    }
    
    public struct Leaderboard: Codable {
        public let entries: [LeaderboardEntry]
        public let type: LeaderboardType
        public let timeframe: TimeFrame
        public let userRank: Int?
    }
    
    public struct LeaderboardEntry: Codable {
        public let rank: Int
        public let userId: String
        public let username: String
        public let score: Int
        public let avatarURL: String?
    }
    
    public enum LeaderboardType: String, Codable {
        case xp = "xp"
        case streaks = "streaks"
        case achievements = "achievements"
    }
    
    public enum TimeFrame: String, Codable {
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        case allTime = "all_time"
    }
    
    public struct UserRank: Codable {
        public let rank: Int
        public let score: Int
        public let totalUsers: Int
        public let percentile: Double
    }
    
    public struct Challenge: Codable, Identifiable {
        public let id: String
        public let title: String
        public let description: String
        public let startDate: Date
        public let endDate: Date
        public let xpReward: Int
        public let participants: Int
        public let isActive: Bool
    }
    
    public struct ChallengeParticipation: Codable {
        public let challengeId: String
        public let progress: Double
        public let isCompleted: Bool
        public let joinedAt: Date
        public let completedAt: Date?
    }
    
    public struct Badge: Codable, Identifiable {
        public let id: String
        public let name: String
        public let description: String
        public let iconName: String
        public let rarity: BadgeRarity
        public let earnedAt: Date?
    }
    
    public enum BadgeRarity: String, Codable {
        case common = "common"
        case rare = "rare"
        case epic = "epic"
        case legendary = "legendary"
    }
}

// MARK: - Gamification API Service
@MainActor
class GamificationAPIService {
    static let shared = GamificationAPIService()
    
    private let networkManager: EnhancedNetworkManager
    
    private init(networkManager: EnhancedNetworkManager = EnhancedNetworkManager.shared) {
        self.networkManager = networkManager
    }

    // MARK: - XP and Levels
    func getUserXP() async throws -> GamificationAPI.UserXP {
        return try await networkManager.get(endpoint: "/analytics/xp")
    }

    func awardXP(points: Int, reason: String, categoryId: String? = nil) async throws -> GamificationAPI.XPAward {
        let request = AwardXPRequest(
            points: points,
            reason: reason,
            categoryId: categoryId
        )
        return try await networkManager.post("/analytics/xp/award", body: request)
    }

    // MARK: - Achievements
    func getUserAchievements() async throws -> [GamificationAPI.Achievement] {
        return try await networkManager.get(endpoint: "/gamification/achievements/user")
    }

    func unlockAchievement(_ achievementId: String) async throws -> GamificationAPI.Achievement {
        let request = UnlockAchievementRequest(achievementId: achievementId)
        return try await networkManager.post("/gamification/achievements/\(achievementId)/unlock", body: request)
    }

    func getAvailableAchievements() async throws -> [GamificationAPI.Achievement] {
        return try await networkManager.get(endpoint: "/gamification/achievements/available")
    }

    // MARK: - Streaks
    func updateStreak(activityType: GamificationAPI.StreakType) async throws -> GamificationAPI.StreakInfo {
        let request = UpdateStreakRequest(activityType: activityType)
        return try await networkManager.post("/gamification/streaks/update", body: request)
    }

    func getStreak(for activityType: GamificationAPI.StreakType) async throws -> GamificationAPI.StreakInfo {
        return try await networkManager.get("/gamification/streaks/\(activityType.rawValue)")
    }

    // MARK: - Leaderboards
    func getLeaderboard(type: GamificationAPI.LeaderboardType, timeframe: GamificationAPI.TimeFrame) async throws -> GamificationAPI.Leaderboard {
        return try await networkManager.get("/gamification/leaderboard/\(type.rawValue)/\(timeframe.rawValue)")
    }

    func getUserRank(type: GamificationAPI.LeaderboardType, timeframe: GamificationAPI.TimeFrame) async throws -> GamificationAPI.UserRank {
        return try await networkManager.get("/gamification/leaderboard/\(type.rawValue)/\(timeframe.rawValue)/rank")
    }

    // MARK: - Challenges
    func getActiveChallenges() async throws -> [GamificationAPI.Challenge] {
        return try await networkManager.get("/gamification/challenges/active")
    }

    func joinChallenge(_ challengeId: String) async throws -> GamificationAPI.ChallengeParticipation {
        let request = JoinChallengeRequest(challengeId: challengeId)
        return try await networkManager.post("/gamification/challenges/\(challengeId)/join", body: request)
    }

    func updateChallengeProgress(_ challengeId: String, progress: Double) async throws -> GamificationAPI.ChallengeParticipation {
        let request = UpdateChallengeProgressRequest(challengeId: challengeId, progress: progress)
        return try await networkManager.put("/gamification/challenges/\(challengeId)/progress", body: request)
    }

    // MARK: - Badges
    func getUserBadges() async throws -> [GamificationAPI.Badge] {
        return try await networkManager.get("/gamification/badges/user")
    }

    func awardBadge(_ badgeId: String, reason: String) async throws -> GamificationAPI.Badge {
        let request = AwardBadgeRequest(badgeId: badgeId, reason: reason)
        return try await networkManager.post("/gamification/badges/\(badgeId)/award", body: request)
    }
}

// MARK: - Request Types
private struct AwardXPRequest: Codable {
    let points: Int
    let reason: String
    let categoryId: String?
}

private struct UnlockAchievementRequest: Codable {
    let achievementId: String
}

private struct UpdateStreakRequest: Codable {
    let activityType: GamificationAPI.StreakType
}

private struct JoinChallengeRequest: Codable {
    let challengeId: String
}

private struct UpdateChallengeProgressRequest: Codable {
    let challengeId: String
    let progress: Double
}

private struct AwardBadgeRequest: Codable {
    let badgeId: String
    let reason: String
}
