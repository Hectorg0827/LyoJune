import Foundation

/// The live implementation of the `MessagingServicing` protocol.
/// This class uses an `HTTPClient` to fetch data from the RESTful chat API endpoints.
public final class MessagingService: MessagingServicing {

    private let httpClient: HTTPClienting

    public init(httpClient: HTTPClienting) {
        self.httpClient = httpClient
    }

    public func fetchThreads() async throws -> [ChatThread] {
        let endpoint = MessagingEndpoint.getThreads()
        return try await httpClient.request(endpoint)
    }

    public func fetchHistory(for chatId: String) async throws -> [ChatMessage] {
        let endpoint = MessagingEndpoint.getHistory(for: chatId)
        return try await httpClient.request(endpoint)
    }
}
