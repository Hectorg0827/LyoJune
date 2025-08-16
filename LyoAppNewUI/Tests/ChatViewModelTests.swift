import XCTest
@testable import LyoApp

@MainActor
final class ChatViewModelTests: XCTestCase {

    private var sut: ChatViewModel!
    private var mockMessagingService: MockMessagingService!
    private var mockWebSocketService: MockWebSocketService!
    private let testChatId = "chat-123"

    override func setUp() {
        super.setUp()
        mockMessagingService = MockMessagingService()
        mockWebSocketService = MockWebSocketService()
        sut = ChatViewModel(
            chatId: testChatId,
            messagingService: mockMessagingService,
            webSocketService: mockWebSocketService
        )
    }

    override func tearDown() {
        sut = nil
        mockMessagingService = nil
        mockWebSocketService = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_connectAndFetchHistory_callsServicesAndLoadsHistory() async {
        // Given
        let history: [ChatMessage] = [.init(id: UUID(), sender: .init(id: UUID(), username: "test", profileImageURL: nil), text: "History", timestamp: Date())]
        mockMessagingService.historyResult = .success(history)

        // When
        sut.connectAndFetchHistory()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockMessagingService.fetchHistoryCallCount, 1)
        XCTAssertEqual(mockWebSocketService.connectCallCount, 1)
        XCTAssertEqual(mockWebSocketService.lastConnectedChatId, testChatId)
        XCTAssertEqual(sut.messages.count, 1)
        XCTAssertEqual(sut.messages.first?.text, "History")
        XCTAssertEqual(sut.viewState, .loaded)
    }

    func test_webSocketMessage_isAppendedToMessages() async {
        // Given
        let incomingMessage = ChatMessage(id: UUID(), sender: .init(id: UUID(), username: "other", profileImageURL: nil), text: "Real-time message", timestamp: Date())

        // When
        sut.connectAndFetchHistory() // Connects and starts listening
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Simulate a message arriving from the WebSocket
        mockWebSocketService.messageContinuation?.yield(incomingMessage)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.messages.count, 1) // 0 from history + 1 from WebSocket
        XCTAssertEqual(sut.messages.last?.text, "Real-time message")
    }

    func test_sendMessage_callsWebSocketService() async {
        // Given
        let messageText = "Hello, world!"

        // When
        sut.sendMessage(messageText)

        // Then
        XCTAssertEqual(mockWebSocketService.sendMessageCallCount, 1)
        XCTAssertEqual(mockWebSocketService.lastSentMessage, messageText)
    }

    func test_disconnect_callsWebSocketService() {
        // When
        sut.disconnect()

        // Then
        XCTAssertEqual(mockWebSocketService.disconnectCallCount, 1)
    }
}
