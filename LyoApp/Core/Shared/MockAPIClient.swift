import Foundation
import Combine

// MARK: - Mock API Client
public final class MockAPIClient: APIClientProtocol {
    public static let shared = MockAPIClient()
    
    private let mockDelay: TimeInterval
    private let shouldSimulateNetworkFailure: Bool
    
    private init(mockDelay: TimeInterval = 0.5, shouldSimulateNetworkFailure: Bool = false) {
        self.mockDelay = mockDelay
        self.shouldSimulateNetworkFailure = shouldSimulateNetworkFailure
    }
    
    public func request<T: Codable>(_ endpoint: APIEndpoint, responseType: T.Type) async throws -> T {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        
        // Simulate network failure occasionally
        if shouldSimulateNetworkFailure && Bool.random() {
            throw NetworkError.networkError(NSError(domain: "MockNetwork", code: -1, userInfo: [NSLocalizedDescriptionKey: "Simulated network error"]))
        }
        
        return try mockResponse(for: endpoint, responseType: responseType)
    }
    
    public func request<T: Codable>(_ endpoint: APIEndpoint) async throws -> T {
        return try await request(endpoint, responseType: T.self)
    }
    
    public func performRequest<T: Codable>(_ request: URLRequest, responseType: T.Type) -> Future<T, NetworkError> {
        return Future { promise in
            DispatchQueue.global().asyncAfter(deadline: .now() + self.mockDelay) {
                do {
                    // Convert URLRequest to APIEndpoint for mock logic
                    let endpoint = self.urlRequestToAPIEndpoint(request)
                    let result = try self.mockResponse(for: endpoint, responseType: responseType)
                    promise(.success(result))
                } catch let error as NetworkError {
                    promise(.failure(error))
                } catch {
                    promise(.failure(.unknown))
                }
            }
        }
    }
    
    public func uploadFile<T: Codable>(to endpoint: APIEndpoint, fileData: Data, fileName: String, mimeType: String) -> Future<T, NetworkError> {
        return Future { promise in
            DispatchQueue.global().asyncAfter(deadline: .now() + self.mockDelay) {
                do {
                    let result = try self.mockResponse(for: endpoint, responseType: T.self)
                    promise(.success(result))
                } catch let error as NetworkError {
                    promise(.failure(error))
                } catch {
                    promise(.failure(.unknown))
                }
            }
        }
    }
    
    // MARK: - Mock Response Generation
    
    private func mockResponse<T: Codable>(for endpoint: APIEndpoint, responseType: T.Type) throws -> T {
        let path = endpoint.path
        
        // Auth endpoints
        if path.contains("/auth/login") || path.contains("/auth/register") {
            return try mockAuthResponse() as! T
        }
        
        if path.contains("/auth/refresh") {
            return try mockRefreshTokenResponse() as! T
        }
        
        // User endpoints
        if path.contains("/user/profile") || path.contains("/profile") {
            return try mockUserProfile() as! T
        }
        
        // Course endpoints
        if path.contains("/courses") {
            if path.contains("/enroll") {
                return try mockEnrollmentResponse() as! T
            }
            return try mockCourses() as! T
        }
        
        // Post endpoints
        if path.contains("/posts") {
            if path.contains("/feed") {
                return try mockFeedResponse() as! T
            }
            return try mockPosts() as! T
        }
        
        // Generic empty response for other endpoints
        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }
        
        // Try to create a default instance if possible
        throw NetworkError.invalidResponse
    }
    
    // MARK: - Mock Response Helpers
    
    private func mockAuthResponse() throws -> AuthResponse {
        return AuthResponse(
            user: mockUser(),
            accessToken: "mock_access_token_\(UUID().uuidString)",
            refreshToken: "mock_refresh_token_\(UUID().uuidString)",
            expiresIn: 3600
        )
    }
    
    private func mockRefreshTokenResponse() throws -> RefreshTokenResponse {
        return RefreshTokenResponse(
            accessToken: "mock_new_access_token_\(UUID().uuidString)",
            refreshToken: "mock_new_refresh_token_\(UUID().uuidString)"
        )
    }
    
    private func mockUser() -> User {
        return User(
            id: UUID().uuidString,
            email: "mock.user@example.com",
            firstName: "Mock",
            lastName: "User",
            username: "mockuser",
            avatar: nil,
            bio: "This is a mock user for testing purposes",
            isVerified: true,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
    }
    
    private func mockUserProfile() throws -> UserProfile {
        return UserProfile(
            id: UUID(),
            username: "mockuser",
            displayName: "Mock User",
            bio: "This is a mock user profile",
            avatar: nil,
            level: 5,
            xp: 1250,
            joinedAt: Date(),
            coursesCompleted: 3,
            badgesEarned: 12,
            followersCount: 42,
            followingCount: 28,
            isFollowing: false
        )
    }
    
    private func mockCourses() throws -> [Course] {
        return [
            Course(
                id: UUID().uuidString,
                title: "Introduction to Swift",
                description: "Learn the basics of Swift programming",
                thumbnailUrl: nil,
                difficulty: "beginner",
                duration: 3600,
                instructorId: "instructor_1",
                instructorName: "John Doe",
                price: 0,
                isPremium: false,
                tags: ["swift", "ios", "programming"],
                rating: 4.5,
                reviewCount: 128,
                enrollmentCount: 1542,
                isEnrolled: false,
                progress: 0.0,
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
    }
    
    private func mockFeedResponse() throws -> FeedResponse {
        return FeedResponse(
            posts: [],
            hasMore: false,
            nextPage: nil
        )
    }
    
    private func mockPosts() throws -> [Post] {
        return []
    }
    
    private func mockEnrollmentResponse() throws -> EnrollmentResponse {
        return EnrollmentResponse(
            success: true,
            enrollmentDate: Date()
        )
    }
    
    // MARK: - Helper Methods
    
    private func urlRequestToAPIEndpoint(_ request: URLRequest) -> APIEndpoint {
        let path = request.url?.path ?? ""
        let method = HTTPMethod(rawValue: request.httpMethod ?? "GET") ?? .GET
        let headers = request.allHTTPHeaderFields
        let body = request.httpBody
        
        return APIEndpoint(path: path, method: method, headers: headers, body: body)
    }
}

// MARK: - Mock Response Types
private struct RefreshTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
}
