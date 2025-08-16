import XCTest
@testable import LyoApp

@MainActor
final class RouterTests: XCTestCase {

    private var sut: Router!

    override func setUp() {
        super.setUp()
        sut = Router()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_navigate_appendsDestinationToPath() {
        // Given
        let destination = DeepLink.tutor
        XCTAssertTrue(sut.path.isEmpty, "Precondition: Path should be empty.")

        // When
        sut.navigate(to: destination)

        // Then
        XCTAssertEqual(sut.path.count, 1)
        XCTAssertEqual(sut.path.first as? DeepLink, destination)
    }

    func test_handleURLString_withValidChatURL_appendsCorrectDeepLink() {
        // Given
        let urlString = "lyo://chat/chat-id-123"

        // When
        sut.handle(urlString: urlString)

        // Then
        XCTAssertEqual(sut.path.count, 1)
        XCTAssertEqual(sut.path.first as? DeepLink, .chat(chatId: "chat-id-123"))
    }

    func test_handleURLString_withValidCourseURL_appendsCorrectDeepLink() {
        // Given
        let courseId = UUID().uuidString
        let urlString = "lyo://course/\(courseId)"

        // When
        sut.handle(urlString: urlString)

        // Then
        XCTAssertEqual(sut.path.count, 1)
        XCTAssertEqual(sut.path.first as? DeepLink, .courseOverview(courseId: courseId))
    }

    func test_handleURLString_withInvalidScheme_doesNotNavigate() {
        // Given
        let urlString = "http://lyo/chat/123"

        // When
        sut.handle(urlString: urlString)

        // Then
        XCTAssertTrue(sut.path.isEmpty)
    }

    func test_handleURLString_withUnknownHost_doesNotNavigate() {
        // Given
        let urlString = "lyo://unknown/123"

        // When
        sut.handle(urlString: urlString)

        // Then
        XCTAssertTrue(sut.path.isEmpty)
    }
}
