import Foundation

/// A protocol that defines the contract for a service that fetches search and explore data.
public protocol SearchServicing {

    /// Asynchronously searches for content based on a query.
    /// - Parameter query: The search term.
    /// - Returns: An array of `SearchResult` objects.
    /// - Throws: An `APIError` if the network request or decoding fails.
    func search(query: String) async throws -> [SearchResult]

    /// Asynchronously fetches the current trending items.
    /// - Returns: An array of `TrendingItem` objects.
    /// - Throws: An `APIError` if the network request or decoding fails.
    func getTrending() async throws -> [TrendingItem]
}
