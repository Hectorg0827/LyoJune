import XCTest
@testable import LyoApp

@MainActor
final class TutorViewModel_VoiceTests: XCTestCase {

    private var sut: TutorViewModel!
    private var mockTutorService: MockTutorService!
    private var mockAIGeneratorService: MockAIGeneratorService!
    private var mockSpeechService: MockSpeechRecognitionService!
    private var mockOnDeviceAIService: MockOnDeviceAIService!
    private var mockRouter: MockRouter!
    private var mockAICoordinator: MockAICoordinator!

    override func setUp() {
        super.setUp()
        mockTutorService = MockTutorService()
        mockAIGeneratorService = MockAIGeneratorService()
        mockSpeechService = MockSpeechRecognitionService()
        mockOnDeviceAIService = MockOnDeviceAIService()
        mockRouter = MockRouter()
        mockAICoordinator = MockAICoordinator()

        sut = TutorViewModel(
            tutorService: mockTutorService,
            aiGeneratorService: mockAIGeneratorService,
            speechService: mockSpeechService,
            onDeviceAIService: mockOnDeviceAIService,
            router: mockRouter,
            aiCoordinator: mockAICoordinator
        )
    }

    // MARK: - Tests

    func test_toggleListening_whenStarting_callsStartListening() {
        // When
        sut.toggleListening() // Turn on

        // Then
        XCTAssertTrue(sut.isListening)
        XCTAssertEqual(mockSpeechService.startListeningCallCount, 1)
    }

    func test_stopListening_withTranscript_sendsToOnDeviceAIForIntent() async {
        // Given
        sut.liveTranscript = "generate a course"

        // When
        sut.toggleListening() // Turn off
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertFalse(sut.isListening)
        XCTAssertEqual(mockSpeechService.stopListeningCallCount, 1)
        XCTAssertEqual(mockOnDeviceAIService.generateCallCount, 1)
        XCTAssertEqual(mockOnDeviceAIService.lastPrompt, "Classify the intent of this text: 'generate a course'. Respond with 'generate' or 'question'.")
    }

    func test_intentClassification_asGenerate_callsGeneratorService() async {
        // Given
        mockOnDeviceAIService.generateResult = .success("generate")
        sut.liveTranscript = "generate a course on history"

        // When
        sut.toggleListening() // Turn off
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockAIGeneratorService.generateContentCallCount, 1, "The backend generator service should be called.")
        XCTAssertEqual(mockTutorService.postTurnCallCount, 0, "The tutor service should NOT be called.")
    }

    func test_intentClassification_asQuestion_callsTutorService() async {
        // Given
        mockOnDeviceAIService.generateResult = .success("question")
        sut.liveTranscript = "what is swiftui?"

        // When
        sut.toggleListening() // Turn off
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockTutorService.postTurnCallCount, 1, "The tutor service should be called.")
        XCTAssertEqual(mockAIGeneratorService.generateContentCallCount, 0, "The generator service should NOT be called.")
    }
}

// MARK: - Additional Mocks

class MockOnDeviceAIService: OnDeviceAIServicing {
    var generateResult: Result<String, Error> = .success("")
    private(set) var generateCallCount = 0
    private(set) var lastPrompt: String?

    func generate(prompt: String) async throws -> String {
        generateCallCount += 1
        lastPrompt = prompt
        return try generateResult.get()
    }
}

// Need to add this mock for the preview to compile
class MockSpeechRecognitionService: SpeechRecognitionServicing {
    var transcriptions: AsyncThrowingStream<String, Error> { .init { _ in } }
    private(set) var startListeningCallCount = 0
    private(set) var stopListeningCallCount = 0
    func startListening() throws { startListeningCallCount += 1 }
    func stopListening() { stopListeningCallCount += 1 }
}
