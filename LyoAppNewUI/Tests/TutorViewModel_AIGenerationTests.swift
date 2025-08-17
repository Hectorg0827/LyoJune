import XCTest
@testable import LyoApp

@MainActor
final class TutorViewModel_AIGenerationTests: XCTestCase {

    private var sut: TutorViewModel!
    private var mockTutorService: MockTutorService!
    private var mockAIGeneratorService: MockAIGeneratorService!
    private var mockRouter: MockRouter!
    private var mockAICoordinator: MockAICoordinator!

    override func setUp() {
        super.setUp()
        mockTutorService = MockTutorService()
        mockAIGeneratorService = MockAIGeneratorService()
        mockRouter = MockRouter()
        mockAICoordinator = MockAICoordinator()

        sut = TutorViewModel(
            tutorService: mockTutorService,
            aiGeneratorService: mockAIGeneratorService,
            router: mockRouter,
            aiCoordinator: mockAICoordinator
        )
    }

    override func tearDown() {
        sut = nil
        mockTutorService = nil
        mockAIGeneratorService = nil
        mockRouter = nil
        mockAICoordinator = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_sendMessage_withGenerateKeyword_callsGeneratorService() async {
        // Given
        let message = "generate a course on swiftui"

        // When
        sut.sendMessage(message)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockAIGeneratorService.generateContentCallCount, 1)
        XCTAssertEqual(mockTutorService.postTurnCallCount, 0, "PostTurn should not be called for a generation request.")
    }

    func test_handleGeneratedContent_withFullCourse_callsRouterAndCoordinator() async {
        // Given
        let course = Course.placeholder
        mockAIGeneratorService.generateContentResult = .success(.fullCourse(course))

        // When
        sut.sendMessage("generate")
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockAICoordinator.hideChatCallCount, 1)
        XCTAssertEqual(mockRouter.navigateCallCount, 1)
        XCTAssertEqual(mockRouter.lastDestination, .courseOverview(courseId: course.id.uuidString))
    }

    func test_handleGeneratedContent_withTutorial_appendsTutorialMessage() async {
        // Given
        let tutorial = Tutorial(title: "My Tutorial", content: "...")
        mockAIGeneratorService.generateContentResult = .success(.tutorial(tutorial))

        // When
        sut.sendMessage("generate")
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        // The view model should have 2 messages: the user's "generate" message, and the tutor's tutorial response.
        XCTAssertEqual(sut.messages.count, 2)
        let lastMessage = sut.messages.last
        XCTAssertEqual(lastMessage?.type, .tutorial)
        XCTAssertEqual(lastMessage?.tutorial, tutorial)
    }
}

// MARK: - Additional Mocks

// We need mocks for the Router and Coordinator to test the navigation calls.
class MockRouter: Router {
    private(set) var navigateCallCount = 0
    private(set) var lastDestination: DeepLink?

    override func navigate(to destination: DeepLink) {
        navigateCallCount += 1
        lastDestination = destination
    }
}

class MockAICoordinator: AICoordinator {
    private(set) var hideChatCallCount = 0

    override func hideChat() {
        hideChatCallCount += 1
        super.hideChat()
    }
}
