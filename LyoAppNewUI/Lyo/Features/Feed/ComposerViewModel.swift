import Foundation
import SwiftUI // For UIImage, if we were using it. For now, we'll use Data.

@MainActor
final class ComposerViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var caption: String = ""
    @Published var selectedMedia: Data? = nil // In a real app, this would be a more complex object with media type info.

    @Published private(set) var uploadState: UploadState = .idle
    @Published var errorToast: Toast? = nil

    enum UploadState: Equatable {
        case idle
        case presigning
        case uploading(progress: Double)
        case committing
        case posting
        case success
    }

    // MARK: - Private Properties

    private let feedService: FeedServicing

    // MARK: - Initialization

    init(feedService: FeedServicing) {
        self.feedService = feedService
    }

    // MARK: - Public Intent Methods

    func createPost() {
        guard let mediaData = selectedMedia, !caption.isEmpty else {
            errorToast = Toast(message: "Please select media and enter a caption.", style: .error)
            return
        }

        Task {
            do {
                // Step 1: Get Presigned URL
                uploadState = .presigning
                let presignResponse = try await feedService.getPresignedURL(contentType: "video/mp4", fileExtension: "mp4")

                // Step 2: Upload to Presigned URL
                uploadState = .uploading(progress: 0.0)
                try await upload(data: mediaData, to: presignResponse.uploadUrl)

                // Step 3: Commit Media
                uploadState = .committing
                try await feedService.commitMedia(assetKey: presignResponse.assetKey)

                // Step 4: Create Post
                uploadState = .posting
                _ = try await feedService.createPost(caption: caption, mediaAssetUrl: presignResponse.assetKey)

                uploadState = .success

            } catch {
                errorToast = Toast(message: "Failed to create post: \(error.localizedDescription)", style: .error)
                uploadState = .idle
            }
        }
    }

    // MARK: - Private Upload Logic

    /// Performs a raw data upload to the given URL.
    private func upload(data: Data, to url: URL) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("video/mp4", forHTTPHeaderField: "Content-Type")

        // In a real app, you would use a URLSession with a delegate to track upload progress.
        // For this simulation, we'll just update the progress state artificially.
        let (_, response) = try await URLSession.shared.upload(for: request, from: data)

        // This is a simplified progress simulation.
        uploadState = .uploading(progress: 0.5)
        try await Task.sleep(nanoseconds: 500_000_000)
        uploadState = .uploading(progress: 1.0)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed(URLError(.badServerResponse))
        }
    }
}
