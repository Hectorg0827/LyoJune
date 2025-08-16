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

                userInfo

                Spacer()
            }
            .padding()

            // Tap navigation
            HStack {
                Rectangle().fill(Color.black.opacity(0.001)).onTapGesture(perform: goToPrevious)
                Rectangle().fill(Color.black.opacity(0.001)).onTapGesture(perform: goToNext)
            }
        }
        .onAppear(perform: startTimer)
        .onDisappear(perform: stopTimer)
    }

    // MARK: - Subviews

    @ViewBuilder
    private func storyContent(for item: StoryItem) -> some View {
        switch item.type {
        case .image:
            AsyncImage(url: item.mediaURL) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                ProgressView()
            }
        case .video:
            if let url = item.mediaURL {
                VideoPlayer(player: AVPlayer(url: url))
            } else {
                Text("Invalid video URL")
            }
        }
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
        }
    }

    // MARK: - Logic

    private func startTimer() {
        progress = 0
        let duration = story.items[safe: currentItemIndex]?.duration ?? 3.0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            progress += 0.05 / duration
            if progress >= 1.0 {
                goToNext()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func goToNext() {
        if currentItemIndex < story.items.count - 1 {
            currentItemIndex += 1
            startTimer()
        } else {
            isPresented = false
        }
    }

    private func goToPrevious() {
        if currentItemIndex > 0 {
            currentItemIndex -= 1
            startTimer()
        }
    }
}

/// The progress bar view at the top of the story player.
private struct StoryProgressView: View {
    let itemCount: Int
    @Binding var currentIndex: Int
    @Binding var progress: Double

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<itemCount, id: \.self) { index in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Color.white.opacity(0.5))
                        if index == currentIndex {
                            Rectangle().fill(Color.white)
                                .frame(width: geo.size.width * progress)
                                .animation(.linear, value: progress)
                        } else if index < currentIndex {
                            Rectangle().fill(Color.white)
                        }
                    }
                }
                .clipShape(Capsule())
            }
        }
        .frame(height: 3)
    }
}

// Helper to safely access array elements
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
