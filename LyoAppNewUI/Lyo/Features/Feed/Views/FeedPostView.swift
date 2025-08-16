import SwiftUI
import AVKit

/// A view that displays a single, full-screen video post, similar to TikTok.
struct FeedPostView: View {

    let post: Post
    @State private var player: AVPlayer

    // A state to control play/pause based on visibility.
    @State private var isPlaying: Bool = false

    init(post: Post) {
        self.post = post
        // Initialize the player but don't play it yet.
        _player = State(initialValue: AVPlayer(url: post.videoURL))
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Video Player
            VideoPlayer(player: player)
                .disabled(true) // Disable default controls
                .aspectRatio(contentMode: .fill)
                .onAppear(perform: play)
                .onDisappear(perform: pause)

            // UI Overlay
            HStack(alignment: .bottom) {
                videoInfo
                Spacer()
                actionButtons
            }
            .padding()
            .foregroundColor(.white)
            .shadow(radius: 5)
        }
    }

    // MARK: - Subviews

    @EnvironmentObject private var router: Router

    private var videoInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                router.navigate(to: .profile(userId: post.user.id.uuidString))
            }) {
                Text("@\(post.user.username)")
                    .font(.headline)
                    .bold()
            }

            Text(post.caption)
                .font(.subheadline)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 24) {
            ActionButton(iconName: "heart.fill", text: "\(post.likeCount)")
            ActionButton(iconName: "message.fill", text: "\(post.commentCount)")
            ActionButton(iconName: "arrowshape.turn.up.right.fill", text: "\(post.shareCount)")
        }
    }

    private struct ActionButton: View {
        let iconName: String
        let text: String

        var body: some View {
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.title)
                Text(text)
                    .font(.caption)
                    .bold()
            }
        }
    }

    // MARK: - Playback Control

    private func play() {
        player.isMuted = false // Unmute when visible
        player.play()
        isPlaying = true

        // Loop the video
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
            player.seek(to: .zero)
            player.play()
        }
    }

    private func pause() {
        player.pause()
        isPlaying = false
    }
}

#if DEBUG
struct FeedPostView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleUser = User(id: UUID(), username: "jules_ai", profileImageURL: nil)
        let samplePost = Post(
            id: UUID(),
            user: sampleUser,
            videoURL: URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!,
            caption: "This is a sample video post! #swiftui #iosdev",
            likeCount: 1337,
            commentCount: 42,
            shareCount: 18
        )

        FeedPostView(post: samplePost)
    }
}
#endif
