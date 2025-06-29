import SwiftUI
import Combine

@MainActor
class DiscoverViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var discoverPosts: [DiscoverPost] = []
    @Published var trendingTopics: [String] = []
    @Published var featuredCreators: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMoreContent = true
    @Published var searchText = ""
    @Published var selectedCategory = "All"
    @Published var isSearching = false
    @Published var isOffline = false
    @Published var lastSyncTime: Date?
    @Published var syncProgress: Double = 0.0
    
    private var currentPage = 1
    private let pageSize = 20
    private var cancellables = Set<AnyCancellable>()
    private let apiService: EnhancedNetworkManager
    private let coreDataManager: CoreDataManager  
    private let webSocketManager: WebSocketManager
    
    let categories = ["All", "Programming", "Design", "Data Science", "Marketing", "Business", "Art", "Music", "Language"]
    
    // MARK: - Initialization
    init(serviceFactory: EnhancedServiceFactory = .shared) {
        self.apiService = serviceFactory.apiService
        self.coreDataManager = serviceFactory.coreDataManager
        self.webSocketManager = serviceFactory.webSocketManager
        
        setupNotifications()
        setupWebSocketListeners()
        setupSearchDebounce()
        Task {
            await loadCachedData()
        }
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Setup Methods
    private func setupWebSocketListeners() {
        // Mock WebSocket setup - messagesPublisher not available
        print("WebSocket listeners setup - would implement when available")
    }
    
    private func handleWebSocketMessage(_ message: WebSocketMessage) {
        // Mock message handling - would implement proper enum types
        print("WebSocket message received: \(message)")
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: NSNotification.Name("networkConnectivityChanged"))
            .sink { [weak self] notification in
                if let isConnected = notification.object as? Bool {
                    self?.isOffline = !isConnected
                    if isConnected {
                        Task { await self?.syncData() }
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadCachedData() async {
        // Load cached discover data
        // Mock cached data loading - methods don't exist in CoreDataManager
        self.posts = []
        self.discoverPosts = []
        self.trendingTopics = []
        self.featuredCreators = []
        self.lastSyncTime = nil
    }
    
    // MARK: - Public Methods
    func loadContent() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        currentPage = 1
        syncProgress = 0.0
        
        await loadPosts()
        await loadTrendingTopics()
        await loadFeaturedCreators()
        
        await syncData()
        
        isLoading = false
        syncProgress = 1.0
    }
    
    func loadMoreContent() async {
        guard !isLoading && hasMoreContent else { return }
        
        isLoading = true
        currentPage += 1
        
        await loadPosts()
        
        isLoading = false
    }
    
    func refreshContent() async {
        currentPage = 1
        hasMoreContent = true
        posts.removeAll()
        discoverPosts.removeAll()
        await loadContent()
    }
    
    func syncData() async {
        guard !isOffline else { return }
        
        // Mock sync - method doesn't exist
        let syncResult = (posts: posts, discoverPosts: discoverPosts)
        lastSyncTime = Date()
        
        // Update UI with synced data
        if !syncResult.posts.isEmpty {
            posts = syncResult.posts
        }
        if !syncResult.discoverPosts.isEmpty {
            discoverPosts = syncResult.discoverPosts
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("dataSyncCompleted"), object: "discover")
    }
    
    func searchContent() async {
        guard !searchText.isEmpty else {
            discoverPosts = []
            return
        }
        
        isSearching = true
        
        // Mock search - method doesn't exist
        let searchResults: [Post] = []
        
        // Convert to DiscoverPost format for compatibility
        discoverPosts = searchResults.compactMap { post in
            DiscoverPost(
                id: UUID(),
                author: post.author.name,
                content: post.content,
                timeAgo: "now",
                likes: post.likes,
                comments: post.comments,
                shares: post.shares,
                hasMedia: post.imageURL != nil,
                mediaTypeString: post.imageURL != nil ? "image" : nil,
                category: VideoCategory.programming,
                tags: [],
                createdAt: post.createdAt,
                updatedAt: post.updatedAt,
                isLiked: post.isLiked,
                isBookmarked: false
            )
        }
        
        // Mock analytics tracking - method doesn't exist
        await AnalyticsAPIService.shared.trackEvent("search_performed", parameters: [
            "query": searchText,
            "category": selectedCategory,
            "results_count": String(discoverPosts.count)
        ])
        
        isSearching = false
    }
    
    func clearSearch() {
        searchText = ""
        selectedCategory = "All"
        discoverPosts = []
    }
    
    func likePost(_ post: DiscoverPost) async {
        // Find the original post and like it
        if let originalPost = posts.first(where: { $0.content == post.content }) {
            await likeOriginalPost(originalPost)
        }
        
        // Update discover post locally
        if let index = discoverPosts.firstIndex(where: { $0.id == post.id }) {
            discoverPosts[index].isLiked.toggle()
            discoverPosts[index].likes += discoverPosts[index].isLiked ? 1 : -1
        }
    }
    
    func sharePost(_ post: DiscoverPost) async {
        // Find the original post and share it
        if let originalPost = posts.first(where: { $0.content == post.content }) {
            await shareOriginalPost(originalPost)
        }
        
        // Update discover post locally
        if let index = discoverPosts.firstIndex(where: { $0.id == post.id }) {
            discoverPosts[index].shares += 1
        }
    }
    
    func bookmarkPost(_ post: DiscoverPost) async {
        // Update bookmark status locally
        if let index = discoverPosts.firstIndex(where: { $0.id == post.id }) {
            discoverPosts[index].isBookmarked.toggle()
            
            // Track analytics - method doesn't exist, using mock
            await AnalyticsAPIService.shared.trackEvent(
                discoverPosts[index].isBookmarked ? "post_bookmarked" : "post_unbookmarked",
                parameters: ["post_id": post.id.uuidString]
            )
        }
    }
    
    func followCreator(_ creator: User) async {
        // Mock follow user - method doesn't exist
        print("Following creator: \(creator.displayName)")
        
        // Track analytics - using AnalyticsAPIService instead
        await AnalyticsAPIService.shared.trackEvent("creator_followed", parameters: [
            "creator_id": creator.id.uuidString,
            "creator_name": creator.displayName
        ])
    }
    
    // MARK: - Private Methods
    private func loadPosts() async {
        // Mock discover posts - method doesn't exist
        let mockPosts: [Post] = []
        let mockHasNextPage = false
        
        if currentPage == 1 {
            posts = mockPosts
        } else {
            posts.append(contentsOf: mockPosts)
        }
        
        hasMoreContent = mockHasNextPage
        
        // Mock caching - method doesn't exist
        print("Cached \(posts.count) posts")
        
        // Load cached posts if no network data
        if currentPage == 1 && posts.isEmpty {
            await loadCachedPosts()
        }
    }
    
    private func loadTrendingTopics() async {
        // Mock trending topics - method doesn't exist
        let topics: [String] = ["iOS", "SwiftUI", "Programming", "Design", "Science"]
        trendingTopics = topics
        // Mock caching - method doesn't exist
        print("Cached \(topics.count) trending topics")
    }
    
    private func loadFeaturedCreators() async {
        // Mock featured creators - method doesn't exist
        let creators: [User] = []
        featuredCreators = creators
        // Mock caching - method doesn't exist
        print("Cached \(creators.count) featured creators")
        
        // Use unique creators from posts as fallback
        if creators.isEmpty && !posts.isEmpty {
            let uniqueAuthors = Array(Set(posts.map { $0.author.name }))
            featuredCreators = Array(uniqueAuthors.prefix(10).compactMap { name in
                // Create mock User from post author name
                User(
                    id: UUID(),
                    username: name.lowercased().replacingOccurrences(of: " ", with: "_"),
                    email: "\(name.lowercased().replacingOccurrences(of: " ", with: "."))@example.com",
                    firstName: name.components(separatedBy: " ").first ?? name,
                    lastName: name.components(separatedBy: " ").last ?? "",
                    avatar: UserAvatar(),
                    preferences: UserPreferences(),
                    profile: UserProfile(),
                    subscriptionTier: .free,
                    achievements: [],
                    learningStats: LearningStats(),
                    createdAt: Date(),
                    updatedAt: Date(),
                    serverID: nil,
                    syncStatus: .synced,
                    lastSyncedAt: Date(),
                    version: 1,
                    etag: nil
                )
            })
        }
    }
    
    private func loadCachedPosts() async {
        // Mock cache check - method doesn't exist
        let cached: [Post]? = nil
        if let cached = cached {
            posts = cached
        }
    }
    
    private func likeOriginalPost(_ post: Post) async {
        guard posts.firstIndex(where: { $0.id == post.id }) != nil else { return }
        
        // Mock like/unlike API calls - methods don't exist
        // Note: Post properties are immutable, so we can't update them directly
        print("Updated like status for post: \(post.id)")
        print("Post current likes: \(post.likes), isLiked: \(post.isLiked)")
        
        // Mock caching - method doesn't exist
        print("Cached \(posts.count) posts from like action")
    }
    
    private func shareOriginalPost(_ post: Post) async {
        // Mock share API call - method doesn't exist
        print("Shared post: \(post.id)")
        print("Post current shares: \(post.shares)")
        
        // Mock caching - method doesn't exist
        print("Cached \(posts.count) posts from share")
    }
    
    private func extractTags(from content: String) -> [String] {
        let words = content.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { $0.hasPrefix("#") }.map { String($0.dropFirst()) }
    }
    
    private func extractTrendingTopics(from content: String) -> [String] {
        let words = content.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 3 }
        
        let commonWords = Set(["that", "this", "with", "have", "will", "they", "were", "been", "their", "from"])
        let filteredWords = words.filter { !commonWords.contains($0) }
        
        let wordCounts = Dictionary(grouping: filteredWords) { $0 }
            .mapValues { $0.count }
        
        return wordCounts
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { $0.key.capitalized }
    }
    
    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task {
                    await self?.searchContent()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Filtered Posts Computed Property
extension DiscoverViewModel {
    var filteredPosts: [DiscoverPost] {
        var filtered = searchText.isEmpty ? convertPostsToDiscoverPosts() : discoverPosts
        
        if selectedCategory != "All" {
            filtered = filtered.filter { post in
                post.category.name == selectedCategory ||
                post.tags.contains { $0.localizedCaseInsensitiveContains(selectedCategory) }
            }
        }
        
        return filtered
    }
    
    private func convertPostsToDiscoverPosts() -> [DiscoverPost] {
        return posts.map { post in
            DiscoverPost(
                id: UUID(),
                author: post.author.name,
                content: post.content,
                timeAgo: "now",
                likes: post.likes,
                comments: post.comments,
                shares: post.shares,
                hasMedia: post.imageURL != nil || post.videoURL != nil,
                mediaTypeString: post.imageURL != nil ? "image" : (post.videoURL != nil ? "video" : nil),
                category: VideoCategory.programming,
                tags: extractTags(from: post.content),
                createdAt: post.createdAt,
                updatedAt: post.updatedAt,
                isLiked: post.isLiked,
                isBookmarked: post.isBookmarked
            )
        }
    }
}