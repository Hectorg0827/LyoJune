
import Foundation

@MainActor
class SearchAPIService: APIService {
    static let shared = SearchAPIService()
    let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }

    func searchContent(_ query: String, filters: SearchFilters? = nil) async throws -> SearchResults {
        var endpoint = Endpoint(path: "/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        // Add filter logic here
        return try await apiClient.request(endpoint)
    }

    func getSuggestions(for query: String) async throws -> [SearchSuggestion] {
        let endpoint = Endpoint(path: "/search/suggestions?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        return try await apiClient.request(endpoint)
    }

    func saveSearch(_ query: String) async throws {
        let request = SaveSearchRequest(query: query)
        let endpoint = Endpoint(path: "/search/history", method: .post, body: request)
        let _: EmptyResponse = try await apiClient.request(endpoint)
    }

    func performAISearch(query: String) async throws -> SearchResults {
        let request = AISearchRequest(query: query)
        let endpoint = Endpoint(path: "/search/ai", method: .post, body: request)
        return try await apiClient.request(endpoint)
    }
}
