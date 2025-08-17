import Foundation

/// A namespace for creating API endpoints related to media uploads.
enum MediaEndpoint {

    /// Creates an endpoint to get a presigned URL for a file upload.
    /// - Parameters:
    ///   - contentType: The MIME type of the file (e.g., "image/jpeg").
    ///   - fileExtension: The file's extension (e.g., "jpg").
    /// - Returns: An `Endpoint` configured to fetch a `PresignedURLResponse`.
    static func getPresignedURL(contentType: String, fileExtension: String) -> Endpoint<PresignedURLResponse> {
        let requestBody = PresignRequest(contentType: contentType, fileExtension: fileExtension)
        return try! Endpoint(
            path: "/v1/media/presign",
            method: .post,
            encodableBody: requestBody
        )
    }

    /// Creates an endpoint to commit a media file after it has been successfully uploaded.
    /// This tells the backend that the upload is complete and the file is ready for processing.
    /// - Parameter assetKey: The key of the asset that was uploaded.
    /// - Returns: An `Endpoint` configured to expect an empty response.
    static func commitMedia(assetKey: String) -> Endpoint<EmptyResponse> {
        let requestBody = CommitMediaRequest(assetKey: assetKey)
        return try! Endpoint(
            path: "/v1/media/commit",
            method: .post,
            encodableBody: requestBody
        )
    }
}
