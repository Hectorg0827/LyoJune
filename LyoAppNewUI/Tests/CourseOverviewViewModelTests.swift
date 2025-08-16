import XCTest
@testable import LyoApp

@MainActor
final class CourseOverviewViewModelTests: XCTestCase {

    private var sut: CourseOverviewViewModel!
    private var mockLearnService: MockLearnService!
    private let sampleCourse = Course.placeholder

    override func setUp() {
        super.setUp()
        mockLearnService = MockLearnService()
        sut = CourseOverviewViewModel(
            course: sampleCourse,
            learnService: mockLearnService
        )
    }

    override func tearDown() {
        sut = nil
        mockLearnService = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_initialState_isCorrect() {
        // Assert
        XCTAssertEqual(sut.viewState, .loading)
        XCTAssertTrue(sut.lessons.isEmpty)
    }

    func test_fetchLessons_onSuccess_updatesStateToLoaded() async {
        // Given
        let sampleLessons: [Lesson] = [
            .init(id: UUID(), title: "Lesson 1", content: "", durationMinutes: 5),
            .init(id: UUID(), title: "Lesson 2", content: "", durationMinutes: 10)
        ]
        mockLearnService.lessonsResult = .success(sampleLessons)

        // When
        sut.fetchLessons()
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Then
        XCTAssertEqual(mockLearnService.fetchLessonsCallCount, 1)
        XCTAssertEqual(sut.viewState, .loaded)
        XCTAssertEqual(sut.lessons, sampleLessons)
    }

    func test_fetchLessons_onSuccessWithEmptyData_updatesStateToEmpty() async {
        // Given
        mockLearnService.lessonsResult = .success([])

        // When
        sut.fetchLessons()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockLearnService.fetchLessonsCallCount, 1)
        XCTAssertEqual(sut.viewState, .empty)
        XCTAssertTrue(sut.lessons.isEmpty)
    }

    func test_fetchLessons_onFailure_updatesStateToError() async {
        // Given
        mockLearnService.lessonsResult = .failure(.unauthorized)

        // When
        sut.fetchLessons()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockLearnService.fetchLessonsCallCount, 1)
        XCTAssertEqual(sut.viewState, .error)
        XCTAssertTrue(sut.lessons.isEmpty)
    }
}
