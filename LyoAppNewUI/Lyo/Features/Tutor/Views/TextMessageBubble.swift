import SwiftUI

/// A view that displays a text message in a chat bubble.
/// The style and alignment of the bubble change based on the sender.
struct TextMessageBubble: View {

    let message: TutorMessage

    private var isFromUser: Bool {
        message.sender == .user
    }

    var body: some View {
        HStack {
            if isFromUser {
                Spacer()
            }

            Text(message.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(bubbleBackground)
                .foregroundColor(isFromUser ? .white : .primary)
                .cornerRadius(20)
                .frame(maxWidth: 300, alignment: isFromUser ? .trailing : .leading)

            if !isFromUser {
                Spacer()
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        if isFromUser {
            Color.blue
        } else {
            Color(.secondarySystemBackground)
        }
    }
}

#if DEBUG
struct TextMessageBubble_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            TextMessageBubble(message: .init(
                id: UUID(),
                sender: .tutor,
                type: .text,
                text: "Hello! I'm your AI Tutor. What would you like to learn about today?",
                question: nil
            ))

            TextMessageBubble(message: .init(
                id: UUID(),
                sender: .user,
                type: .text,
                text: "I want to learn about the history of the internet.",
                question: nil
            ))
        }
        .padding()
    }
}
#endif
