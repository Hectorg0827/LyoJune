import Foundation
import Combine
import Network
import Security

// KeychainHelper.swift should be available in scope
// ConfigurationManager.swift should be available in scope

// MARK: - WebSocket Manager
final class WebSocketManager: NSObject, ObservableObject {
    static let shared = WebSocketManager()
    
    @Published var isConnected: Bool = false
    @Published var connectionState: ConnectionState = .disconnected
    @Published var lastMessage: WebSocketMessage?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private let messageQueue = DispatchQueue(label: "websocket.message.queue")
    private var cancellables = Set<AnyCancellable>()
    
    // Configuration
    private let maxReconnectAttempts = 5
    private var reconnectAttempts = 0
    private var reconnectTimer: Timer?
    // Remove HapticManager.shared access from init to avoid MainActor issues
    
    override init() {
        super.init()
        setupURLSession()
        setupNetworkMonitoring()
    }
    
    // MARK: - Public Methods
    
    func reconnectIfNeeded() {
        if !isConnected && connectionState == .disconnected {
            connect()
        }
    }
    
    func connect() {
        guard !isConnected else { return }
        
        let config = ConfigurationManager.shared
        let urlString = config.webSocketURL
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid WebSocket URL: \(urlString)")
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        
        // Add authentication header if available
        if let token = KeychainHelper.shared.retrieve(for: "access_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        webSocketTask = urlSession?.webSocketTask(with: request)
        webSocketTask?.delegate = self
        webSocketTask?.resume()
        
        receiveMessage()
        
        DispatchQueue.main.async {
            self.connectionState = .connecting
        }
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        reconnectAttempts = 0
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectionState = .disconnected
        }
    }
    
    func pauseConnection() {
        // Temporarily pause the connection without full disconnect
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        
        DispatchQueue.main.async {
            self.connectionState = .connecting // Paused state
        }
        print("🔸 WebSocket connection paused")
    }
    
    func send<T: Codable>(_ message: T) {
        guard isConnected, let webSocketTask = webSocketTask else {
            print("❌ WebSocket not connected, cannot send message")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(message)
            let message = URLSessionWebSocketTask.Message.data(data)
            
            webSocketTask.send(message) { [weak self] error in
                if let error = error {
                    print("❌ WebSocket send error: \(error)")
                    self?.handleError(error)
                }
            }
        } catch {
            print("❌ Failed to encode WebSocket message: \(error)")
        }
    }
    
    func sendText(_ text: String) {
        guard isConnected, let webSocketTask = webSocketTask else {
            print("❌ WebSocket not connected, cannot send text")
            return
        }
        
        let message = URLSessionWebSocketTask.Message.string(text)
        webSocketTask.send(message) { [weak self] error in
            if let error = error {
                print("❌ WebSocket send error: \(error)")
                self?.handleError(error)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupURLSession() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 30
        urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    private func setupNetworkMonitoring() {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "network.monitor")
        
        monitor.pathUpdateHandler = { [weak self] path in
            let shouldReconnect = path.status == .satisfied
            let wasConnected = self?.isConnected ?? false
            
            // Auto-reconnect if network is available
            if shouldReconnect && !wasConnected && self?.reconnectAttempts ?? 0 < self?.maxReconnectAttempts ?? 5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self?.attemptReconnect()
                }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.receiveMessage() // Continue receiving
                
            case .failure(let error):
                print("❌ WebSocket receive error: \(error)")
                self?.handleError(error)
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        messageQueue.async {
            switch message {
            case .string(let text):
                self.processTextMessage(text)
                
            case .data(let data):
                self.processDataMessage(data)
                
            @unknown default:
                print("⚠️ Unknown WebSocket message type")
            }
        }
    }
    
    private func processTextMessage(_ text: String) {
        // Process text message
        print("📨 WebSocket text message: \(text)")
        
        // Try to decode as JSON
        if let data = text.data(using: .utf8) {
            processDataMessage(data)
        }
    }
    
    private func processDataMessage(_ data: Data) {
        do {
            let message = try JSONDecoder().decode(WebSocketMessage.self, from: data)
            
            DispatchQueue.main.async {
                self.lastMessage = message
                Task { @MainActor in
                    HapticManager.shared.impactOccurred(style: .light)
                }
            }
            
            // Handle different message types
            handleWebSocketMessage(message)
            
        } catch {
            print("❌ Failed to decode WebSocket message: \(error)")
        }
    }
    
    private func handleWebSocketMessage(_ message: WebSocketMessage) {
        switch message.type {
        case .notification:
            NotificationCenter.default.post(
                name: .webSocketNotification,
                object: message.data
            )
            
        case .userUpdate:
            NotificationCenter.default.post(
                name: .webSocketUserUpdate,
                object: message.data
            )
            
        case .liveUpdate:
            NotificationCenter.default.post(
                name: .webSocketLiveUpdate,
                object: message.data
            )
            
        case .chat:
            NotificationCenter.default.post(
                name: .webSocketChatMessage,
                object: message.data
            )
        }
    }
    
    private func handleError(_ error: Error) {
        print("❌ WebSocket error: \(error)")
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectionState = .error(error)
        }
        
        // Attempt reconnection
        attemptReconnect()
    }
    
    private func attemptReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            print("❌ Max reconnect attempts reached")
            return
        }
        
        reconnectAttempts += 1
        let delay = TimeInterval(reconnectAttempts * 2) // Exponential backoff
        
        print("🔄 Attempting reconnect \(reconnectAttempts)/\(maxReconnectAttempts) in \(delay)s")
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.connect()
        }
    }
    
    deinit {
        disconnect()
    }
}

// MARK: - URLSessionWebSocketDelegate

extension WebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("✅ WebSocket connected")
        
        DispatchQueue.main.async {
            self.isConnected = true
            self.connectionState = .connected
            self.reconnectAttempts = 0
            Task { @MainActor in
                HapticManager.shared.impactOccurred(style: .light)
            }
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("🔌 WebSocket disconnected with code: \(closeCode)")
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectionState = .disconnected
        }
        
        // Attempt reconnection if not intentionally closed
        if closeCode != .goingAway {
            attemptReconnect()
        }
    }
}

// MARK: - URLSessionDelegate

extension WebSocketManager: URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Handle SSL certificate validation
        completionHandler(.performDefaultHandling, nil)
    }
}

// MARK: - Supporting Types

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case error(Error)
    
    static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected), (.connecting, .connecting), (.connected, .connected):
            return true
        case (.error(_), .error(_)):
            return true
        default:
            return false
        }
    }
}

struct WebSocketMessage: Codable {
    let type: MessageType
    let data: [String: Any]
    let timestamp: Date
    
    enum MessageType: String, Codable {
        case notification
        case userUpdate
        case liveUpdate
        case chat
    }
    
    enum CodingKeys: String, CodingKey {
        case type, data, timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(MessageType.self, forKey: .type)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        // Use JSONSerialization for [String: Any] since it's not directly Codable
        if let dataValue = try? container.decode(Data.self, forKey: .data) {
            data = try JSONSerialization.jsonObject(with: dataValue) as? [String: Any] ?? [:]
        } else {
            data = [:]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(timestamp, forKey: .timestamp)
        // Convert [String: Any] to Data for encoding
        let dataValue = try JSONSerialization.data(withJSONObject: data)
        try container.encode(dataValue, forKey: .data)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let webSocketNotification = Notification.Name("webSocketNotification")
    static let webSocketUserUpdate = Notification.Name("webSocketUserUpdate")
    static let webSocketLiveUpdate = Notification.Name("webSocketLiveUpdate")
    static let webSocketChatMessage = Notification.Name("webSocketChatMessage")
}
