import Foundation

/// The live implementation of the `LearnServicing` protocol.
/// This class uses an `HTTPClient` to fetch data related to courses, lessons, and resources from the backend.
public final class LearnService: LearnServicing {

    private let httpClient: HTTPClienting

    /// Initializes a new `LearnService`.
    /// - Parameter httpClient: The `HTTPClient` to use for making network requests.
    public init(httpClient: HTTPClienting) {
        self.httpClient = httpClient
    }

    public func fetchAllCourses() async throws -> [Course] {
        let endpoint = LearnEndpoint.getAllCourses()
        return try await httpClient.request(endpoint)
    }

    public func fetchLessons(for courseId: UUID) async throws -> [Lesson] {
        let endpoint = LearnEndpoint.getLessons(for: courseId)
        return try await httpClient.request(endpoint)
    }

    public func fetchAllResources() async throws -> [Resource] {
        let endpoint = LearnEndpoint.getAllResources()
        return try await httpClient.request(endpoint)
    }
}
