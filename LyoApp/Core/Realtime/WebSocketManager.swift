import Foundation
import Network
import Combine

// MARK: - WebSocket Manager
@MainActor
public class WebSocketManager: NSObject, ObservableObject {
    // MARK: - Properties
    @Published public var connectionState: ConnectionState = .disconnected
    @Published public var error: WebSocketError?
    @Published public var isReconnecting = false
    @Published public var lastMessageTime: Date?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var cancellables = Set<AnyCancellable>()
    private var reconnectTimer: Timer?
    private var heartbeatTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private let heartbeatInterval: TimeInterval = 30
    private let reconnectDelay: TimeInterval = 2
    
    // Network monitoring
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "WebSocketNetworkMonitor")
    
    // Message handlers
    private var messageHandlers: [String: (WebSocketMessage) -> Void] = [:]
    private var connectionHandlers: [(ConnectionState) -> Void] = []
    
    // MARK: - Connection State
    public enum ConnectionState {
        case disconnected
        case connecting
        case connected
        case reconnecting
        case failed(Error)
    }
    
    // MARK: - Initialization
    public override init() {
        super.init()
        setupNetworkMonitoring()
    }
    
    deinit {
        disconnect()
        networkMonitor.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Connect to WebSocket server
    public func connect(to url: URL, headers: [String: String] = [:]) {
        guard connectionState != .connected && connectionState != .connecting else { return }
        
        connectionState = .connecting
        error = nil
        
        // Setup URL session
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 60
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        
        // Create request with headers
        var request = URLRequest(url: url)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Create WebSocket task
        webSocketTask = urlSession?.webSocketTask(with: request)
        webSocketTask?.resume()
        
        // Start listening for messages
        receiveMessage()
        
        // Start heartbeat
        startHeartbeat()
    }
    
    /// Disconnect from WebSocket server
    public func disconnect() {
        stopHeartbeat()
        stopReconnectTimer()
        
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        urlSession = nil
        
        connectionState = .disconnected
        reconnectAttempts = 0
        isReconnecting = false
    }
    
    /// Send message
    public func send<T: Codable>(message: T, type: String) async throws {
        guard connectionState == .connected else {
            throw WebSocketError.notConnected
        }
        
        let webSocketMessage = WebSocketMessage(
            id: UUID().uuidString,
            type: type,
            data: try JSONEncoder().encode(message),
            timestamp: Date()
        )
        
        let messageData = try JSONEncoder().encode(webSocketMessage)
        let message = URLSessionWebSocketTask.Message.data(messageData)
        
        try await webSocketTask?.send(message)
    }
    
    /// Send text message
    public func sendText(_ text: String, type: String) async throws {
        let webSocketMessage = WebSocketMessage(
            id: UUID().uuidString,
            type: type,
            data: text.data(using: .utf8) ?? Data(),
            timestamp: Date()
        )
        
        let messageData = try JSONEncoder().encode(webSocketMessage)
        let message = URLSessionWebSocketTask.Message.data(messageData)
        
        try await webSocketTask?.send(message)
    }
    
    /// Send ping
    public func sendPing() async throws {
        guard connectionState == .connected else { return }
        try await webSocketTask?.sendPing { [weak self] error in
            if let error = error {
                Task { @MainActor in
                    self?.handleError(WebSocketError.pingFailed(error.localizedDescription))
                }
            }
        }
    }
    
    /// Register message handler
    public func onMessage(type: String, handler: @escaping (WebSocketMessage) -> Void) {
        messageHandlers[type] = handler
    }
    
    /// Register connection state handler
    public func onConnectionStateChange(handler: @escaping (ConnectionState) -> Void) {
        connectionHandlers.append(handler)
    }
    
    /// Remove message handler
    public func removeMessageHandler(for type: String) {
        messageHandlers[type] = nil
    }
    
    /// Force reconnect
    public func reconnect() {
        guard let url = webSocketTask?.originalRequest?.url else { return }
        
        disconnect()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.connect(to: url)
        }
    }
    
    // MARK: - Private Methods
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            Task { @MainActor in
                await self?.handleReceivedMessage(result)
            }
        }
    }
    
    private func handleReceivedMessage(_ result: Result<URLSessionWebSocketTask.Message, Error>) async {
        switch result {
        case .success(let message):
            lastMessageTime = Date()
            
            switch message {
            case .data(let data):
                await processMessageData(data)
            case .string(let text):
                await processMessageText(text)
            @unknown default:
                break
            }
            
            // Continue receiving messages
            receiveMessage()
            
        case .failure(let error):
            handleError(WebSocketError.receiveFailed(error.localizedDescription))
        }
    }
    
    private func processMessageData(_ data: Data) async {
        do {
            let webSocketMessage = try JSONDecoder().decode(WebSocketMessage.self, from: data)
            
            // Handle system messages
            if webSocketMessage.type == "ping" {
                try? await sendText("pong", type: "pong")
                return
            }
            
            // Call registered handlers
            if let handler = messageHandlers[webSocketMessage.type] {
                handler(webSocketMessage)
            }
            
            // Generic message handler
            if let handler = messageHandlers["*"] {
                handler(webSocketMessage)
            }
            
        } catch {
            handleError(WebSocketError.messageDecodingFailed(error.localizedDescription))
        }
    }
    
    private func processMessageText(_ text: String) async {
        // Handle simple text messages
        let webSocketMessage = WebSocketMessage(
            id: UUID().uuidString,
            type: "text",
            data: text.data(using: .utf8) ?? Data(),
            timestamp: Date()
        )
        
        if let handler = messageHandlers["text"] {
            handler(webSocketMessage)
        }
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                await self?.handleNetworkChange(path)
            }
        }
        networkMonitor.start(queue: networkQueue)
    }
    
    private func handleNetworkChange(_ path: NWPath) async {
        if path.status == .satisfied && connectionState == .failed(.none) {
            // Network is back, attempt reconnection
            if let url = webSocketTask?.originalRequest?.url {
                attemptReconnection(to: url)
            }
        } else if path.status != .satisfied && connectionState == .connected {
            // Network lost
            connectionState = .failed(WebSocketError.networkUnavailable)
            notifyConnectionHandlers()
        }
    }
    
    private func attemptReconnection(to url: URL) {
        guard reconnectAttempts < maxReconnectAttempts else {
            connectionState = .failed(WebSocketError.maxReconnectAttemptsReached)
            notifyConnectionHandlers()
            return
        }
        
        isReconnecting = true
        reconnectAttempts += 1
        
        let delay = reconnectDelay * Double(reconnectAttempts)
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.connect(to: url)
            }
        }
    }
    
    private func startHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            Task {
                try? await self?.sendPing()
            }
        }
    }
    
    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    private func handleError(_ error: WebSocketError) {
        self.error = error
        
        // Attempt reconnection for certain errors
        switch error {
        case .networkUnavailable, .connectionLost, .receiveFailed:
            if let url = webSocketTask?.originalRequest?.url {
                connectionState = .failed(error)
                attemptReconnection(to: url)
            }
        default:
            connectionState = .failed(error)
        }
        
        notifyConnectionHandlers()
    }
    
    private func notifyConnectionHandlers() {
        for handler in connectionHandlers {
            handler(connectionState)
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension WebSocketManager: URLSessionWebSocketDelegate {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        Task { @MainActor in
            connectionState = .connected
            reconnectAttempts = 0
            isReconnecting = false
            error = nil
            notifyConnectionHandlers()
        }
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        Task { @MainActor in
            connectionState = .disconnected
            stopHeartbeat()
            notifyConnectionHandlers()
        }
    }
}

// MARK: - Supporting Types

public struct WebSocketMessage: Codable {
    public let id: String
    public let type: String
    public let data: Data
    public let timestamp: Date
    
    public func decode<T: Codable>(_ type: T.Type) throws -> T {
        return try JSONDecoder().decode(type, from: data)
    }
    
    public func decodeText() -> String? {
        return String(data: data, encoding: .utf8)
    }
}

public enum WebSocketError: LocalizedError {
    case notConnected
    case connectionFailed(String)
    case connectionLost
    case networkUnavailable
    case messageDecodingFailed(String)
    case receiveFailed(String)
    case sendFailed(String)
    case pingFailed(String)
    case maxReconnectAttemptsReached
    
    public var errorDescription: String? {
        switch self {
        case .notConnected:
            return "WebSocket is not connected"
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .connectionLost:
            return "Connection lost"
        case .networkUnavailable:
            return "Network is not available"
        case .messageDecodingFailed(let message):
            return "Failed to decode message: \(message)"
        case .receiveFailed(let message):
            return "Failed to receive message: \(message)"
        case .sendFailed(let message):
            return "Failed to send message: \(message)"
        case .pingFailed(let message):
            return "Ping failed: \(message)"
        case .maxReconnectAttemptsReached:
            return "Maximum reconnection attempts reached"
        }
    }
}
