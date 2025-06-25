
import Foundation

// MARK: - Mock API Client for Testing and Development
public class MockAPIClient: APIClientProtocol {
    
    public static let shared = MockAPIClient()
    
    public init() {}
    
    public func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Handle empty responses
        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }
        
        // Return mock data based on the endpoint path
        switch endpoint.path {
        case let path where path.contains("/courses"):
            return try mockCoursesResponse() as! T
        case let path where path.contains("/auth/login"):
            return try mockAuthResponse() as! T
        case let path where path.contains("/auth/register"):
            return try mockAuthResponse() as! T
        case let path where path.contains("/profile"):
            return try mockUserResponse() as! T
        case let path where path.contains("/achievements"):
            return try mockAchievementsResponse() as! T
        case let path where path.contains("/analytics"):
            return try mockAnalyticsResponse() as! T
        case let path where path.contains("/leaderboard"):
            return try mockLeaderboardResponse() as! T
        case let path where path.contains("/community"):
            return try mockCommunityResponse() as! T
        default:
            throw APIError.mockDataNotFound
        }
    }
}

// MARK: - Mock Data Generators
extension MockAPIClient {
    private func mockCoursesResponse<T: Decodable>() throws -> T {
        // This would need to be implemented based on actual CourseModels
        throw APIError.mockDataNotFound
    }
    
    private func mockAuthResponse<T: Decodable>() throws -> T {
        // This would need to be implemented based on actual AuthModels
        throw APIError.mockDataNotFound
    }
    
    private func mockUserResponse<T: Decodable>() throws -> T {
        // This would need to be implemented based on actual UserModels
        throw APIError.mockDataNotFound
    }
    
    private func mockAchievementsResponse<T: Decodable>() throws -> T {
        // This would need to be implemented based on actual GamificationModels
        throw APIError.mockDataNotFound
    }
    
    private func mockAnalyticsResponse<T: Decodable>() throws -> T {
        // This would need to be implemented based on actual analytics models
        throw APIError.mockDataNotFound
    }
    
    private func mockLeaderboardResponse<T: Decodable>() throws -> T {
        // This would need to be implemented based on actual leaderboard models
        throw APIError.mockDataNotFound
    }
    
    private func mockCommunityResponse<T: Decodable>() throws -> T {
        // This would need to be implemented based on actual community models
        throw APIError.mockDataNotFound
    }
}
