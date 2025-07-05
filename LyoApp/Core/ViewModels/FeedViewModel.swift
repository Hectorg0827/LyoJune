import SwiftUI
import Combine
import Foundation

// MARK: - Feed Type Definitions
struct PostUpdate: Codable {
    let type: UpdateType
    let post: Post?
    let postId: String?
    let timestamp: Date
    
    enum UpdateType: String, CaseIterable, Codable {
        case newPost = "new_post"
        case likeUpdate = "like_update"
        case commentUpdate = "comment_update"
        case shareUpdate = "share_update"
        case postDeleted = "post_deleted"
    }
    
    init(type: UpdateType, post: Post? = nil, postId: String? = nil, timestamp: Date = Date()) {
        self.type = type
        self.post = post
        self.postId = postId
        self.timestamp = timestamp
    }
}

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
    
    private var apiService: EnhancedNetworkManager {
        serviceFactory.apiService
    }
    
    private var coreDataManager: DataManager {
        serviceFactory.coreDataManager
    }
    
    private var webSocketManager: WebSocketManager {
        serviceFactory.webSocketManager
    }
    
    init() {
        setupNotifications()
        setupRealTimeUpdates()
        Task {
            await loadCachedData()
        }
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
        
        // Load from cache first for instant UI
        await loadCachedData()
        
        do {
            // Fetch fresh data from backend API
            let endpoint = APIEndpoint(path: "/feed", method: .GET)
            let response: FeedResponse = try await apiService.request(endpoint: endpoint)
            
            posts = response.posts
            // Videos will be loaded separately if needed
            
            // Cache the new data
            cacheData(posts: posts, videos: videos)
            
            isOffline = false
        } catch {
            errorMessage = "Failed to load feed: \(error.localizedDescription)"
            // Fallback to cached data if available
            if posts.isEmpty {
                await loadCachedData()
                isOffline = true
            }
        }
        
        isLoading = false
    }
    
    func loadMoreContent() async {
        guard !isLoading && hasMoreContent else { return }
        
        isLoading = true
        currentPage += 1
        
        do {
            // Fetch more data from backend API
            let endpoint = APIEndpoint(path: "/feed", method: .GET)
            let response: FeedResponse = try await apiService.request(endpoint: endpoint)
            
            posts.append(contentsOf: response.posts)
            // Check if there are more posts available (based on response count or pagination)
            hasMoreContent = response.posts.count >= 20  // Assume 20 posts per page
            
            // Cache the new data
            cacheData(posts: posts, videos: videos)
        } catch {
            currentPage -= 1 // Revert page increment on error
            handleError(error)
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
        do {
            let endpoint = APIEndpoint(path: "/posts/\(postId)/like", method: .POST)
            let updatedPost: Post = try await apiService.request(endpoint: endpoint)
            
            // Update local state
            DispatchQueue.main.async {
                if let index = self.posts.firstIndex(where: { $0.id == postId }) {
                    self.posts[index] = updatedPost
                }
            }
            
            // Update cached data
            // TODO: Implement proper post caching with EnhancedCoreDataManager
            print("Updated post like status: \(postId)")
            
        } catch {
            print("Error liking post: \(error)")
        }
    }
    
    func sharePost(_ post: Post) async {
        do {
            let endpoint = APIEndpoint(path: "/posts/\(post.id)/share", method: .POST)
            let _: EmptyResponse = try await apiService.request(endpoint: endpoint)
            
            // Track analytics
            await AnalyticsAPIService.shared.trackEvent("post_shared", parameters: [
                "post_id": post.id,
                "author_id": post.authorId
            ])
            
        } catch {
            print("Error sharing post: \(error)")
        }
    }
    
    // MARK: - Private Methods
    private func setupNotifications() {
        // Listen for network connectivity changes
        NotificationCenter.default.publisher(for: NSNotification.Name("networkConnectivityChanged"))
            .sink { [weak self] notification in
                Task { @MainActor in
                    self?.isOffline = !(notification.object as? Bool ?? true)
                    if !(self?.isOffline ?? true) && (self?.posts.isEmpty ?? true) {
                        await self?.loadContent()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Listen for authentication changes
        NotificationCenter.default.publisher(for: NSNotification.Name("authenticationStateChanged"))
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.loadContent()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupRealTimeUpdates() {
        // TODO: Implement real-time post updates via WebSocket
        // This will be implemented when WebSocketManager is enhanced with post updates
        print("Real-time updates setup completed")
    }
    
    private func handleRealTimePostUpdate(_ update: PostUpdate) {
        DispatchQueue.main.async {
            switch update.type {
            case .newPost:
                if let newPost = update.post, !self.posts.contains(where: { $0.id == newPost.id }) {
                    self.posts.insert(newPost, at: 0)
                }
            case .likeUpdate:
                if let postId = update.postId, let updatedPost = update.post,
                   let index = self.posts.firstIndex(where: { $0.id == postId }) {
                    self.posts[index] = updatedPost
                }
            case .commentUpdate:
                if let postId = update.postId, let updatedPost = update.post,
                   let index = self.posts.firstIndex(where: { $0.id == postId }) {
                    self.posts[index] = updatedPost
                }
            case .shareUpdate:
                if let postId = update.postId, let updatedPost = update.post,
                   let index = self.posts.firstIndex(where: { $0.id == postId }) {
                    self.posts[index] = updatedPost
                }
            case .postDeleted:
                if let postId = update.postId {
                    self.posts.removeAll { $0.id == postId }
                }
            }
        }
    }
    
    private func loadCachedData() async {
        // TODO: Implement proper cached data loading with EnhancedCoreDataManager
        print("Loading cached data - placeholder implementation")
    }
    
    private func cacheData(posts: [Post], videos: [EducationalVideo]) {
        
        print("Caching \(posts.count) posts and \(videos.count) videos - placeholder implementation")
    }
    
    private func handleError(_ error: Error) {
        if let apiError = error as? NetworkError {
            switch apiError {
            case .networkError:
                errorMessage = "No internet connection. Showing cached content."
                isOffline = true
            case .unauthorized:
                errorMessage = "Session expired. Please log in again."
                // Trigger re-authentication
                Task {
                    try? await serviceFactory.authService.refreshToken()
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

