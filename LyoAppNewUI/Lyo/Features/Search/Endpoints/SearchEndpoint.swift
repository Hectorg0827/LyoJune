import Foundation

/// A namespace for creating API endpoints related to Search & Explore.
enum SearchEndpoint {

    /// Creates an endpoint to search for content.
    /// - Parameter query: The user's search query.
    /// - Returns: An `Endpoint` configured to fetch an array of `SearchResult` objects.
    static func search(query: String) -> Endpoint<[SearchResult]> {
        let queryItems = [URLQueryItem(name: "query", value: query)]
        return Endpoint(
            path: "/v1/search",
            method: .get,
            queryItems: queryItems
        )
    }

    /// Creates an endpoint to fetch trending items for the explore view.
    /// - Returns: An `Endpoint` configured to fetch an array of `TrendingItem` objects.
    static func getTrending() -> Endpoint<[TrendingItem]> {
        return Endpoint(path: "/v1/explore/trending", method: .get)
    }
}
