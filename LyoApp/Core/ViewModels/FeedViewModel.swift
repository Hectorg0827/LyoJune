import SwiftUI
import Combine

@MainActor
class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var videos: [EducationalVideo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMoreContent = true
    @Published var isRefreshing = false
    
    private var currentPage = 1
    private let pageSize = 20
    private var cancellables = Set<AnyCancellable>()
    private let postService = PostAPIService.shared
    private let dataManager = DataManager.shared
    
    init() {
        setupNotifications()
        loadCachedData()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Public Methods
    func loadContent() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        currentPage = 1
        
        await loadPosts()
        await loadVideos()
        
        isLoading = false
    }
    
    func loadMoreContent() async {
        guard !isLoading && hasMoreContent else { return }
        
        isLoading = true
        currentPage += 1
        
        await loadPosts()
        
        isLoading = false
    }
    
    func refreshContent() async {
        isRefreshing = true
        currentPage = 1
        hasMoreContent = true
        posts.removeAll()
        videos.removeAll()
        
        await loadContent()
        
        isRefreshing = false
    }
    
    func likePost(_ post: Post) async {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        
        // Optimistic update
        posts[index].isLiked.toggle()
        posts[index].likeCount += posts[index].isLiked ? 1 : -1
        
        do {
            if posts[index].isLiked {
                let response: LikeResponse = try await postService.likePost(postId: post.id)
                posts[index].likeCount = response.likeCount
            } else {
                let response: LikeResponse = try await postService.unlikePost(postId: post.id)
                posts[index].likeCount = response.likeCount
            }
            
            // Track analytics
            await AnalyticsAPIService.shared.trackEvent(
                posts[index].isLiked ? "post_liked" : "post_unliked",
                parameters: ["post_id": post.id]
            )
            
        } catch {
            // Revert optimistic update on error
            posts[index].isLiked.toggle()
            posts[index].likeCount += posts[index].isLiked ? 1 : -1
            errorMessage = "Failed to update like status"
        }
    }
    
    func sharePost(_ post: Post, message: String? = nil) async {
        do {
            let _: ShareResponse = try await postService.sharePost(postId: post.id, message: message)
            
            // Update share count if we have it in the model
            if let index = posts.firstIndex(where: { $0.id == post.id }) {
                posts[index].shareCount += 1
            }
            
            // Track analytics
            await AnalyticsAPIService.shared.trackEvent(
                "post_shared",
                parameters: ["post_id": post.id]
            )
            
        } catch {
            errorMessage = "Failed to share post"
        }
    }
    
    func reportPost(_ post: Post, reason: String) async {
        do {
            let _: ReportResponse = try await postService.reportPost(postId: post.id, reason: reason)
            
            // Remove post from feed after successful report
            posts.removeAll { $0.id == post.id }
            
        } catch {
            errorMessage = "Failed to report post"
        }
    }
    
    func createPost(content: String, mediaUrls: [String] = [], courseId: String? = nil) async {
        do {
            let newPost = try await postService.createPost(
                content: content,
                mediaUrls: mediaUrls,
                courseId: courseId
            )
            
            // Add to beginning of feed
            posts.insert(newPost, at: 0)
            
            // Track analytics
            await AnalyticsAPIService.shared.trackEvent(
                "post_created",
                parameters: [
                    "content_length": content.count,
                    "has_media": !mediaUrls.isEmpty,
                    "has_course": courseId != nil
                ]
            )
            
        } catch {
            errorMessage = "Failed to create post"
        }
    }
    
    // MARK: - Private Methods
    private func loadPosts() async {
        do {
            let response: FeedResponse = try await postService.getFeed(page: currentPage, limit: pageSize)
            
            if currentPage == 1 {
                posts = response.posts
            } else {
                posts.append(contentsOf: response.posts)
            }
            
            hasMoreContent = response.pagination.hasNextPage
            
            // Cache data for offline access
            dataManager.saveForOffline(posts, key: "feed_posts")
            
        } catch {
            errorMessage = "Failed to load posts: \(error.localizedDescription)"
            
            // Try to load cached data if first page fails
            if currentPage == 1 {
                loadCachedData()
            }
        }
    }
    
    private func loadVideos() async {
        // For now, load sample videos - in a real app, this would come from the API
        videos = EducationalVideo.mockVideos()
        dataManager.saveForOffline(videos, key: "feed_videos")
    }
    
    private func loadCachedData() {
        if let cachedPosts: [Post] = dataManager.loadFromOffline([Post].self, key: "feed_posts") {
            posts = cachedPosts
        }
        
        if let cachedVideos: [EducationalVideo] = dataManager.loadFromOffline([EducationalVideo].self, key: "feed_videos") {
            videos = cachedVideos
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: Constants.NotificationNames.userDidLogin)
            .sink { [weak self] _ in
                Task {
                    await self?.refreshContent()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Constants.NotificationNames.dataDidSync)
            .sink { [weak self] _ in
                Task {
                    await self?.loadContent()
                }
            }
            .store(in: &cancellables)
    }
}