import SwiftUI

struct FeedView: View {

    // In a real app, these would be provided by a higher-level coordinator or DI container.
    @StateObject private var feedViewModel: FeedViewModel
    @StateObject private var storiesViewModel: StoriesViewModel

    @State private var isShowingStoryPlayer = false
    @State private var selectedStory: Story? = nil

    init(feedViewModel: FeedViewModel, storiesViewModel: StoriesViewModel) {
        _feedViewModel = StateObject(wrappedValue: feedViewModel)
        _storiesViewModel = StateObject(wrappedValue: storiesViewModel)
    }

    var body: some View {
        ZStack(alignment: .top) {
            // The main, vertically-swiping feed
            feedContent

            // The Stories tray as an overlay
            VStack {
                StoriesTrayView(
                    stories: $storiesViewModel.stories,
                    isLoading: storiesViewModel.isLoading
                ) { story in
                    self.selectedStory = story
                    self.isShowingStoryPlayer = true
                }
                .background(.ultraThinMaterial.opacity(0.8))
                Spacer()
            }
        }
        .navigationTitle("Feed")
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .onAppear {
            if feedViewModel.posts.isEmpty {
                feedViewModel.fetchForYouFeed()
            }
            if storiesViewModel.stories.isEmpty {
                storiesViewModel.fetchStories()
            }
        }
        .fullScreenCover(isPresented: $isShowingStoryPlayer) {
            if let story = selectedStory {
                StoryPlayerView(story: story, isPresented: $isShowingStoryPlayer)
            }
        }
    }

    @ViewBuilder
    private var feedContent: some View {
        if feedViewModel.isLoading && feedViewModel.posts.isEmpty {
            ProgressView()
        } else {
            TabView {
                ForEach(feedViewModel.posts) { post in
                    FeedPostView(post: post)
                        .tag(post.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}

#if DEBUG
struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        // This would require a more complex setup with mock services that can be
        // injected into the view models.
        let mockFeedService = MockFeedService()
        let feedViewModel = FeedViewModel(feedService: mockFeedService)
        let storiesViewModel = StoriesViewModel(feedService: mockFeedService)

        // Add some mock data to the service
        let sampleUser = User(id: UUID(), username: "jules_ai", profileImageURL: nil)
        mockFeedService.postsResult = .success([
            Post(id: UUID(), user: sampleUser, videoURL: URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!, caption: "Post 1", likeCount: 1, commentCount: 1, shareCount: 1),
            Post(id: UUID(), user: sampleUser, videoURL: URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4")!, caption: "Post 2", likeCount: 2, commentCount: 2, shareCount: 2)
        ])

        return FeedView(feedViewModel: feedViewModel, storiesViewModel: storiesViewModel)
    }

    // A mock service for previews
    private class MockFeedService: FeedServicing {
        var postsResult: Result<[Post], APIError> = .success([])
        var storiesResult: Result<[Story], APIError> = .success([])

        func getForYouFeed() async throws -> [Post] {
            try postsResult.get()
        }
        func getFollowingFeed() async throws -> [Post] { [] }
        func getStories() async throws -> [Story] {
            try storiesResult.get()
        }
        func getPresignedURL(contentType: String, fileExtension: String) async throws -> PresignedURLResponse { fatalError() }
        func commitMedia(assetKey: String) async throws {}
        func createPost(caption: String, mediaAssetUrl: String) async throws -> Post { fatalError() }
    }
}
#endif
