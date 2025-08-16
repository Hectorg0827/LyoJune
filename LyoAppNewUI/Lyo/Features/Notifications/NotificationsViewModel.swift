import Foundation

@MainActor
final class NotificationsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var notifications: [Notification] = []
    @Published private(set) var viewState: ViewState = .loading

    // MARK: - Private Properties

    private let notificationService: NotificationServicing

    // MARK: - Initialization

    init(notificationService: NotificationServicing) {
        self.notificationService = notificationService
    }

    // MARK: - Public Intent Methods

    /// Fetches the list of notifications from the backend.
    func fetchNotifications() {
        if notifications.isEmpty {
            viewState = .loading
        }

        Task {
            do {
                let fetchedNotifications = try await notificationService.fetchNotifications()
                self.notifications = fetchedNotifications
                self.viewState = fetchedNotifications.isEmpty ? .empty : .loaded
            } catch {
                self.viewState = .error
            }
        }
    }
}

// MARK: - View State Enum

extension NotificationsViewModel {
    /// An enum to represent the different states of the view.
    enum ViewState {
        case loading
        case loaded
        case empty
        case error
    }
}
