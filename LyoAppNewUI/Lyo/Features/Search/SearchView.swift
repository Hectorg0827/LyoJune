import SwiftUI

struct SearchView: View {

    @StateObject private var viewModel: SearchViewModel

    init(viewModel: SearchViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        // The RootView will provide the NavigationStack
        List {
            switch viewModel.viewState {
            case .idle:
                trendingSection
            case .loading:
                ProgressView("Searching...")
            case .empty:
                Text("No results found for \"\(viewModel.searchQuery)\"")
                    .foregroundColor(.secondary)
            case .results(let results):
                ForEach(results) { result in
                    SearchResultRowView(result: result)
                }
            case .error:
                Text("An error occurred. Please try again.")
                    .foregroundColor(.red)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Search")
        .searchable(text: $viewModel.searchQuery, prompt: "Search for courses, posts, or users")
        .onAppear {
            if viewModel.trendingItems.isEmpty {
                viewModel.fetchTrending()
            }
        }
    }

    @ViewBuilder
    private var trendingSection: some View {
        Section(header: Text("Trending Topics").font(.headline)) {
            if viewModel.trendingItems.isEmpty {
                ProgressView()
            } else {
                ForEach(viewModel.trendingItems) { item in
                    VStack(alignment: .leading) {
                        Text(item.topic).bold()
                        Text(item.description).font(.caption).foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

#if DEBUG
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        // This would require a mock search service
        let service = MockSearchService()
        let viewModel = SearchViewModel(searchService: service)

        // Simulate some trending data
        service.trendingResult = .success([
            .init(topic: "SwiftUI", description: "1,234 posts"),
            .init(topic: "Concurrency", description: "876 posts")
        ])

        return NavigationStack {
            SearchView(viewModel: viewModel)
        }
    }

    private class MockSearchService: SearchServicing {
        var searchResult: Result<[SearchResult], APIError> = .success([])
        var trendingResult: Result<[TrendingItem], APIError> = .success([])

        func search(query: String) async throws -> [SearchResult] {
            try searchResult.get()
        }
        func getTrending() async throws -> [TrendingItem] {
            try trendingResult.get()
        }
    }
}
#endif
