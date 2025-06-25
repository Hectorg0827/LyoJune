
import Foundation

public class MockAPIClient: APIClientProtocol {
    public func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        // Return mock data based on the endpoint
        switch endpoint.path {
        case "/courses":
            return Course.mockCourses() as! T
        default:
            throw APIError.mockDataNotFound
        }
    }
}
