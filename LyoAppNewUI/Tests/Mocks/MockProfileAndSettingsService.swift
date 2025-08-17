import Foundation
@testable import LyoApp

final class MockProfileAndSettingsService: ProfileAndSettingsServicing {

    // MARK: - Profile
    var profileResult: Result<UserProfile, APIError> = .failure(.unauthorized)
    var updateProfileResult: Result<UserProfile, APIError> = .failure(.unauthorized)
    var followError: APIError?
    var unfollowError: APIError?

    private(set) var getProfileCallCount = 0
    private(set) var updateProfileCallCount = 0
    private(set) var followUserCallCount = 0
    private(set) var unfollowUserCallCount = 0

    func getProfile(for userId: UUID) async throws -> UserProfile {
        getProfileCallCount += 1
        return try profileResult.get()
    }

    func updateProfile(_ updateRequest: UpdateProfileRequest) async throws -> UserProfile {
        updateProfileCallCount += 1
        return try updateProfileResult.get()
    }

    func followUser(userId: UUID) async throws {
        followUserCallCount += 1
        if let error = followError { throw error }
    }

    func unfollowUser(userId: UUID) async throws {
        unfollowUserCallCount += 1
        if let error = unfollowError { throw error }
    }

    // MARK: - Settings
    var settingsResult: Result<UserSettings, APIError> = .failure(.unauthorized)
    var updateSettingsResult: Result<UserSettings, APIError> = .failure(.unauthorized)

    private(set) var getSettingsCallCount = 0
    private(set) var updateSettingsCallCount = 0

    func getSettings() async throws -> UserSettings {
        getSettingsCallCount += 1
        return try settingsResult.get()
    }

    func updateSettings(_ settings: UserSettings) async throws -> UserSettings {
        updateSettingsCallCount += 1
        return try updateSettingsResult.get()
    }

    // MARK: - Moderation
    var reportContentError: APIError?
    private(set) var reportContentCallCount = 0

    func reportContent(_ reportRequest: ReportContentRequest) async throws {
        reportContentCallCount += 1
        if let error = reportContentError { throw error }
    }
}
