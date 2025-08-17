import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var searchQuery: String = ""
    @Published private(set) var trendingItems: [TrendingItem] = []
    @Published private(set) var searchResults: [SearchResult] = []
    @Published private(set) var viewState: ViewState = .idle

    enum ViewState {
        case idle // Not searching, showing trending
        case loading
        case results([SearchResult])
        case empty
        case error
    }

    // MARK: - Private Properties

    private let searchService: SearchServicing
    private var searchTask: Task<Void, Never>?

    // MARK: - Initialization

    init(searchService: SearchServicing) {
        self.searchService = searchService

        // Use Combine to watch the searchQuery and trigger debounced searches
        $searchQuery
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables) // We need to add this property
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Public Intent Methods

    func fetchTrending() {
        Task {
            do {
                self.trendingItems = try await searchService.getTrending()
            } catch {
                // Handle error silently or with a toast
                print("Failed to load trending items: \(error)")
            }
        }
    }

    private func performSearch(query: String) {
        searchTask?.cancel()

        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            viewState = .idle
            return
        }

        viewState = .loading

        searchTask = Task {
            do {
                let results = try await searchService.search(query: query)
                if Task.isCancelled { return }
                self.viewState = results.isEmpty ? .empty : .results(results)
            } catch {
                if Task.isCancelled { return }
                self.viewState = .error
            }
        }
    }
}
