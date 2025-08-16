import Foundation

/// The live implementation of the `NotificationServicing` protocol.
/// This class uses an `HTTPClient` to fetch notification data from the backend.
public final class NotificationService: NotificationServicing {

    private let httpClient: HTTPClienting

    public init(httpClient: HTTPClienting) {
        self.httpClient = httpClient
    }

    public func fetchNotifications() async throws -> [Notification] {
        let endpoint = NotificationEndpoint.getNotifications()
        return try await httpClient.request(endpoint)
    }
}
