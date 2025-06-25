import Foundation
import Combine

// MARK: - Gamification API Service
@MainActor
class GamificationAPIService: APIService {
    static let shared = GamificationAPIService()

    // MARK: - XP and Levels
    func getUserXP() async throws -> UserXP {
        let endpoint = Endpoint(path: "/analytics/xp")
        return try await apiClient.request(endpoint)
    }

    func awardXP(points: Int, reason: String, categoryId: String? = nil) async throws -> XPAward {
        let request = AwardXPRequest(
            points: points,
            reason: reason,
            categoryId: categoryId
        )
        let endpoint = Endpoint(path: "/analytics/xp/award", method: .post, body: request)
        return try await apiClient.request(endpoint)
    }

    // MARK: - Achievements
    func getUserAchievements() async throws -> [Achievement] {
        let endpoint = Endpoint(path: "/achievements")
        return try await apiClient.request(endpoint)
    }

    func unlockAchievement(_ achievementId: String) async throws -> Achievement {
        let request = UnlockAchievementRequest(achievementId: achievementId)
        let endpoint = Endpoint(path: "/achievements/unlock", method: .post, body: request)
        return try await apiClient.request(endpoint)
    }

    func getAvailableAchievements() async throws -> [Achievement] {
        let endpoint = Endpoint(path: "/achievements/available")
        return try await apiClient.request(endpoint)
    }

    // MARK: - Streaks
    func updateStreak(activityType: StreakType) async throws -> StreakInfo {
        let request = UpdateStreakRequest(activityType: activityType.rawValue)
        let endpoint = Endpoint(path: "/analytics/streak", method: .post, body: request)
        return try await apiClient.request(endpoint)
    }

    func getStreak(for activityType: StreakType) async throws -> StreakInfo {
        let endpoint = Endpoint(path: "/analytics/streak/\(activityType.rawValue)")
        return try await apiClient.request(endpoint)
    }

    // MARK: - Leaderboards
    func getLeaderboard(type: LeaderboardType, timeframe: TimeFrame) async throws -> Leaderboard {
        let endpoint = Endpoint(path: "/leaderboard/\(type.rawValue)?timeframe=\(timeframe.rawValue)")
        return try await apiClient.request(endpoint)
    }

    func getUserRank(type: LeaderboardType, timeframe: TimeFrame) async throws -> UserRank {
        let endpoint = Endpoint(path: "/leaderboard/\(type.rawValue)/rank?timeframe=\(timeframe.rawValue)")
        return try await apiClient.request(endpoint)
    }

    // MARK: - Challenges
    func getActiveChallenges() async throws -> [Challenge] {
        let endpoint = Endpoint(path: "/community/challenges")
        return try await apiClient.request(endpoint)
    }

    func joinChallenge(_ challengeId: String) async throws -> ChallengeParticipation {
        let request = JoinChallengeRequest(challengeId: challengeId)
        let endpoint = Endpoint(path: "/community/challenges/\(challengeId)/join", method: .post, body: request)
        return try await apiClient.request(endpoint)
    }

    func updateChallengeProgress(_ challengeId: String, progress: Double) async throws -> ChallengeParticipation {
        let request = UpdateChallengeProgressRequest(
            challengeId: challengeId,
            progress: progress
        )
        let endpoint = Endpoint(path: "/community/challenges/\(challengeId)/progress", method: .put, body: request)
        return try await apiClient.request(endpoint)
    }

    // MARK: - Badges
    func getUserBadges() async throws -> [Badge] {
        let endpoint = Endpoint(path: "/achievements/badges")
        return try await apiClient.request(endpoint)
    }

    func awardBadge(_ badgeId: String, reason: String) async throws -> Badge {
        let request = AwardBadgeRequest(
            badgeId: badgeId,
            reason: reason
        )
        let endpoint = Endpoint(path: "/achievements/badges/award", method: .post, body: request)
        return try await apiClient.request(endpoint)
    }
}
