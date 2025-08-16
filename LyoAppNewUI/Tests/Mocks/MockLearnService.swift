import Foundation
@testable import LyoApp

/// A mock implementation of the `LearnServicing` protocol for use in unit tests.
final class MockLearnService: LearnServicing {

    // MARK: - Courses

    /// The result to return when `fetchAllCourses` is called.
    var coursesResult: Result<[Course], APIError> = .success([])

    /// The number of times `fetchAllCourses` has been called.
    private(set) var fetchAllCoursesCallCount = 0

    func fetchAllCourses() async throws -> [Course] {
        fetchAllCoursesCallCount += 1
        switch coursesResult {
        case .success(let courses):
            return courses
        case .failure(let error):
            throw error
        }
    }

    // MARK: - Lessons

    /// The result to return when `fetchLessons` is called.
    var lessonsResult: Result<[Lesson], APIError> = .success([])

    /// The number of times `fetchLessons` has been called.
    private(set) var fetchLessonsCallCount = 0

    func fetchLessons(for courseId: UUID) async throws -> [Lesson] {
        fetchLessonsCallCount += 1
        switch lessonsResult {
        case .success(let lessons):
            return lessons
        case .failure(let error):
            throw error
        }
    }

    // MARK: - Resources

    /// The result to return when `fetchAllResources` is called.
    var resourcesResult: Result<[Resource], APIError> = .success([])

    /// The number of times `fetchAllResources` has been called.
    private(set) var fetchAllResourcesCallCount = 0

    func fetchAllResources() async throws -> [Resource] {
        fetchAllResourcesCallCount += 1
        switch resourcesResult {
        case .success(let resources):
            return resources
        case .failure(let error):
            throw error
        }
    }

    /// A convenience method to reset all call counts.
    func reset() {
        fetchAllCoursesCallCount = 0
        fetchLessonsCallCount = 0
        fetchAllResourcesCallCount = 0
    }
}
