import SwiftUI

struct NotificationsView: View {

    @StateObject private var viewModel: NotificationsViewModel
    @EnvironmentObject private var router: Router

    init(viewModel: NotificationsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        // The RootView will provide the NavigationStack
        content
            .navigationTitle("Notifications")
            .onAppear {
                if viewModel.notifications.isEmpty {
                    viewModel.fetchNotifications()
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .loading:
            List {
                ForEach(0..<10) { _ in
                    NotificationRowView(notification: .placeholder)
                        .redacted(reason: .placeholder)
                }
            }
            .listStyle(.plain)
        case .loaded:
            List(viewModel.notifications) { notification in
                Button(action: {
                    if let deepLink = notification.deepLink {
                        router.handle(urlString: deepLink)
                    }
                }) {
                    NotificationRowView(notification: notification)
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
        case .empty:
            EmptyStateView(
                image: Image(systemName: "bell.slash.fill"),
                title: "No Notifications",
                description: "You're all caught up!"
            )
        case .error:
            EmptyStateView(
                image: Image(systemName: "wifi.slash"),
                title: "Couldn't Load Notifications",
                description: "Please check your connection and try again.",
                actionView: {
                    Button("Retry", action: viewModel.fetchNotifications)
                        .buttonStyle(.borderedProminent)
                }
            )
        }
    }
}

// MARK: - Notification Row View

private struct NotificationRowView: View {
    let notification: Notification

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: notification.type.iconName)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading) {
                Text(notification.text)
                    .font(.body)
                Text(notification.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Helpers

extension Notification.NotificationType {
    var iconName: String {
        switch self {
        case .newMessage, .tutorMessage:
            return "message.fill"
        case .newFollower:
            return "person.fill.checkmark"
        case .postLike:
            return "heart.fill"
        case .postComment:
            return "bubble.left.fill"
        }
    }
}

extension Notification {
    static var placeholder: Notification {
        .init(id: UUID(), type: .newMessage, text: "This is a placeholder notification message.", timestamp: Date(), deepLink: nil)
    }
}
