import SwiftUI

struct ThreadsListView: View {

    @StateObject private var viewModel: ThreadsListViewModel
    @EnvironmentObject private var router: Router

    // The services are no longer needed here, as the Router constructs the destination view.

    init(viewModel: ThreadsListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        // The NavigationStack is now provided by the RootView
        content
            .navigationTitle("Messages")
            .onAppear {
                if viewModel.threads.isEmpty {
                    viewModel.fetchThreads()
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .loading:
            List {
                ForEach(0..<8) { _ in
                    ThreadRowView(thread: .placeholder)
                        .redacted(reason: .placeholder)
                }
            }
            .listStyle(.plain)

        case .loaded:
            List(viewModel.threads) { thread in
                Button(action: {
                    router.navigate(to: .chat(chatId: thread.id))
                }) {
                    ThreadRowView(thread: thread)
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)

        case .empty:
            EmptyStateView(
                image: Image(systemName: "message.fill"),
                title: "No Messages Yet",
                description: "Start a new conversation to see it here."
            )

        case .error:
            EmptyStateView(
                image: Image(systemName: "wifi.slash"),
                title: "An Error Occurred",
                description: "We couldn't load your messages.",
                actionView: {
                    Button("Retry", action: viewModel.fetchThreads)
                        .buttonStyle(.borderedProminent)
                }
            )
        }
    }
}

extension ChatThread {
    static var placeholder: ChatThread {
        .init(
            id: "placeholder",
            participants: [.init(id: UUID(), username: "username", profileImageURL: nil)],
            lastMessage: .init(id: UUID(), sender: .init(id: UUID(), username: "", profileImageURL: nil), text: "This is a placeholder message text.", timestamp: Date())
        )
    }
}
