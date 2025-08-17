import Foundation

/// A namespace for creating API endpoints related to the RESTful portion of the Messaging feature.
enum MessagingEndpoint {

    /// Creates an endpoint to fetch all of the current user's chat threads.
    /// - Returns: An `Endpoint` configured to fetch an array of `ChatThread` objects.
    static func getThreads() -> Endpoint<[ChatThread]> {
        return Endpoint(path: "/v1/chats", method: .get)
    }

    /// Creates an endpoint to fetch the message history for a specific chat thread.
    /// - Parameter chatId: The ID of the chat thread.
    /// - Returns: An `Endpoint` configured to fetch an array of `ChatMessage` objects.
    static func getHistory(for chatId: String) -> Endpoint<[ChatMessage]> {
        return Endpoint(path: "/v1/chats/\(chatId)/history", method: .get)
    }
}
