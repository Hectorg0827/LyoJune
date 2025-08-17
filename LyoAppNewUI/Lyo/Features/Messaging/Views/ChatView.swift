import SwiftUI

struct ChatView: View {

    @StateObject private var viewModel: ChatViewModel
    @State private var inputText: String = ""

    // In a real app, you would get the current user's ID from a session object.
    private let currentUserId = "my_user_id" // Placeholder

    init(viewModel: ChatViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            messageList
            inputBar
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: viewModel.connectAndFetchHistory)
        .onDisappear(perform: viewModel.disconnect)
    }

    @ViewBuilder
    private var messageList: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    switch viewModel.viewState {
                    case .loading:
                        ProgressView()
                    case .loaded:
                        ForEach(viewModel.messages) { message in
                            let senderType: SenderType = message.sender.id.uuidString == currentUserId ? .user : .other
                            TextMessageBubble(text: message.text, sender: senderType, senderName: message.sender.username)
                                .id(message.id)
                        }
                    case .error:
                        Text("Failed to load message history.")
                            .foregroundColor(.red)
                    }
                }
                .padding(.vertical)
            }
            .onChange(of: viewModel.messages.count) { _ in
                if let lastMessage = viewModel.messages.last {
                    withAnimation {
                        scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Message...", text: $inputText, axis: .vertical)
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(20)
                .lineLimit(5)

            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Send message")
        }
        .padding()
        .background(.thinMaterial)
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        HapticManager.impact(style: .light)
        viewModel.sendMessage(text)
        inputText = ""
    }
}
