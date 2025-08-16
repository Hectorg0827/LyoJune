import SwiftUI

struct ThreadsListView: View {

    @StateObject private var viewModel: ThreadsListViewModel

    // In a real app, the dependencies for the ChatView would be passed down
    // from a higher-level coordinator or factory.
    private let messagingService: MessagingServicing
    private let webSocketService: WebSocketServicing

    init(
        viewModel: ThreadsListViewModel,
        messagingService: MessagingServicing,
        webSocketService: WebSocketServicing
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.messagingService = messagingService
        self.webSocketService = webSocketService
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Messages")
                .onAppear {
                    if viewModel.threads.isEmpty {
                        viewModel.fetchThreads()
                    }
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
                // This is where we create the dependencies for the next screen.
                let chatViewModel = ChatViewModel(
                    chatId: thread.id,
                    messagingService: messagingService,
                    webSocketService: webSocketService
                )
                NavigationLink(destination: ChatView(viewModel: chatViewModel)) {
                    ThreadRowView(thread: thread)
                }
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
