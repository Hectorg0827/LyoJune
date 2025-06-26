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
    @Published var isOffline = false
    
    private var currentPage = 1
    private let pageSize = 20
    private var cancellables = Set<AnyCancellable>()
    
    // Enhanced services
    private let serviceFactory = EnhancedServiceFactory.shared
    
    private var apiService: EnhancedAPIService {
        serviceFactory.apiService
    }
    
    private var coreDataManager: CoreDataManager {
        serviceFactory.coreDataManager
    }
    
    private var webSocketManager: WebSocketManager {
        serviceFactory.webSocketManager
    }
    
    init() {
        setupNotifications()
        setupRealTimeUpdates()
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
        
        do {
            // Load from cache first for instant UI
            await loadCachedData()
            
            // Then fetch fresh data from API
            let feedData = try await apiService.getFeedPosts(page: currentPage, limit: pageSize)
            
            posts = feedData.posts
            videos = feedData.videos
            hasMoreContent = feedData.hasMore
            
            // Cache the new data
            await cacheData(posts: feedData.posts, videos: feedData.videos)
            
            isOffline = false
            
        } catch {
            handleError(error)
            // If network fails, show cached data
            if posts.isEmpty {
                await loadCachedData()
            }
        }
        
        isLoading = false
    }
    
    func loadMoreContent() async {
        guard !isLoading && hasMoreContent else { return }
        
        isLoading = true
        currentPage += 1
        
        do {
            let feedData = try await apiService.getFeedPosts(page: currentPage, limit: pageSize)
            
            posts.append(contentsOf: feedData.posts)
            videos.append(contentsOf: feedData.videos)
            hasMoreContent = feedData.hasMore
            
            // Cache the new data
            await cacheData(posts: feedData.posts, videos: feedData.videos)
            
        } catch {
            handleError(error)
            currentPage -= 1 // Revert page increment on error
        }
        
        isLoading = false
    }
    
    func refreshContent() async {
        isRefreshing = true
        currentPage = 1
        await loadContent()
        isRefreshing = false
    }
    
    func likePost(_ postId: String) async {
        // Optimistic update
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            let wasLiked = posts[index].isLiked
            posts[index].isLiked.toggle()
            posts[index].likesCount += wasLiked ? -1 : 1
            
            do {
                if wasLiked {
                    try await apiService.unlikePost(postId: postId)
                } else {
                    try await apiService.likePost(postId: postId)
                }
                
                // Update cached data
                await coreDataManager.updatePostLikeStatus(postId: postId, isLiked: !wasLiked)
                
            } catch {
                // Revert optimistic update on error
                posts[index].isLiked = wasLiked
                posts[index].likesCount += wasLiked ? 1 : -1
                handleError(error)
            }
        }
    }
    
    func sharePost(_ post: Post) async {
        await apiService.trackAnalyticsEvent(
            eventName: "post_shared",
            properties: [
                "post_id": post.id,
                "post_author": post.author.id
            ]
        )
    }
    
    // MARK: - Private Methods
    private func setupNotifications() {
        // Listen for network connectivity changes
        NotificationCenter.default.publisher(for: .networkConnectivityChanged)
            .sink { [weak self] notification in
                Task { @MainActor in
                    self?.isOffline = !(notification.object as? Bool ?? true)
                    if !self!.isOffline && self!.posts.isEmpty {
                        await self?.loadContent()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Listen for authentication changes
        NotificationCenter.default.publisher(for: .authenticationStateChanged)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.loadContent()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupRealTimeUpdates() {
        // Listen for real-time post updates
        webSocketManager.postUpdatesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handleRealTimePostUpdate(update)
            }
            .store(in: &cancellables)
    }
    
    private func handleRealTimePostUpdate(_ update: PostUpdate) {
        switch update.type {
        case .newPost:
            if let newPost = update.post, !posts.contains(where: { $0.id == newPost.id }) {
                posts.insert(newPost, at: 0)
            }
        case .likeUpdate:
            if let index = posts.firstIndex(where: { $0.id == update.postId }) {
                posts[index].likesCount = update.likesCount ?? posts[index].likesCount
                posts[index].isLiked = update.isLiked ?? posts[index].isLiked
            }
        case .commentUpdate:
            if let index = posts.firstIndex(where: { $0.id == update.postId }) {
                posts[index].commentsCount = update.commentsCount ?? posts[index].commentsCount
            }
        }
    }
    
    private func loadCachedData() async {
        do {
            let cachedPosts = try await coreDataManager.getCachedPosts(limit: pageSize * currentPage)
            if !cachedPosts.isEmpty {
                posts = cachedPosts
                isOffline = true
            }
        } catch {
            print("Failed to load cached posts: \(error.localizedDescription)")
        }
    }
    
    private func cacheData(posts: [Post], videos: [EducationalVideo]) async {
        do {
            try await coreDataManager.cachePosts(posts)
            // Cache videos if needed in the future
        } catch {
            print("Failed to cache posts: \(error.localizedDescription)")
        }
    }
    
    private func handleError(_ error: Error) {
        if let apiError = error as? APIError {
            switch apiError {
            case .networkError:
                errorMessage = "No internet connection. Showing cached content."
                isOffline = true
            case .unauthorized:
                errorMessage = "Session expired. Please log in again."
                // Trigger re-authentication
                Task {
                    await serviceFactory.authService.refreshToken()
                }
            case .serverError:
                errorMessage = "Server error. Please try again later."
            default:
                errorMessage = "Something went wrong. Please try again."
            }
        } else {
            errorMessage = error.localizedDescription
        }
    }
}