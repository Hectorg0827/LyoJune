import Foundation

/// A namespace for creating API endpoints related to content moderation.
enum ModerationEndpoint {

    /// Creates an endpoint to report a piece of content.
    /// - Parameter reportRequest: The request body containing details of the report.
    /// - Returns: An `Endpoint` that expects an empty response on success.
    static func reportContent(_ reportRequest: ReportContentRequest) -> Endpoint<EmptyResponse> {
        return try! Endpoint(
            path: "/v1/moderation/report",
            method: .post,
            encodableBody: reportRequest
        )
    }
}
