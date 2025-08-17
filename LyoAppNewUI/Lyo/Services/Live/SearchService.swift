import Foundation

/// The live implementation of the `SearchServicing` protocol.
/// This class uses an `HTTPClient` to fetch data from the search and explore endpoints.
public final class SearchService: SearchServicing {

    private let httpClient: HTTPClienting

    public init(httpClient: HTTPClienting) {
        self.httpClient = httpClient
    }

    public func search(query: String) async throws -> [SearchResult] {
        let endpoint = SearchEndpoint.search(query: query)
        return try await httpClient.request(endpoint)
    }

    public func getTrending() async throws -> [TrendingItem] {
        let endpoint = SearchEndpoint.getTrending()
        return try await httpClient.request(endpoint)
    }
}
