import Foundation
import Combine
import Network

/// Enhanced WebSocket Manager for real-time features in Phase 3
class WebSocketManager: ObservableObject {
    static let shared = WebSocketManager()
    
    @Published var isConnected: Bool = false
    @Published var connectionState: ConnectionState = .disconnected
    @Published var lastMessage: WebSocketMessage?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private let configManager = ConfigurationManager.shared
    private let networkManager = EnhancedNetworkManager.shared
    
    private var cancellables = Set<AnyCancellable>()
    private var reconnectTimer: Timer?
    private var heartbeatTimer: Timer?
    
    // Connection management
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private var isManualDisconnect = false
    
    // Message handlers
    private var messageHandlers: [String: (WebSocketMessage) -> Void] = [:]
    
    private init() {
        setupNetworkMonitoring()
    }
    
    deinit {
        disconnect()
    }
    
    // MARK: - Connection Management
    
    func connect() {
        guard !isConnected else { return }
        
        // Check if user is authenticated
        guard EnhancedAuthService.shared.isAuthenticated,
              let token = EnhancedAuthService.shared.currentToken else {
            print("⚠️ Cannot connect WebSocket: User not authenticated")
            return
        }
        
        isManualDisconnect = false
        connectionState = .connecting
        
        // Build WebSocket URL with authentication
        guard let url = buildWebSocketURL(token: token) else {
            connectionState = .disconnected
            return
        }
        
        // Create URLSession with WebSocket configuration
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        webSocketTask = urlSession?.webSocketTask(with: url)
        
        // Start connection
        webSocketTask?.resume()
        
        // Start listening for messages
        receiveMessage()
        
        print("🔌 Connecting to WebSocket: \(url)")
    }
    
    func disconnect() {
        isManualDisconnect = true
        connectionState = .disconnecting
        
        // Send close message
        let closeCode = URLSessionWebSocketTask.CloseCode.normalClosure
        webSocketTask?.cancel(with: closeCode, reason: nil)
        
        cleanup()
        
        print("🔌 WebSocket disconnected")
    }
    
    private func cleanup() {
        webSocketTask = nil
        urlSession = nil
        isConnected = false
        connectionState = .disconnected
        
        // Cancel timers
        reconnectTimer?.invalidate()
        heartbeatTimer?.invalidate()
        reconnectTimer = nil
        heartbeatTimer = nil
    }
    
    // MARK: - Message Handling
    
    func sendMessage(_ message: WebSocketMessage) {
        guard isConnected else {
            print("⚠️ Cannot send message: WebSocket not connected")
            return
        }
        
        do {
            let messageData = try JSONEncoder().encode(message)
            let messageString = String(data: messageData, encoding: .utf8) ?? ""
            
            webSocketTask?.send(.string(messageString)) { error in
                if let error = error {
                    print("❌ Failed to send WebSocket message: \(error)")
                }
            }
        } catch {
            print("❌ Failed to encode WebSocket message: \(error)")
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleReceivedMessage(message)
                
                // Continue listening for more messages
                self?.receiveMessage()
                
            case .failure(let error):
                print("❌ WebSocket receive error: \(error)")
                self?.handleConnectionError(error)
            }
        }
    }
    
    private func handleReceivedMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            parseMessage(from: text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                parseMessage(from: text)
            }
        @unknown default:
            print("⚠️ Unknown WebSocket message type")
        }
    }
    
    private func parseMessage(from text: String) {
        do {
            let message = try JSONDecoder().decode(WebSocketMessage.self, from: text.data(using: .utf8)!)
            
            DispatchQueue.main.async {
                self.lastMessage = message
                self.processMessage(message)
            }
        } catch {
            print("❌ Failed to parse WebSocket message: \(error)")
        }
    }
    
    private func processMessage(_ message: WebSocketMessage) {
        // Call registered message handlers
        if let handler = messageHandlers[message.type] {
            handler(message)
        }
        
        // Handle system messages
        switch message.type {
        case "heartbeat":
            sendHeartbeatResponse()
        case "auth_required":
            handleAuthRequired()
        case "connection_established":
            handleConnectionEstablished()
        default:
            break
        }
    }
    
    // MARK: - Message Handler Registration
    
    func registerMessageHandler(for messageType: String, handler: @escaping (WebSocketMessage) -> Void) {
        messageHandlers[messageType] = handler
    }
    
    func unregisterMessageHandler(for messageType: String) {
        messageHandlers.removeValue(forKey: messageType)
    }
    
    // MARK: - Connection Helpers
    
    private func buildWebSocketURL(token: String) -> URL? {
        guard var urlComponents = URLComponents(string: configManager.backendWebSocketURL) else {
            return nil
        }
        
        // Add authentication token as query parameter
        urlComponents.queryItems = [
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "client", value: "ios"),
            URLQueryItem(name: "version", value: Bundle.main.appVersion)
        ]
        
        return urlComponents.url
    }
    
    private func setupNetworkMonitoring() {
        // Monitor network connectivity changes
        networkManager.$isOnline
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isOnline in
                if isOnline && !self?.isConnected == true && !self?.isManualDisconnect == true {
                    // Network came back online, try to reconnect
                    self?.reconnectWithDelay()
                } else if !isOnline && self?.isConnected == true {
                    // Network went offline
                    self?.connectionState = .disconnected
                    self?.isConnected = false
                }
            }
            .store(in: &cancellables)
        
        // Monitor authentication state changes
        EnhancedAuthService.shared.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    self?.connect()
                } else {
                    self?.disconnect()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Reconnection Logic
    
    private func reconnectWithDelay() {
        guard reconnectAttempts < maxReconnectAttempts else {
            print("❌ Max reconnection attempts reached")
            return
        }
        
        let delay = pow(2.0, Double(reconnectAttempts)) // Exponential backoff
        reconnectAttempts += 1
        
        print("🔄 Reconnecting in \(delay) seconds (attempt \(reconnectAttempts)/\(maxReconnectAttempts))")
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.connect()
        }
    }
    
    private func handleConnectionError(_ error: Error) {
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectionState = .disconnected
        }
        
        if !isManualDisconnect && networkManager.isOnline {
            reconnectWithDelay()
        }
    }
    
    // MARK: - Heartbeat Management
    
    private func startHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
    }
    
    private func sendHeartbeat() {
        let heartbeatMessage = WebSocketMessage(
            type: "heartbeat",
            data: ["timestamp": Date().timeIntervalSince1970]
        )
        sendMessage(heartbeatMessage)
    }
    
    private func sendHeartbeatResponse() {
        let response = WebSocketMessage(
            type: "heartbeat_response",
            data: ["timestamp": Date().timeIntervalSince1970]
        )
        sendMessage(response)
    }
    
    // MARK: - System Message Handlers
    
    private func handleAuthRequired() {
        print("⚠️ WebSocket authentication required")
        disconnect()
        
        // Try to refresh token and reconnect
        EnhancedAuthService.shared.refreshToken { [weak self] success in
            if success {
                self?.connect()
            }
        }
    }
    
    private func handleConnectionEstablished() {
        DispatchQueue.main.async {
            self.isConnected = true
            self.connectionState = .connected
            self.reconnectAttempts = 0
        }
        
        startHeartbeat()
        
        // Provide haptic feedback for successful connection
        HapticManager.shared.impact(.light)
        
        print("✅ WebSocket connection established")
    }
}

// MARK: - URLSessionWebSocketDelegate

extension WebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("✅ WebSocket connection opened")
        handleConnectionEstablished()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("🔌 WebSocket connection closed with code: \(closeCode)")
        
        DispatchQueue.main.async {
            self.cleanup()
        }
        
        // Attempt reconnection if not manually disconnected
        if !isManualDisconnect && networkManager.isOnline {
            reconnectWithDelay()
        }
    }
}

// MARK: - Supporting Types

enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case reconnecting
    
    var description: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        case .disconnecting: return "Disconnecting"
        case .reconnecting: return "Reconnecting"
        }
    }
}

struct WebSocketMessage: Codable {
    let id: String
    let type: String
    let data: [String: Any]
    let timestamp: Date
    
    init(type: String, data: [String: Any] = [:]) {
        self.id = UUID().uuidString
        self.type = type
        self.data = data
        self.timestamp = Date()
    }
    
    // Custom encoding/decoding for [String: Any]
    enum CodingKeys: String, CodingKey {
        case id, type, data, timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        // Decode data as JSON
        let dataContainer = try container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .data)
        var dataDictionary: [String: Any] = [:]
        
        for key in dataContainer.allKeys {
            if let stringValue = try? dataContainer.decode(String.self, forKey: key) {
                dataDictionary[key.stringValue] = stringValue
            } else if let intValue = try? dataContainer.decode(Int.self, forKey: key) {
                dataDictionary[key.stringValue] = intValue
            } else if let doubleValue = try? dataContainer.decode(Double.self, forKey: key) {
                dataDictionary[key.stringValue] = doubleValue
            } else if let boolValue = try? dataContainer.decode(Bool.self, forKey: key) {
                dataDictionary[key.stringValue] = boolValue
            }
        }
        
        data = dataDictionary
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(timestamp, forKey: .timestamp)
        
        // Encode data as JSON
        var dataContainer = container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .data)
        
        for (key, value) in data {
            let codingKey = DynamicCodingKeys(stringValue: key)!
            
            if let stringValue = value as? String {
                try dataContainer.encode(stringValue, forKey: codingKey)
            } else if let intValue = value as? Int {
                try dataContainer.encode(intValue, forKey: codingKey)
            } else if let doubleValue = value as? Double {
                try dataContainer.encode(doubleValue, forKey: codingKey)
            } else if let boolValue = value as? Bool {
                try dataContainer.encode(boolValue, forKey: codingKey)
            }
        }
    }
}

struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = String(intValue)
    }
}

// MARK: - WebSocket Feature Extensions

extension WebSocketManager {
    
    // MARK: - Learning Progress Updates
    
    func subscribeToLearningProgress() {
        registerMessageHandler(for: "learning_progress") { message in
            if let progressData = message.data["progress"] as? [String: Any] {
                // Handle learning progress update
                NotificationCenter.default.post(
                    name: .learningProgressUpdated,
                    object: progressData
                )
            }
        }
    }
    
    // MARK: - Feed Updates
    
    func subscribeToFeedUpdates() {
        registerMessageHandler(for: "feed_update") { message in
            if let feedData = message.data["posts"] as? [[String: Any]] {
                // Handle feed update
                NotificationCenter.default.post(
                    name: .feedUpdated,
                    object: feedData
                )
            }
        }
    }
    
    // MARK: - Live Chat
    
    func joinChatRoom(_ roomId: String) {
        let joinMessage = WebSocketMessage(
            type: "join_room",
            data: ["room_id": roomId]
        )
        sendMessage(joinMessage)
    }
    
    func leaveChatRoom(_ roomId: String) {
        let leaveMessage = WebSocketMessage(
            type: "leave_room",
            data: ["room_id": roomId]
        )
        sendMessage(leaveMessage)
    }
    
    func sendChatMessage(_ text: String, to roomId: String) {
        let chatMessage = WebSocketMessage(
            type: "chat_message",
            data: [
                "room_id": roomId,
                "message": text
            ]
        )
        sendMessage(chatMessage)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let learningProgressUpdated = Notification.Name("learningProgressUpdated")
    static let feedUpdated = Notification.Name("feedUpdated")
    static let chatMessageReceived = Notification.Name("chatMessageReceived")
}
