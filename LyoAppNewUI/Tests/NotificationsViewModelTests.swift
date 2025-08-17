import XCTest
@testable import LyoApp

@MainActor
final class NotificationsViewModelTests: XCTestCase {

    private var sut: NotificationsViewModel!
    private var mockNotificationService: MockNotificationService!

    override func setUp() {
        super.setUp()
        mockNotificationService = MockNotificationService()
        sut = NotificationsViewModel(notificationService: mockNotificationService)
    }

    override func tearDown() {
        sut = nil
        mockNotificationService = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_initialState_isCorrect() {
        XCTAssertEqual(sut.viewState, .loading)
        XCTAssertTrue(sut.notifications.isEmpty)
    }

    func test_fetchNotifications_onSuccess_updatesStateToLoaded() async {
        // Given
        let sampleNotifications: [Notification] = [.placeholder, .placeholder]
        mockNotificationService.notificationsResult = .success(sampleNotifications)

        // When
        sut.fetchNotifications()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockNotificationService.fetchNotificationsCallCount, 1)
        XCTAssertEqual(sut.viewState, .loaded)
        XCTAssertEqual(sut.notifications, sampleNotifications)
    }

    func test_fetchNotifications_onSuccessWithEmptyData_updatesStateToEmpty() async {
        // Given
        mockNotificationService.notificationsResult = .success([])

        // When
        sut.fetchNotifications()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockNotificationService.fetchNotificationsCallCount, 1)
        XCTAssertEqual(sut.viewState, .empty)
        XCTAssertTrue(sut.notifications.isEmpty)
    }

    func test_fetchNotifications_onFailure_updatesStateToError() async {
        // Given
        mockNotificationService.notificationsResult = .failure(.unauthorized)

        // When
        sut.fetchNotifications()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockNotificationService.fetchNotificationsCallCount, 1)
        XCTAssertEqual(sut.viewState, .error)
        XCTAssertTrue(sut.notifications.isEmpty)
    }
}
