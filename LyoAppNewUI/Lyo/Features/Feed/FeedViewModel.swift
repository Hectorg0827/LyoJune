import Foundation

@MainActor
final class FeedViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var posts: [Post] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorToast: Toast? = nil

    // MARK: - Private Properties

    private let feedService: FeedServicing

    // MARK: - Initialization

    init(feedService: FeedServicing) {
        self.feedService = feedService
    }

    // MARK: - Public Intent Methods

    /// Fetches the "For-You" feed from the backend.
    func fetchForYouFeed() {
        guard !isLoading else { return }

        isLoading = true

        Task {
            do {
                // In a real app, you would implement pagination, passing a cursor or page number.
                self.posts = try await feedService.getForYouFeed()
            } catch {
                self.errorToast = Toast(message: "Failed to load feed. Please try again.", style: .error)
            }
            isLoading = false
        }
    }
}
