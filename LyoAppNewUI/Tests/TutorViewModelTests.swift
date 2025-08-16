import XCTest
@testable import LyoApp

@MainActor
final class TutorViewModelTests: XCTestCase {

    private var sut: TutorViewModel!
    private var mockTutorService: MockTutorService!

    override func setUp() {
        super.setUp()
        mockTutorService = MockTutorService()
        sut = TutorViewModel(tutorService: mockTutorse)
    }

    override func tearDown() {
        sut = nil
        mockTutorService = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_loadInitialState_onSuccess_populatesMessages() async {
        // Given
        let history: [TutorMessage] = [
            .init(id: UUID(), sender: .user, type: .text, text: "Hello", question: nil)
        ]
        mockTutorService.getStateResult = .success(.init(learnerId: "test", history: history))

        // When
        sut.loadInitialState()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockTutorService.getStateCallCount, 1)
        XCTAssertEqual(sut.messages.count, 1)
        XCTAssertEqual(sut.messages.first?.text, "Hello")
    }

    func test_loadInitialState_onFailure_showsWelcomeMessage() async {
        // Given
        mockTutorService.getStateResult = .failure(.unauthorized)

        // When
        sut.loadInitialState()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockTutorService.getStateCallCount, 1)
        XCTAssertEqual(sut.messages.count, 1)
        XCTAssertEqual(sut.messages.first?.sender, .tutor)
        XCTAssertEqual(sut.messages.first?.text, "Hello! What would you like to learn about today?")
    }

    func test_sendMessage_onSuccess_optimisticallyUpdatesMessagesAndAppendsResponse() async {
        // Given
        let responseMessage = TutorMessage(id: UUID(), sender: .tutor, type: .text, text: "Response", question: nil)
        mockTutorService.postTurnResult = .success([responseMessage])

        // When
        sut.sendMessage("Test message")

        // Then (Optimistic UI)
        XCTAssertEqual(sut.messages.count, 1)
        XCTAssertEqual(sut.messages.last?.sender, .user)
        XCTAssertEqual(sut.messages.last?.text, "Test message")

        // After async
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(mockTutorService.postTurnCallCount, 1)
        XCTAssertEqual(sut.messages.count, 2)
        XCTAssertEqual(sut.messages.last?.text, "Response")
        XCTAssertFalse(sut.isSending)
    }

    func test_sendMessage_onFailure_setsErrorToast() async {
        // Given
        mockTutorService.postTurnResult = .failure(.serverError(message: "Tutor offline"))

        // When
        sut.sendMessage("Test")
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockTutorService.postTurnCallCount, 1)
        XCTAssertEqual(sut.messages.count, 1) // Only the user's message should be present
        XCTAssertNotNil(sut.errorToast)
        XCTAssertFalse(sut.isSending)
    }

    func test_answerQuestion_callsPostTurnWithCorrectOptionId() async {
        // Given
        let question = Question.placeholder
        let selectedOption = question.options[1]

        // When
        sut.answerQuestion(questionId: question.id, option: selectedOption)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockTutorService.postTurnCallCount, 1)
        XCTAssertEqual(mockTutorService.lastPostTurnOptionId, selectedOption.id)
        XCTAssertEqual(mockTutorService.lastPostTurnText, selectedOption.text)
    }
}

extension Question {
    static var placeholder: Question {
        .init(
            id: UUID(),
            text: "Placeholder",
            options: [
                .init(id: "A", text: "Option A"),
                .init(id: "B", text: "Option B")
            ]
        )
    }
}
