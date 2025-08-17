import Foundation

/// A protocol that defines the contract for a service that handles the RESTful API
/// interactions for the Messaging feature.
public protocol MessagingServicing {

    /// Fetches all of the current user's chat threads.
    /// - Returns: An array of `ChatThread` objects.
    /// - Throws: An `APIError` if the network request fails.
    func fetchThreads() async throws -> [ChatThread]

    /// Fetches the message history for a specific chat thread.
    /// - Parameter chatId: The ID of the chat thread.
    /// - Returns: An array of `ChatMessage` objects.
    /// - Throws: An `APIError` if the network request fails.
    func fetchHistory(for chatId: String) async throws -> [ChatMessage]
}
