import Foundation
@testable import LyoApp

final class MockSearchService: SearchServicing {

    var searchResult: Result<[SearchResult], APIError> = .success([])
    private(set) var searchCallCount = 0
    private(set) var lastSearchQuery: String?

    var trendingResult: Result<[TrendingItem], APIError> = .success([])
    private(set) var getTrendingCallCount = 0

    func search(query: String) async throws -> [SearchResult] {
        searchCallCount += 1
        lastSearchQuery = query
        return try searchResult.get()
    }

    func getTrending() async throws -> [TrendingItem] {
        getTrendingCallCount += 1
        return try trendingResult.get()
    }
}
