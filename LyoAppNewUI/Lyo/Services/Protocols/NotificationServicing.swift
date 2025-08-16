import Foundation

/// A protocol that defines the contract for a service that fetches notifications.
public protocol NotificationServicing {

    /// Asynchronously fetches all notifications for the current user.
    /// - Returns: An array of `Notification` objects.
    /// - Throws: An `APIError` if the network request or decoding fails.
    func fetchNotifications() async throws -> [Notification]
}
