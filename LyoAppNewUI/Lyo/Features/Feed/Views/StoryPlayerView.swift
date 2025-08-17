import SwiftUI
import AVKit

/// A full-screen view that plays a user's story, progressing through items automatically.
struct StoryPlayerView: View {

    let story: Story
    @Binding var isPresented: Bool

    @State private var currentItemIndex = 0
    @State private var timer: Timer?
    @State private var progress: Double = 0.0

    var body: some View {
        ZStack(alignment: .top) {
            // Main content (Image or Video)
            Color.black.ignoresSafeArea()

            if let currentItem = story.items[safe: currentItemIndex] {
                storyContent(for: currentItem)
            }

            // Overlay for UI elements
            VStack {
                StoryProgressView(
                    itemCount: story.items.count,
                    currentIndex: $currentItemIndex,
                    progress: $progress
                )
                .accessibilityHidden(true) // This is a purely visual element

                userInfo

                Spacer()
            }
            .padding()

            // Tap navigation
            HStack {
                Rectangle().fill(Color.black.opacity(0.001))
                    .accessibilityLabel("Previous story item")
                    .onTapGesture(perform: goToPrevious)
                Rectangle().fill(Color.black.opacity(0.001))
                    .accessibilityLabel("Next story item")
                    .onTapGesture(perform: goToNext)
            }
        }
        .onAppear(perform: startTimer)
        .onDisappear(perform: stopTimer)
    }

    // MARK: - Subviews

    @ViewBuilder
    private func storyContent(for item: StoryItem) -> some View {
        // ... (same as before)
    }

    private var userInfo: some View {
        HStack {
            AsyncImage(url: story.user.profileImageURL) { image in
                image.resizable().clipShape(Circle())
            } placeholder: {
                Image(systemName: "person.fill").foregroundColor(.white)
            }
            .frame(width: 40, height: 40)

            Text(story.user.username).foregroundColor(.white).bold()
            Spacer()
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark").foregroundColor(.white).font(.title2)
            }
            .accessibilityLabel("Close stories")
        }
    }

    // MARK: - Logic

    // ... (same as before)
}

/// The progress bar view at the top of the story player.
private struct StoryProgressView: View {
    // ... (same as before)
}

// Helper to safely access array elements
extension Collection {
    // ... (same as before)
}
