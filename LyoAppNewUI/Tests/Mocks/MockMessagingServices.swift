import Foundation
@testable import LyoApp

// MARK: - Mock REST Service

final class MockMessagingService: MessagingServicing {
    var threadsResult: Result<[ChatThread], APIError> = .success([])
    var historyResult: Result<[ChatMessage], APIError> = .success([])

    private(set) var fetchThreadsCallCount = 0
    private(set) var fetchHistoryCallCount = 0

    func fetchThreads() async throws -> [ChatThread] {
        fetchThreadsCallCount += 1
        return try threadsResult.get()
    }

    func fetchHistory(for chatId: String) async throws -> [ChatMessage] {
        fetchHistoryCallCount += 1
        return try historyResult.get()
    }
}


// MARK: - Mock WebSocket Service

final class MockWebSocketService: WebSocketServicing {

    // The continuation can be used to manually yield or finish the stream from a test.
    var messageContinuation: AsyncThrowingStream<ChatMessage, Error>.Continuation?

    lazy var messages: AsyncThrowingStream<ChatMessage, Error> = {
        AsyncThrowingStream { self.messageContinuation = $0 }
    }()

    private(set) var connectCallCount = 0
    private(set) var lastConnectedChatId: String?

    private(set) var disconnectCallCount = 0

    private(set) var sendMessageCallCount = 0
    private(set) var lastSentMessage: String?
    var sendMessageError: Error?

    func connect(chatId: String) {
        connectCallCount += 1
        lastConnectedChatId = chatId
    }

    func disconnect() {
        disconnectCallCount += 1
        messageContinuation?.finish()
    }

    func sendMessage(_ text: String) async throws {
        sendMessageCallCount += 1
        lastSentMessage = text
        if let error = sendMessageError {
            throw error
        }
    }
}
