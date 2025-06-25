import SwiftUI

struct ChatView: View {
    @Binding var conversation: Conversation?
    @Binding var isPresented: Bool
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let conversation = conversation {
                    // Header
                    HStack(spacing: 12) {
                        Button(action: {
                            closeChatView()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        
                        // User avatar
                        Circle()
                            .fill(LinearGradient(
                                colors: conversation.avatarColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(conversation.initials)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(conversation.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("Online")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            // Video call action
                        }) {
                            Image(systemName: "video")
                                .font(.system(size: 18))
                                .foregroundColor(.primary)
                        }
                        
                        Button(action: {
                            // Audio call action
                        }) {
                            Image(systemName: "phone")
                                .font(.system(size: 18))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                    
                    // Messages
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                ChatMessageView(message: message)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    
                    // Message input
                    HStack(spacing: 12) {
                        Button(action: {
                            // Attachment action
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }
                        
                        HStack(spacing: 8) {
                            TextField("Type a message...", text: $messageText, axis: .vertical)
                                .focused($isTextFieldFocused)
                                .lineLimit(1...5)
                            
                            if !messageText.isEmpty {
                                Button(action: sendMessage) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.blue)
                                }
                            } else {
                                Button(action: {
                                    // Voice message action
                                }) {
                                    Image(systemName: "mic.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            loadMessages()
        }
    }
    
    private func loadMessages() {
        // Load existing messages for the conversation
        // This would typically fetch from the MessagesAPIService
        messages = generateSampleMessages()
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let newMessage = ChatMessage(
            id: UUID(),
            senderId: "current_user", // This would come from AuthService
            senderName: "You",
            content: messageText,
            timestamp: Date(),
            isFromCurrentUser: true
        )
        
        messages.append(newMessage)
        messageText = ""
        
        // Send message to backend via MessagesAPIService
        // Task {
        //     await messagesService.sendMessage(...)
        // }
    }
    
    private func closeChatView() {
        isPresented = false
        conversation = nil
    }
    
    private func generateSampleMessages() -> [ChatMessage] {
        return [
            ChatMessage(
                id: UUID(),
                senderId: "other_user",
                senderName: conversation?.name ?? "User",
                content: "Hey! How's your studying going?",
                timestamp: Date().addingTimeInterval(-3600),
                isFromCurrentUser: false
            ),
            ChatMessage(
                id: UUID(),
                senderId: "current_user",
                senderName: "You",
                content: "Pretty good! Just finished the physics chapter.",
                timestamp: Date().addingTimeInterval(-3500),
                isFromCurrentUser: true
            ),
            ChatMessage(
                id: UUID(),
                senderId: "other_user",
                senderName: conversation?.name ?? "User",
                content: "Nice! Want to study together later?",
                timestamp: Date().addingTimeInterval(-3400),
                isFromCurrentUser: false
            )
        ]
    }
}

struct ChatMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    
                    Text(message.timestamp, style: .time)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(16)
                    
                    Text(message.timestamp, style: .time)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
}

struct ChatMessage: Identifiable {
    let id: UUID
    let senderId: String
    let senderName: String
    let content: String
    let timestamp: Date
    let isFromCurrentUser: Bool
}

#Preview {
    ChatView(
        conversation: .constant(Conversation(
            id: UUID(),
            name: "John Doe",
            initials: "JD",
            avatarColors: [.blue, .purple],
            lastMessage: "Hey there!",
            timestamp: Date(),
            hasUnreadMessages: false
        )),
        isPresented: .constant(true)
    )
}
