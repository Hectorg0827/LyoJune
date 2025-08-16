import Foundation
@testable import LyoApp

final class MockNotificationService: NotificationServicing {

    var notificationsResult: Result<[Notification], APIError> = .success([])
    private(set) var fetchNotificationsCallCount = 0

    func fetchNotifications() async throws -> [Notification] {
        fetchNotificationsCallCount += 1
        return try notificationsResult.get()
    }
}
