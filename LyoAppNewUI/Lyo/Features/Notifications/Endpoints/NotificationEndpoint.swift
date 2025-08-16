import Foundation

/// A namespace for creating API endpoints related to Notifications.
enum NotificationEndpoint {

    /// Creates an endpoint to fetch all of the current user's notifications.
    /// - Returns: An `Endpoint` configured to fetch an array of `Notification` objects.
    static func getNotifications() -> Endpoint<[Notification]> {
        return Endpoint(path: "/v1/notifications", method: .get)
    }
}
