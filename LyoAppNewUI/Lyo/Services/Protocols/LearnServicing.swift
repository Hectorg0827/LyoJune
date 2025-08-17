import Foundation

/// A protocol that defines the contract for a service that fetches data for the "Learn" feature.
///
/// Conforming types are responsible for interacting with the backend to retrieve course,
/// lesson, and resource information.
public protocol LearnServicing {

    /// Asynchronously fetches all available courses from the backend.
    /// - Returns: An array of `Course` objects.
    /// - Throws: An `APIError` if the network request or decoding fails.
    func fetchAllCourses() async throws -> [Course]

    /// Asynchronously fetches all lessons for a given course.
    /// - Parameter courseId: The unique identifier of the course.
    /// - Returns: An array of `Lesson` objects for the specified course.
    - Throws: An `APIError` if the network request or decoding fails.
    func fetchLessons(for courseId: UUID) async throws -> [Lesson]

    /// Asynchronously fetches all resources for the Resource Hub.
    /// - Returns: An array of `Resource` objects.
    - Throws: An `APIError` if the network request or decoding fails.
    func fetchAllResources() async throws -> [Resource]
}
