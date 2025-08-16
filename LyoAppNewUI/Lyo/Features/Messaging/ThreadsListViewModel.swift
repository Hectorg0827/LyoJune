import Foundation

@MainActor
final class ThreadsListViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var threads: [ChatThread] = []
    @Published private(set) var viewState: ViewState = .loading

    // MARK: - Private Properties

    private let messagingService: MessagingServicing

    // MARK: - Initialization

    init(messagingService: MessagingServicing) {
        self.messagingService = messagingService
    }

    // MARK: - Public Intent Methods

    /// Fetches the list of chat threads from the backend.
    func fetchThreads() {
        if threads.isEmpty {
            viewState = .loading
        }

        Task {
            do {
                let fetchedThreads = try await messagingService.fetchThreads()
                self.threads = fetchedThreads
                self.viewState = fetchedThreads.isEmpty ? .empty : .loaded
            } catch {
                self.viewState = .error
                // The view will show an error state based on this.
            }
        }
    }
}

// MARK: - View State Enum

extension ThreadsListViewModel {
    /// An enum to represent the different states of the view.
    enum ViewState {
        case loading
        case loaded
        case empty
        case error
    }
}
