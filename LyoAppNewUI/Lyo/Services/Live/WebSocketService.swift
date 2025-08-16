import Foundation

public final class WebSocketService: WebSocketServicing {

    // MARK: - Public Properties

    public let messages: AsyncThrowingStream<ChatMessage, Error>

    // MARK: - Private Properties

    private var messageContinuation: AsyncThrowingStream<ChatMessage, Error>.Continuation?
    private let webSocketURL: URL
    private var webSocketTask: URLSessionWebSocketTask?
    private var pingTimer: Timer?

    // MARK: - Initialization

    public init(webSocketURL: URL) {
        self.webSocketURL = webSocketURL

        var continuation: AsyncThrowingStream<ChatMessage, Error>.Continuation?
        self.messages = AsyncThrowingStream { continuation = $0 }
        self.messageContinuation = continuation
    }

    // MARK: - WebSocketServicing Conformance

    public func connect(chatId: String) {
        guard webSocketTask == nil else { return }

        let url = webSocketURL.appendingPathComponent("/v1/ws/chats/\(chatId)")
        let request = URLRequest(url: url)

        webSocketTask = URLSession.shared.webSocketTask(with: request)
        webSocketTask?.resume()

        startListening()
        startPinging()
    }

    public func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        pingTimer?.invalidate()
        pingTimer = nil
        messageContinuation?.finish()
    }

    public func sendMessage(_ text: String) async throws {
        guard let webSocketTask = webSocketTask else {
            throw URLError(.badURL) // Or a custom error
        }
        // In a real app, you would likely send a JSON object, not just raw text.
        // For example: `{"type": "message", "content": "hello"}`
        let message = URLSessionWebSocketTask.Message.string(text)
        try await webSocketTask.send(message)
    }

    // MARK: - Private Methods

    private func startListening() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let message):
                self.handle(message)
                self.startListening() // Continue listening for the next message
            case .failure(let error):
                self.messageContinuation?.finish(throwing: error)
            }
        }
    }

    private func handle(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            // Assuming the server sends JSON strings.
            guard let data = text.data(using: .utf8) else { return }
            do {
                let chatMessage = try JSONDecoder().decode(ChatMessage.self, from: data)
                messageContinuation?.yield(chatMessage)
            } catch {
                messageContinuation?.finish(throwing: error)
            }
        case .data(let data):
            do {
                let chatMessage = try JSONDecoder().decode(ChatMessage.self, from: data)
                messageContinuation?.yield(chatMessage)
            } catch {
                messageContinuation?.finish(throwing: error)
            }
        @unknown default:
            break
        }
    }

    private func startPinging() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.webSocketTask?.sendPing { error in
                if let error = error {
                    print("WebSocket ping failed: \(error)")
                    // You might want to handle this by attempting to reconnect.
                }
            }
        }
    }

    deinit {
        disconnect()
    }
}
