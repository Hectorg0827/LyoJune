import XCTest
@testable import LyoApp

@MainActor
final class SearchViewModelTests: XCTestCase {

    private var sut: SearchViewModel!
    private var mockSearchService: MockSearchService!

    override func setUp() {
        super.setUp()
        mockSearchService = MockSearchService()
        sut = SearchViewModel(searchService: mockSearchService)
    }

    override func tearDown() {
        sut = nil
        mockSearchService = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_fetchTrending_onSuccess_populatesTrendingItems() async {
        // Given
        let trendingItems: [TrendingItem] = [.init(topic: "SwiftUI", description: "")]
        mockSearchService.trendingResult = .success(trendingItems)

        // When
        sut.fetchTrending()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockSearchService.getTrendingCallCount, 1)
        XCTAssertEqual(sut.trendingItems, trendingItems)
    }

    func test_searchQueryChange_withDebounce_makesOneAPICall() async {
        // Given
        mockSearchService.searchResult = .success([])

        // When
        sut.searchQuery = "s"
        sut.searchQuery = "sw"
        sut.searchQuery = "swi"
        sut.searchQuery = "swif"
        sut.searchQuery = "swift"

        // Wait for longer than the debounce interval (500ms)
        try? await Task.sleep(nanoseconds: 600_000_000)

        // Then
        XCTAssertEqual(mockSearchService.searchCallCount, 1, "The search service should only be called once after debouncing.")
        XCTAssertEqual(mockSearchService.lastSearchQuery, "swift")
    }

    func test_searchQueryChange_toEmpty_resetsStateToIdle() async {
        // Given
        sut.searchQuery = "swift"
        try? await Task.sleep(nanoseconds: 600_000_000)
        XCTAssertNotEqual(sut.viewState, .idle, "Precondition: state should not be idle.")

        // When
        sut.searchQuery = ""
        try? await Task.sleep(nanoseconds: 600_000_000)

        // Then
        XCTAssertEqual(sut.viewState, .idle)
    }

    func test_performSearch_onSuccess_updatesStateToResults() async {
        // Given
        let searchResults: [SearchResult] = [] // The content doesn't matter for this test
        mockSearchService.searchResult = .success(searchResults)

        // When
        sut.searchQuery = "test"
        try? await Task.sleep(nanoseconds: 600_000_000)

        // Then
        guard case .results(let results) = sut.viewState else {
            XCTFail("View state should be .results, but was \(sut.viewState)")
            return
        }
        XCTAssertEqual(results.count, searchResults.count)
    }

    func test_performSearch_onFailure_updatesStateToError() async {
        // Given
        mockSearchService.searchResult = .failure(.unauthorized)

        // When
        sut.searchQuery = "test"
        try? await Task.sleep(nanoseconds: 600_000_000)

        // Then
        XCTAssertEqual(sut.viewState, .error)
    }
}
