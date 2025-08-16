import Foundation

/// A namespace for creating API endpoints related to User Settings.
enum SettingsEndpoint {

    /// Creates an endpoint to fetch the current user's settings.
    /// - Returns: An `Endpoint` configured to fetch a `UserSettings` object.
    static func getSettings() -> Endpoint<UserSettings> {
        return Endpoint(path: "/v1/settings", method: .get)
    }

    /// Creates an endpoint to update the current user's settings.
    /// - Parameter settings: The `UserSettings` object with the new values.
    /// - Returns: An `Endpoint` configured to fetch the updated `UserSettings`.
    static func updateSettings(_ settings: UserSettings) -> Endpoint<UserSettings> {
        return try! Endpoint(
            path: "/v1/settings",
            method: .put,
            encodableBody: settings
        )
    }
}
