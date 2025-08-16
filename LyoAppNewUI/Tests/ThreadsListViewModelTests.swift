import XCTest
@testable import LyoApp

@MainActor
final class ThreadsListViewModelTests: XCTestCase {

    private var sut: ThreadsListViewModel!
    private var mockMessagingService: MockMessagingService!

    override func setUp() {
        super.setUp()
        mockMessagingService = MockMessagingService()
        sut = ThreadsListViewModel(messagingService: mockMessagingService)
    }

    override func tearDown() {
        sut = nil
        mockMessagingService = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_initialState_isCorrect() {
        XCTAssertEqual(sut.viewState, .loading)
        XCTAssertTrue(sut.threads.isEmpty)
    }

    func test_fetchThreads_onSuccess_updatesStateToLoaded() async {
        // Given
        let sampleThreads: [ChatThread] = [.placeholder, .placeholder]
        mockMessagingService.threadsResult = .success(sampleThreads)

        // When
        sut.fetchThreads()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockMessagingService.fetchThreadsCallCount, 1)
        XCTAssertEqual(sut.viewState, .loaded)
        XCTAssertEqual(sut.threads, sampleThreads)
    }

    func test_fetchThreads_onSuccessWithEmptyData_updatesStateToEmpty() async {
        // Given
        mockMessagingService.threadsResult = .success([])

        // When
        sut.fetchThreads()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockMessagingService.fetchThreadsCallCount, 1)
        XCTAssertEqual(sut.viewState, .empty)
        XCTAssertTrue(sut.threads.isEmpty)
    }

    func test_fetchThreads_onFailure_updatesStateToError() async {
        // Given
        mockMessagingService.threadsResult = .failure(.unauthorized)

        // When
        sut.fetchThreads()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockMessagingService.fetchThreadsCallCount, 1)
        XCTAssertEqual(sut.viewState, .error)
        XCTAssertTrue(sut.threads.isEmpty)
    }
}
