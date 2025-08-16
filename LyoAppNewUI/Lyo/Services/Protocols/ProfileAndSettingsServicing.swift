import Foundation

/// A protocol that defines the contract for a service that handles all data
/// for the Profile, Settings, and Moderation features.
public protocol ProfileAndSettingsServicing {

    // MARK: - Profile

    func getProfile(for userId: UUID) async throws -> UserProfile
    func updateProfile(_ updateRequest: UpdateProfileRequest) async throws -> UserProfile
    func followUser(userId: UUID) async throws
    func unfollowUser(userId: UUID) async throws

    // MARK: - Settings

    func getSettings() async throws -> UserSettings
    func updateSettings(_ settings: UserSettings) async throws -> UserSettings

    // MARK: - Moderation

    func reportContent(_ reportRequest: ReportContentRequest) async throws
}
