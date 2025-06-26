import Foundation
import Combine

// MARK: - Chat Manager
@MainActor
public class ChatManager: ObservableObject {
    // MARK: - Properties
    @Published public var chatRooms: [ChatRoom] = []
    @Published public var activeRoom: ChatRoom?
    @Published public var messages: [String: [ChatMessage]] = [:]
    @Published public var typingUsers: [String: Set<String>] = [:]
    @Published public var onlineUsers: [String: Set<String>] = [:]
    @Published public var unreadCounts: [String: Int] = [:]
    @Published public var isLoading = false
    @Published public var error: ChatError?
    
    private let webSocketManager: WebSocketManager
    private let userId: String
    private var cancellables = Set<AnyCancellable>()
    private var typingTimer: Timer?
    
    // MARK: - Initialization
    public init(webSocketManager: WebSocketManager, userId: String) {
        self.webSocketManager = webSocketManager
        self.userId = userId
        setupWebSocketHandlers()
    }
    
    deinit {
        cancellables.removeAll()
        typingTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Join a chat room
    public func joinRoom(_ roomId: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Send join room message
        let joinMessage = JoinRoomMessage(roomId: roomId, userId: userId)
        try await webSocketManager.send(message: joinMessage, type: "join_room")
        
        // Update active room
        if let room = chatRooms.first(where: { $0.id == roomId }) {
            activeRoom = room
        }
    }
    
    /// Leave a chat room
    public func leaveRoom(_ roomId: String) async throws {
        let leaveMessage = LeaveRoomMessage(roomId: roomId, userId: userId)
        try await webSocketManager.send(message: leaveMessage, type: "leave_room")
        
        // Clear active room if leaving current room
        if activeRoom?.id == roomId {
            activeRoom = nil
        }
    }
    
    /// Send a text message
    public func sendMessage(_ text: String, to roomId: String) async throws {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let message = ChatMessage(
            id: UUID().uuidString,
            roomId: roomId,
            senderId: userId,
            content: .text(text),
            timestamp: Date(),
            status: .sending
        )
        
        // Add message to local store with sending status
        addMessageToLocal(message)
        
        // Send message to server
        let sendMessage = SendMessageMessage(
            messageId: message.id,
            roomId: roomId,
            senderId: userId,
            content: text,
            messageType: "text"
        )
        
        do {
            try await webSocketManager.send(message: sendMessage, type: "send_message")
        } catch {
            // Update message status to failed
            updateMessageStatus(message.id, in: roomId, status: .failed)
            throw error
        }
    }
    
    /// Send an image message
    public func sendImage(_ imageData: Data, to roomId: String) async throws {
        let message = ChatMessage(
            id: UUID().uuidString,
            roomId: roomId,
            senderId: userId,
            content: .image(imageData),
            timestamp: Date(),
            status: .sending
        )
        
        // Add message to local store
        addMessageToLocal(message)
        
        // Upload image first (implementation would depend on your backend)
        let imageUrl = try await uploadImage(imageData)
        
        // Send message with image URL
        let sendMessage = SendMessageMessage(
            messageId: message.id,
            roomId: roomId,
            senderId: userId,
            content: imageUrl,
            messageType: "image"
        )
        
        do {
            try await webSocketManager.send(message: sendMessage, type: "send_message")
        } catch {
            updateMessageStatus(message.id, in: roomId, status: .failed)
            throw error
        }
    }
    
    /// Send typing indicator
    public func sendTypingIndicator(in roomId: String, isTyping: Bool) async throws {
        let typingMessage = TypingMessage(
            roomId: roomId,
            userId: userId,
            isTyping: isTyping
        )
        
        try await webSocketManager.send(message: typingMessage, type: "typing")
        
        // Setup timer to stop typing indicator after 3 seconds
        if isTyping {
            typingTimer?.invalidate()
            typingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
                Task {
                    try? await self?.sendTypingIndicator(in: roomId, isTyping: false)
                }
            }
        }
    }
    
    /// Create a new chat room
    public func createRoom(_ room: CreateRoomRequest) async throws {
        try await webSocketManager.send(message: room, type: "create_room")
    }
    
    /// Load chat history
    public func loadChatHistory(for roomId: String, limit: Int = 50, before messageId: String? = nil) async throws {
        let historyRequest = ChatHistoryRequest(
            roomId: roomId,
            limit: limit,
            beforeMessageId: messageId
        )
        
        try await webSocketManager.send(message: historyRequest, type: "load_history")
    }
    
    /// Mark messages as read
    public func markAsRead(roomId: String, messageId: String) async throws {
        let readMessage = ReadReceiptMessage(
            roomId: roomId,
            userId: userId,
            messageId: messageId
        )
        
        try await webSocketManager.send(message: readMessage, type: "mark_read")
        
        // Clear unread count
        unreadCounts[roomId] = 0
    }
    
    /// Delete a message
    public func deleteMessage(_ messageId: String, in roomId: String) async throws {
        let deleteMessage = DeleteMessageMessage(
            messageId: messageId,
            roomId: roomId,
            userId: userId
        )
        
        try await webSocketManager.send(message: deleteMessage, type: "delete_message")
    }
    
    /// Edit a message
    public func editMessage(_ messageId: String, in roomId: String, newContent: String) async throws {
        let editMessage = EditMessageMessage(
            messageId: messageId,
            roomId: roomId,
            userId: userId,
            newContent: newContent
        )
        
        try await webSocketManager.send(message: editMessage, type: "edit_message")
    }
    
    /// Get messages for a room
    public func getMessages(for roomId: String) -> [ChatMessage] {
        return messages[roomId] ?? []
    }
    
    /// Get typing users for a room
    public func getTypingUsers(for roomId: String) -> Set<String> {
        return typingUsers[roomId] ?? []
    }
    
    /// Get online users for a room
    public func getOnlineUsers(for roomId: String) -> Set<String> {
        return onlineUsers[roomId] ?? []
    }
    
    /// Get unread count for a room
    public func getUnreadCount(for roomId: String) -> Int {
        return unreadCounts[roomId] ?? 0
    }
    
    // MARK: - Private Methods
    
    private func setupWebSocketHandlers() {
        // Handle incoming messages
        webSocketManager.onMessage(type: "message") { [weak self] wsMessage in
            Task { @MainActor in
                await self?.handleIncomingMessage(wsMessage)
            }
        }
        
        // Handle message status updates
        webSocketManager.onMessage(type: "message_status") { [weak self] wsMessage in
            Task { @MainActor in
                await self?.handleMessageStatus(wsMessage)
            }
        }
        
        // Handle typing indicators
        webSocketManager.onMessage(type: "typing") { [weak self] wsMessage in
            Task { @MainActor in
                await self?.handleTypingIndicator(wsMessage)
            }
        }
        
        // Handle user presence
        webSocketManager.onMessage(type: "presence") { [weak self] wsMessage in
            Task { @MainActor in
                await self?.handlePresenceUpdate(wsMessage)
            }
        }
        
        // Handle room updates
        webSocketManager.onMessage(type: "room_update") { [weak self] wsMessage in
            Task { @MainActor in
                await self?.handleRoomUpdate(wsMessage)
            }
        }
        
        // Handle chat history
        webSocketManager.onMessage(type: "chat_history") { [weak self] wsMessage in
            Task { @MainActor in
                await self?.handleChatHistory(wsMessage)
            }
        }
        
        // Handle message deletion
        webSocketManager.onMessage(type: "message_deleted") { [weak self] wsMessage in
            Task { @MainActor in
                await self?.handleMessageDeletion(wsMessage)
            }
        }
        
        // Handle message editing
        webSocketManager.onMessage(type: "message_edited") { [weak self] wsMessage in
            Task { @MainActor in
                await self?.handleMessageEdit(wsMessage)
            }
        }
    }
    
    private func handleIncomingMessage(_ wsMessage: WebSocketMessage) async {
        do {
            let messageData = try wsMessage.decode(IncomingMessageData.self)
            
            let chatMessage = ChatMessage(
                id: messageData.id,
                roomId: messageData.roomId,
                senderId: messageData.senderId,
                content: parseMessageContent(messageData.content, type: messageData.messageType),
                timestamp: messageData.timestamp,
                status: .delivered
            )
            
            addMessageToLocal(chatMessage)
            
            // Update unread count if not in active room
            if activeRoom?.id != messageData.roomId {
                incrementUnreadCount(for: messageData.roomId)
            }
            
        } catch {
            self.error = ChatError.messageDecodingFailed(error.localizedDescription)
        }
    }
    
    private func handleMessageStatus(_ wsMessage: WebSocketMessage) async {
        do {
            let statusData = try wsMessage.decode(MessageStatusData.self)
            updateMessageStatus(statusData.messageId, in: statusData.roomId, status: statusData.status)
        } catch {
            self.error = ChatError.statusDecodingFailed(error.localizedDescription)
        }
    }
    
    private func handleTypingIndicator(_ wsMessage: WebSocketMessage) async {
        do {
            let typingData = try wsMessage.decode(TypingIndicatorData.self)
            updateTypingUsers(roomId: typingData.roomId, userId: typingData.userId, isTyping: typingData.isTyping)
        } catch {
            self.error = ChatError.typingDecodingFailed(error.localizedDescription)
        }
    }
    
    private func handlePresenceUpdate(_ wsMessage: WebSocketMessage) async {
        do {
            let presenceData = try wsMessage.decode(PresenceData.self)
            updateUserPresence(roomId: presenceData.roomId, userId: presenceData.userId, isOnline: presenceData.isOnline)
        } catch {
            self.error = ChatError.presenceDecodingFailed(error.localizedDescription)
        }
    }
    
    private func handleRoomUpdate(_ wsMessage: WebSocketMessage) async {
        do {
            let roomData = try wsMessage.decode(ChatRoom.self)
            updateChatRoom(roomData)
        } catch {
            self.error = ChatError.roomDecodingFailed(error.localizedDescription)
        }
    }
    
    private func handleChatHistory(_ wsMessage: WebSocketMessage) async {
        do {
            let historyData = try wsMessage.decode(ChatHistoryData.self)
            addHistoryMessages(historyData.messages, to: historyData.roomId)
        } catch {
            self.error = ChatError.historyDecodingFailed(error.localizedDescription)
        }
    }
    
    private func handleMessageDeletion(_ wsMessage: WebSocketMessage) async {
        do {
            let deletionData = try wsMessage.decode(MessageDeletionData.self)
            removeMessage(deletionData.messageId, from: deletionData.roomId)
        } catch {
            self.error = ChatError.deletionDecodingFailed(error.localizedDescription)
        }
    }
    
    private func handleMessageEdit(_ wsMessage: WebSocketMessage) async {
        do {
            let editData = try wsMessage.decode(MessageEditData.self)
            updateMessageContent(editData.messageId, in: editData.roomId, newContent: editData.newContent)
        } catch {
            self.error = ChatError.editDecodingFailed(error.localizedDescription)
        }
    }
    
    private func parseMessageContent(_ content: String, type: String) -> MessageContent {
        switch type {
        case "text":
            return .text(content)
        case "image":
            return .imageURL(content)
        case "file":
            return .fileURL(content)
        default:
            return .text(content)
        }
    }
    
    private func addMessageToLocal(_ message: ChatMessage) {
        if messages[message.roomId] == nil {
            messages[message.roomId] = []
        }
        messages[message.roomId]?.append(message)
        messages[message.roomId]?.sort { $0.timestamp < $1.timestamp }
    }
    
    private func updateMessageStatus(_ messageId: String, in roomId: String, status: MessageStatus) {
        guard var roomMessages = messages[roomId] else { return }
        
        if let index = roomMessages.firstIndex(where: { $0.id == messageId }) {
            roomMessages[index].status = status
            messages[roomId] = roomMessages
        }
    }
    
    private func updateTypingUsers(roomId: String, userId: String, isTyping: Bool) {
        if typingUsers[roomId] == nil {
            typingUsers[roomId] = Set<String>()
        }
        
        if isTyping {
            typingUsers[roomId]?.insert(userId)
        } else {
            typingUsers[roomId]?.remove(userId)
        }
    }
    
    private func updateUserPresence(roomId: String, userId: String, isOnline: Bool) {
        if onlineUsers[roomId] == nil {
            onlineUsers[roomId] = Set<String>()
        }
        
        if isOnline {
            onlineUsers[roomId]?.insert(userId)
        } else {
            onlineUsers[roomId]?.remove(userId)
        }
    }
    
    private func updateChatRoom(_ room: ChatRoom) {
        if let index = chatRooms.firstIndex(where: { $0.id == room.id }) {
            chatRooms[index] = room
        } else {
            chatRooms.append(room)
        }
    }
    
    private func addHistoryMessages(_ historyMessages: [ChatMessage], to roomId: String) {
        if messages[roomId] == nil {
            messages[roomId] = []
        }
        
        // Add messages and sort by timestamp
        messages[roomId]?.append(contentsOf: historyMessages)
        messages[roomId]?.sort { $0.timestamp < $1.timestamp }
    }
    
    private func removeMessage(_ messageId: String, from roomId: String) {
        messages[roomId]?.removeAll { $0.id == messageId }
    }
    
    private func updateMessageContent(_ messageId: String, in roomId: String, newContent: String) {
        guard var roomMessages = messages[roomId] else { return }
        
        if let index = roomMessages.firstIndex(where: { $0.id == messageId }) {
            roomMessages[index].content = .text(newContent)
            roomMessages[index].isEdited = true
            messages[roomId] = roomMessages
        }
    }
    
    private func incrementUnreadCount(for roomId: String) {
        unreadCounts[roomId] = (unreadCounts[roomId] ?? 0) + 1
    }
    
    private func uploadImage(_ imageData: Data) async throws -> String {
        // This would implement actual image upload to your backend
        // For now, return a placeholder URL
        return "https://example.com/uploaded-image.jpg"
    }
}

// MARK: - Supporting Types

public struct ChatRoom: Codable, Identifiable {
    public let id: String
    public let name: String
    public let description: String?
    public let type: RoomType
    public let participants: [String]
    public let createdBy: String
    public let createdAt: Date
    public let lastActivity: Date
    public let isPrivate: Bool
    
    public enum RoomType: String, Codable {
        case direct = "direct"
        case group = "group"
        case channel = "channel"
        case course = "course"
    }
}

public struct ChatMessage: Codable, Identifiable {
    public let id: String
    public let roomId: String
    public let senderId: String
    public var content: MessageContent
    public let timestamp: Date
    public var status: MessageStatus
    public var isEdited = false
    public var replyTo: String?
}

public enum MessageContent: Codable {
    case text(String)
    case image(Data)
    case imageURL(String)
    case fileURL(String)
    case system(String)
    
    public var displayText: String {
        switch self {
        case .text(let text):
            return text
        case .image(_):
            return "📷 Image"
        case .imageURL(_):
            return "📷 Image"
        case .fileURL(_):
            return "📎 File"
        case .system(let text):
            return text
        }
    }
}

public enum MessageStatus: String, Codable {
    case sending
    case sent
    case delivered
    case read
    case failed
}

public enum ChatError: LocalizedError {
    case messageDecodingFailed(String)
    case statusDecodingFailed(String)
    case typingDecodingFailed(String)
    case presenceDecodingFailed(String)
    case roomDecodingFailed(String)
    case historyDecodingFailed(String)
    case deletionDecodingFailed(String)
    case editDecodingFailed(String)
    case uploadFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .messageDecodingFailed(let error):
            return "Failed to decode message: \(error)"
        case .statusDecodingFailed(let error):
            return "Failed to decode status: \(error)"
        case .typingDecodingFailed(let error):
            return "Failed to decode typing indicator: \(error)"
        case .presenceDecodingFailed(let error):
            return "Failed to decode presence: \(error)"
        case .roomDecodingFailed(let error):
            return "Failed to decode room: \(error)"
        case .historyDecodingFailed(let error):
            return "Failed to decode history: \(error)"
        case .deletionDecodingFailed(let error):
            return "Failed to decode deletion: \(error)"
        case .editDecodingFailed(let error):
            return "Failed to decode edit: \(error)"
        case .uploadFailed(let error):
            return "Upload failed: \(error)"
        }
    }
}

// MARK: - Message Data Types

private struct JoinRoomMessage: Codable {
    let roomId: String
    let userId: String
}

private struct LeaveRoomMessage: Codable {
    let roomId: String
    let userId: String
}

private struct SendMessageMessage: Codable {
    let messageId: String
    let roomId: String
    let senderId: String
    let content: String
    let messageType: String
}

private struct TypingMessage: Codable {
    let roomId: String
    let userId: String
    let isTyping: Bool
}

public struct CreateRoomRequest: Codable {
    public let name: String
    public let description: String?
    public let type: ChatRoom.RoomType
    public let participants: [String]
    public let isPrivate: Bool
    
    public init(name: String, description: String? = nil, type: ChatRoom.RoomType, participants: [String], isPrivate: Bool = false) {
        self.name = name
        self.description = description
        self.type = type
        self.participants = participants
        self.isPrivate = isPrivate
    }
}

private struct ChatHistoryRequest: Codable {
    let roomId: String
    let limit: Int
    let beforeMessageId: String?
}

private struct ReadReceiptMessage: Codable {
    let roomId: String
    let userId: String
    let messageId: String
}

private struct DeleteMessageMessage: Codable {
    let messageId: String
    let roomId: String
    let userId: String
}

private struct EditMessageMessage: Codable {
    let messageId: String
    let roomId: String
    let userId: String
    let newContent: String
}

// Response data types
private struct IncomingMessageData: Codable {
    let id: String
    let roomId: String
    let senderId: String
    let content: String
    let messageType: String
    let timestamp: Date
}

private struct MessageStatusData: Codable {
    let messageId: String
    let roomId: String
    let status: MessageStatus
}

private struct TypingIndicatorData: Codable {
    let roomId: String
    let userId: String
    let isTyping: Bool
}

private struct PresenceData: Codable {
    let roomId: String
    let userId: String
    let isOnline: Bool
}

private struct ChatHistoryData: Codable {
    let roomId: String
    let messages: [ChatMessage]
}

private struct MessageDeletionData: Codable {
    let messageId: String
    let roomId: String
}

private struct MessageEditData: Codable {
    let messageId: String
    let roomId: String
    let newContent: String
}
