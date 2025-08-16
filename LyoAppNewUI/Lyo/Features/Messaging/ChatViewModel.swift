import Foundation
import Combine

@MainActor
final class ChatViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var viewState: ViewState = .loading

    // MARK: - Private Properties

    private let chatId: String
    private let messagingService: MessagingServicing
    private let webSocketService: WebSocketServicing

    // MARK: - Initialization

    init(
        chatId: String,
        messagingService: MessagingServicing,
        webSocketService: WebSocketServicing
    ) {
        self.chatId = chatId
        self.messagingService = messagingService
        self.webSocketService = webSocketService
    }

    // MARK: - Public Intent Methods

    func connectAndFetchHistory() {
        viewState = .loading

        // Fetch initial history via REST
        Task {
            do {
                let history = try await messagingService.fetchHistory(for: chatId)
                self.messages = history
                self.viewState = .loaded
            } catch {
                self.viewState = .error
            }
        }

        // Connect to WebSocket for real-time messages
        webSocketService.connect(chatId: chatId)

        // Subscribe to the incoming message stream
        Task {
            do {
                for try await message in webSocketService.messages {
                    // This assumes the sender is not the current user.
                    // A real app would check the sender ID.
                    messages.append(message)
                }
            } catch {
                print("WebSocket stream finished with error: \(error)")
            }
        }
    }

    func sendMessage(_ text: String) {
        Task {
            do {
                try await webSocketService.sendMessage(text)
                // In a real app, the server would echo back the message via the WebSocket
                // and we would append it upon receiving it, not here.
                // For optimistic UI, you could add it here with a "sending" state.
            } catch {
                // Handle send failure
            }
        }
    }

    func disconnect() {
        webSocketService.disconnect()
    }

    deinit {
        disconnect()
    }
}

// MARK: - View State Enum

extension ChatViewModel {
    enum ViewState {
        case loading, loaded, error
    }
}
