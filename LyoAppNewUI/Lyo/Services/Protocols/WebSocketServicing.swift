import Foundation

/// A protocol that defines the contract for a real-time messaging service using WebSockets.
public protocol WebSocketServicing {

    /// An asynchronous stream that yields incoming messages from the WebSocket connection.
    /// A consumer can loop over this stream using `for try await message in messages`.
    var messages: AsyncThrowingStream<ChatMessage, Error> { get }

    /// Connects to the WebSocket for a specific chat session and starts listening for messages.
    /// - Parameter chatId: The unique identifier for the chat to connect to.
    func connect(chatId: String)

    /// Disconnects from the WebSocket and terminates the session.
    func disconnect()

    /// Sends a text message over the WebSocket.
    /// - Parameter text: The message to send.
    /// - Throws: An error if the message fails to send.
    func sendMessage(_ text: String) async throws
}
