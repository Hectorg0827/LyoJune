import Foundation
import Combine
import SwiftUI

// Models are now defined in their respective files under Core/Models
// and are available project-wide. No direct imports are needed as
// they are part of the same application target.

public struct EmptyRequest: Codable {}
public struct EmptyRequest: Codable {}
public struct EmptyResponse: Codable {}

// MARK: - Course API Service
@MainActor
class CourseAPIService: ObservableObject {
    static let shared = CourseAPIService()
    
    private init() {}
    
    func getCourses() async throws -> [LearningCourse] {
        return try await NetworkManager.shared.get(endpoint: Constants.API.Endpoints.courses)
    }
    
    func getCourse(id: String) async throws -> LearningCourse {
        return try await NetworkManager.shared.get(endpoint: "\(Constants.API.Endpoints.courses)/\(id)")
    }
    
    func enrollInCourse(courseId: String) async throws -> EnrollmentResponse {
        let request = EnrollmentRequest(courseId: courseId)
        return try await NetworkManager.shared.post(
            endpoint: "\(Constants.API.Endpoints.courses)/\(courseId)/enroll",
            body: request
        )
    }
    
    func updateProgress(courseId: String, lessonId: String, progress: Double) async throws -> ProgressResponse {
        let request = ProgressUpdateRequest(
            courseId: courseId,
            lessonId: lessonId,
            progress: progress,
            completedAt: progress >= 1.0 ? Date() : nil
        )
        return try await NetworkManager.shared.post(
            endpoint: "\(Constants.API.Endpoints.courses)/\(courseId)/progress",
            body: request
        )
    }
    
    func completeCourse(courseId: String) async throws -> CompletionResponse {
        let request = CourseCompletionRequest(courseId: courseId, completedAt: Date())
        return try await NetworkManager.shared.post(
            endpoint: "\(Constants.API.Endpoints.courses)/\(courseId)/complete",
            body: request
        )
    }
    
    func searchCourses(query: String, category: String? = nil) async throws -> [LearningCourse] {
        var endpoint = "\(Constants.API.Endpoints.courses)/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let category = category {
            endpoint += "&category=\(category)"
        }
        return try await NetworkManager.shared.get(endpoint: endpoint)
    }
    
    func getUserCourses() async throws -> [UserCourse] {
        return try await NetworkManager.shared.get(endpoint: "\(Constants.API.Endpoints.courses)/user")
    }
}

// MARK: - CDPost API Service
@MainActor
class PostAPIService: ObservableObject {
    static let shared = PostAPIService()
    
    private init() {}
    
    func getFeed(page: Int = 1, limit: Int = 20) async throws -> FeedResponse {
        return try await NetworkManager.shared.get(
            endpoint: "\(Constants.API.Endpoints.posts)/feed?page=\(page)&limit=\(limit)"
        )
    }
    
    func getPost(id: String) async throws -> Post {
        return try await NetworkManager.shared.get(endpoint: "\(Constants.API.Endpoints.posts)/\(id)")
    }
    
    func createPost(content: String, mediaUrls: [String] = [], courseId: String? = nil) async throws -> Post {
        let request = CreatePostRequest(
            title: "",  // Add default title
            content: content,
            category: "general",  // Add default category
            tags: [],  // Add default tags
            mediaURLs: mediaUrls  // Note: property name is mediaURLs not mediaUrls
        )
        return try await NetworkManager.shared.post(endpoint: Constants.API.Endpoints.posts, body: request)
    }
    
    func likePost(postId: String) async throws -> LikeResponse {
        return try await NetworkManager.shared.post(
            endpoint: "\(Constants.API.Endpoints.posts)/\(postId)/like",
            body: EmptyResponse()
        )
    }
    
    func unlikePost(postId: String) async throws -> LikeResponse {
        return try await NetworkManager.shared.delete(
            endpoint: "\(Constants.API.Endpoints.posts)/\(postId)/like"
        )
    }
    
    func addComment(postId: String, content: String) async throws -> Comment {
        let request = CreateCommentRequest(content: content)
        return try await NetworkManager.shared.post(
            endpoint: "\(Constants.API.Endpoints.posts)/\(postId)/comments",
            body: request
        )
    }
    
    func getComments(postId: String, page: Int = 1) async throws -> CommentsResponse {
        return try await NetworkManager.shared.get(
            endpoint: "\(Constants.API.Endpoints.posts)/\(postId)/comments?page=\(page)"
        )
    }
    
    func sharePost(postId: String, message: String? = nil) async throws -> ShareResponse {
        let request = SharePostRequest(postId: postId, message: message)
        return try await NetworkManager.shared.post(
            endpoint: "\(Constants.API.Endpoints.posts)/\(postId)/share",
            body: request
        )
    }
    
    func reportPost(postId: String, reason: String) async throws -> ReportResponse {
        let request = ReportPostRequest(reason: reason)
        return try await NetworkManager.shared.post(
            endpoint: "\(Constants.API.Endpoints.posts)/\(postId)/report",
            body: request
        )
    }
    
    func uploadMedia(data: Data, type: MediaType) async throws -> MediaUploadResponse {
        let fileName = "media.\(type.fileExtension)"
        return try await NetworkManager.shared.uploadFile(
            endpoint: "\(Constants.API.Endpoints.posts)/media",
            fileData: data,
            fileName: fileName,
            mimeType: type.mimeType
        )
    }
}

// MARK: - Video API Service
@MainActor
class VideoAPIService: ObservableObject {
    static let shared = VideoAPIService()
    
    private init() {}
    
    func getVideoDetails(id: String) async throws -> Video {
        return try await NetworkManager.shared.get(endpoint: "\(Constants.API.Endpoints.videos)/\(id)")
    }
    
    func updateWatchProgress(videoId: String, progress: Double, currentTime: Double) async throws -> WatchProgressResponse {
        let request = UpdateWatchProgressRequest(
            videoId: videoId,
            progress: progress,
            currentTime: currentTime,
            watchedAt: Date()
        )
        return try await NetworkManager.shared.post(
            endpoint: "\(Constants.API.Endpoints.videos)/\(videoId)/progress",
            body: request
        )
    }
    
    func getVideoTranscript(videoId: String) async throws -> VideoTranscript {
        return try await NetworkManager.shared.get(
            endpoint: "\(Constants.API.Endpoints.videos)/\(videoId)/transcript"
        )
    }
    
    func addVideoNote(videoId: String, content: String, timestamp: Double) async throws -> VideoNote {
        let request = CreateVideoNoteRequest(
            content: content,
            timestamp: timestamp
        )
        return try await NetworkManager.shared.post(
            endpoint: "\(Constants.API.Endpoints.videos)/\(videoId)/notes",
            body: request
        )
    }
    
    func getVideoNotes(videoId: String) async throws -> [VideoNote] {
        return try await NetworkManager.shared.get(
            endpoint: "\(Constants.API.Endpoints.videos)/\(videoId)/notes"
        )
    }
}

// Analytics service methods moved to the main AnalyticsAPIService class above

// MARK: - Request/Response Models
// All request and response models have been moved to their respective
// files in the LyoApp/Core/Models/ directory to ensure a single source of truth.
// This file should only contain API service definitions.
