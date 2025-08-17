import Foundation

@MainActor
final class StoriesViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var stories: [Story] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorToast: Toast? = nil

    // MARK: - Private Properties

    private let feedService: FeedServicing

    // MARK: - Initialization

    init(feedService: FeedServicing) {
        self.feedService = feedService
    }

    // MARK: - Public Intent Methods

    /// Fetches the list of stories for the tray view.
    func fetchStories() {
        guard !isLoading else { return }

        isLoading = true

        Task {
            do {
                self.stories = try await feedService.getStories()
            } catch {
                self.errorToast = Toast(message: "Failed to load stories.", style: .error)
            }
            isLoading = false
        }
    }
}
