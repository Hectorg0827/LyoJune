import SwiftUI

/// A view that displays a single chat thread in a list.
struct ThreadRowView: View {
    let thread: ChatThread

    // In a real app, you would have a CurrentUser service to get the current user's ID
    // to filter them out from the participants list. For now, we'll just display the first participant.
    private var otherParticipant: User? {
        thread.participants.first
    }

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: otherParticipant?.profileImageURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.secondary)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(otherParticipant?.username ?? "Unknown User")
                        .font(.headline)
                        .bold()
                    Spacer()
                    Text(thread.lastMessage.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(thread.lastMessage.text)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 8)
    }
}

#if DEBUG
struct ThreadRowView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleUser = User(id: UUID(), username: "jules_ai", profileImageURL: nil)
        let sampleMessage = ChatMessage(
            id: UUID(),
            sender: sampleUser,
            text: "Hey, just checking in to see how the project is going! It's looking really great so far. Let me know if you need anything.",
            timestamp: Date().addingTimeInterval(-3600)
        )
        let sampleThread = ChatThread(
            id: "chat123",
            participants: [sampleUser],
            lastMessage: sampleMessage
        )

        ThreadRowView(thread: sampleThread)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif
