import SwiftUI

public struct CreatePostRequest: Codable {
    public let mediaURLs: [String]
}

public struct MediaUploadResponse: Codable {
    public let url: String
    public let id: String
}

public struct CommentsResponse: Codable {
    public let comments: [Comment]
    public let pagination: PaginationInfo
}

public struct LikeResponse: Codable {
    public let liked: Bool
    public let likeCount: Int
}

public struct ShareResponse: Codable {
    public let shared: Bool
    public let shareCount: Int
}

public struct ReportResponse: Codable {
    public let reported: Bool
    public let message: String
}

public struct FeedResponse: Codable {
    public let posts: [Post]
    public let pagination: PaginationInfo
    
    public init(posts: [Post], pagination: PaginationInfo) {
        self.posts = posts
        self.pagination = pagination
    }
}

