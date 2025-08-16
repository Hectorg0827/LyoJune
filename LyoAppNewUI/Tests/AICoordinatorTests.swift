import XCTest
@testable import LyoApp

@MainActor
final class AICoordinatorTests: XCTestCase {

    private var sut: AICoordinator!

    override func setUp() {
        super.setUp()
        sut = AICoordinator()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_initialState_isCorrect() {
        // Assert
        XCTAssertFalse(sut.isChatPresented, "The chat should not be presented initially.")
    }

    func test_showChat_setsIsPresentedToTrue() {
        // Given
        sut.isChatPresented = false

        // When
        sut.showChat()

        // Then
        XCTAssertTrue(sut.isChatPresented)
    }

    func test_hideChat_setsIsPresentedToFalse() {
        // Given
        sut.isChatPresented = true

        // When
        sut.hideChat()

        // Then
        XCTAssertFalse(sut.isChatPresented)
    }
}
