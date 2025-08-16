import Foundation

/// The live implementation of the `ProfileAndSettingsServicing` protocol.
public final class ProfileAndSettingsService: ProfileAndSettingsServicing {

    private let httpClient: HTTPClienting

    public init(httpClient: HTTPClienting) {
        self.httpClient = httpClient
    }

    // MARK: - Profile

    public func getProfile(for userId: UUID) async throws -> UserProfile {
        let endpoint = ProfileEndpoint.getProfile(for: userId)
        return try await httpClient.request(endpoint)
    }

    public func updateProfile(_ updateRequest: UpdateProfileRequest) async throws -> UserProfile {
        let endpoint = ProfileEndpoint.updateProfile(updateRequest)
        return try await httpClient.request(endpoint)
    }

    public func followUser(userId: UUID) async throws {
        let endpoint = ProfileEndpoint.followUser(userId: userId)
        _ = try await httpClient.request(endpoint)
    }

    public func unfollowUser(userId: UUID) async throws {
        let endpoint = ProfileEndpoint.unfollowUser(userId: userId)
        _ = try await httpClient.request(endpoint)
    }

    // MARK: - Settings

    public func getSettings() async throws -> UserSettings {
        let endpoint = SettingsEndpoint.getSettings()
        return try await httpClient.request(endpoint)
    }

    public func updateSettings(_ settings: UserSettings) async throws -> UserSettings {
        let endpoint = SettingsEndpoint.updateSettings(settings)
        return try await httpClient.request(endpoint)
    }

    // MARK: - Moderation

    public func reportContent(_ reportRequest: ReportContentRequest) async throws {
        let endpoint = ModerationEndpoint.reportContent(reportRequest)
        _ = try await httpClient.request(endpoint)
    }
}
