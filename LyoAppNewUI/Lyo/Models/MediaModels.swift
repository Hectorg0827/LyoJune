import Foundation

// MARK: - Presign Flow

/// The request body sent to `/v1/media/presign` to get a URL for uploading.
public struct PresignRequest: Codable {
    /// The MIME type of the file to be uploaded (e.g., "image/jpeg", "video/mp4").
    let contentType: String

    /// The file extension (e.g., "jpg", "mp4").
    let fileExtension: String
}

/// The response from a successful presign request.
public struct PresignedURLResponse: Codable {
    /// The presigned URL to which the client should PUT the media file.
    let uploadUrl: URL

    /// The key or URL of the asset that should be used in the commit step.
    let assetKey: String
}

// MARK: - Commit Flow

/// The request body sent to `/v1/media/commit` after a successful upload to the presigned URL.
public struct CommitMediaRequest: Codable {
    /// The key for the asset that was successfully uploaded.
    let assetKey: String
}
