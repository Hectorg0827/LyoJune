import XCTest
@testable import LyoApp

@MainActor
final class CourseListViewModelTests: XCTestCase {

    private var sut: CourseListViewModel!
    private var mockLearnService: MockLearnService!

    override func setUp() {
        super.setUp()
        mockLearnService = MockLearnService()
        sut = CourseListViewModel(learnService: mockLearnService)
    }

    override func tearDown() {
        sut = nil
        mockLearnService = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_initialState_isCorrect() {
        // Assert
        XCTAssertEqual(sut.viewState, .loading, "The initial view state should be .loading.")
        XCTAssertTrue(sut.courses.isEmpty, "The initial courses array should be empty.")
        XCTAssertNil(sut.errorToast, "The initial error toast should be nil.")
    }

    func test_fetchCourses_onSuccess_updatesStateToLoaded() async {
        // Given
        let sampleCourses = [Course.placeholder, Course.placeholder]
        mockLearnService.coursesResult = .success(sampleCourses)

        // When
        sut.fetchCourses()

        // A small delay to allow the async task to complete.
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Then
        XCTAssertEqual(mockLearnService.fetchAllCoursesCallCount, 1)
        XCTAssertEqual(sut.viewState, .loaded)
        XCTAssertEqual(sut.courses, sampleCourses)
        XCTAssertNil(sut.errorToast)
    }

    func test_fetchCourses_onSuccessWithEmptyData_updatesStateToEmpty() async {
        // Given
        mockLearnService.coursesResult = .success([])

        // When
        sut.fetchCourses()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockLearnService.fetchAllCoursesCallCount, 1)
        XCTAssertEqual(sut.viewState, .empty)
        XCTAssertTrue(sut.courses.isEmpty)
        XCTAssertNil(sut.errorToast)
    }

    func test_fetchCourses_onFailure_updatesStateToErrorAndSetsToast() async {
        // Given
        let expectedError = APIError.serverError(message: "Server is down")
        mockLearnService.coursesResult = .failure(expectedError)

        // When
        sut.fetchCourses()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockLearnService.fetchAllCoursesCallCount, 1)
        XCTAssertEqual(sut.viewState, .error)
        XCTAssertTrue(sut.courses.isEmpty)
        XCTAssertNotNil(sut.errorToast)
        XCTAssertEqual(sut.errorToast?.style, .error)
        XCTAssertEqual(sut.errorToast?.message, "Failed to load courses. Please try again.")
    }
}
