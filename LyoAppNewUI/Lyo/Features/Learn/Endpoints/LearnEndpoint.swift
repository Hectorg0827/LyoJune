import Foundation

/// A namespace for creating API endpoints related to the "Learn" feature.
enum LearnEndpoint {

    /// Creates an endpoint to fetch all available courses.
    /// The response is expected to be an array of `Course` objects.
    /// - Returns: An `Endpoint` configured to fetch all courses.
    static func getAllCourses() -> Endpoint<[Course]> {
        return Endpoint(path: "/v1/courses", method: .get)
    }

    /// Creates an endpoint to fetch all lessons for a specific course.
    /// - Parameter courseId: The UUID of the course.
    /// - Returns: An `Endpoint` configured to fetch an array of `Lesson` objects.
    static func getLessons(for courseId: UUID) -> Endpoint<[Lesson]> {
        return Endpoint(path: "/v1/courses/\(courseId.uuidString)/lessons", method: .get)
    }

    /// Creates an endpoint to fetch all available resources for the Resource Hub.
    /// The response is expected to be an array of `Resource` objects.
    /// - Returns: An `Endpoint` configured to fetch all resources.
    static func getAllResources() -> Endpoint<[Resource]> {
        return Endpoint(path: "/v1/resources", method: .get)
    }
}
