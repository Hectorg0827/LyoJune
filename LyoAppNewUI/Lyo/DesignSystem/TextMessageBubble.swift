import SwiftUI

/// An enum to represent the sender of a message in a generic way.
public enum SenderType {
    case user
    case other
}

/// A view that displays a text message in a chat bubble.
/// The style and alignment of the bubble change based on the sender.
public struct TextMessageBubble: View {

    let text: String
    let sender: SenderType

    private var isFromUser: Bool {
        sender == .user
    }

    public var body: some View {
        HStack {
            if isFromUser {
                Spacer(minLength: 50)
            }

            Text(text)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(bubbleBackground)
                .foregroundColor(isFromUser ? .white : .primary)
                .cornerRadius(20)
                .frame(maxWidth: 300, alignment: isFromUser ? .trailing : .leading)

            if !isFromUser {
                Spacer(minLength: 50)
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
            TextMessageBubble(
                text: "Hello! I'm a message from another user.",
                sender: .other
            )

            TextMessageBubble(
                text: "Hi there! This is my reply.",
                sender: .user
            )
        }
        .padding()
    }
}
#endif
