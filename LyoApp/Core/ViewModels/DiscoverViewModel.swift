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
    private let apiService: EnhancedAPIService
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
        loadCachedData()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Setup Methods
    private func setupWebSocketListeners() {
        webSocketManager.messagesPublisher
            .compactMap { [weak self] message in
                self?.handleWebSocketMessage(message)
            }
            .sink { _ in }
            .store(in: &cancellables)
    }
    
    private func handleWebSocketMessage(_ message: WebSocketMessage) {
        switch message.type {
        case "new_post":
            Task { await refreshContent() }
        case "trending_update":
            Task { await loadTrendingTopics() }
        case "featured_creators_update":
            Task { await loadFeaturedCreators() }
        default:
            break
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .networkStatusChanged)
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
    
    private func loadCachedData() {
        // Load cached discover data
        if let cachedPosts = coreDataManager.fetchCachedPosts() {
            self.posts = cachedPosts
        }
        
        if let cachedDiscoverPosts = coreDataManager.fetchCachedDiscoverPosts() {
            self.discoverPosts = cachedDiscoverPosts
        }
        
        if let cachedTopics = coreDataManager.fetchCachedTrendingTopics() {
            self.trendingTopics = cachedTopics
        }
        
        if let cachedCreators = coreDataManager.fetchCachedFeaturedCreators() {
            self.featuredCreators = cachedCreators
        }
        
        self.lastSyncTime = coreDataManager.getLastSyncTime(for: "discover")
    }
    
    // MARK: - Public Methods
    func loadContent() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        currentPage = 1
        syncProgress = 0.0
        
        do {
            async let postsTask = loadPosts()
            async let trendingTask = loadTrendingTopics()
            async let creatorsTask = loadFeaturedCreators()
            
            await postsTask
            await trendingTask
            await creatorsTask
            
            await syncData()
            
        } catch {
            errorMessage = error.localizedDescription
            NotificationCenter.default.post(name: .showError, object: error)
        }
        
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
        
        do {
            // Sync discover data for offline access
            let syncResult = try await coreDataManager.syncDiscoverData()
            lastSyncTime = Date()
            
            // Update UI with synced data
            if !syncResult.posts.isEmpty {
                posts = syncResult.posts
            }
            if !syncResult.discoverPosts.isEmpty {
                discoverPosts = syncResult.discoverPosts
            }
            
            NotificationCenter.default.post(name: .dataSynced, object: "discover")
            
        } catch {
            print("Discover sync failed: \(error)")
        }
    }
    
    func searchContent() async {
        guard !searchText.isEmpty else {
            discoverPosts = []
            return
        }
        
        isSearching = true
        
        do {
            let searchResults = try await apiService.searchPosts(
                query: searchText,
                category: selectedCategory == "All" ? nil : selectedCategory,
                limit: 50
            )
            
            // Convert to DiscoverPost format for compatibility
            discoverPosts = searchResults.compactMap { post in
                DiscoverPost(
                    id: UUID(),
                    content: post.content,
                    author: post.author.username,
                    authorAvatar: post.author.avatar ?? "",
                    timestamp: post.createdAt,
                    likes: post.likeCount,
                    comments: post.commentCount,
                    shares: post.shareCount,
                    imageUrls: post.mediaUrls,
                    videoUrl: nil,
                    category: PostCategory(id: UUID(), name: selectedCategory, color: .blue),
                    tags: extractTags(from: post.content),
                    isLiked: post.isLiked,
                    isBookmarked: false
                )
            }
            
            // Track search analytics
            try await apiService.trackAnalytics(event: "search_performed", properties: [
                "query": searchText,
                "category": selectedCategory,
                "results_count": discoverPosts.count
            ])
            
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            discoverPosts = []
        }
        
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
            
            // Track analytics
            try? await apiService.trackAnalytics(
                event: discoverPosts[index].isBookmarked ? "post_bookmarked" : "post_unbookmarked",
                properties: ["post_id": post.id.uuidString]
            )
        }
    }
    
    func followCreator(_ creator: User) async {
        do {
            try await apiService.followUser(userId: creator.id)
            
            // Track analytics
            try await apiService.trackAnalytics(event: "creator_followed", properties: [
                "creator_id": creator.id,
                "creator_name": creator.username
            ])
            
        } catch {
            errorMessage = "Failed to follow creator: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Private Methods
    private func loadPosts() async {
        do {
            let response = try await apiService.getDiscoverPosts(
                page: currentPage,
                limit: pageSize,
                category: selectedCategory == "All" ? nil : selectedCategory
            )
            
            if currentPage == 1 {
                posts = response.posts
            } else {
                posts.append(contentsOf: response.posts)
            }
            
            hasMoreContent = response.hasNextPage
            
            // Cache data
            coreDataManager.cachePosts(posts)
            
        } catch {
            errorMessage = "Failed to load posts: \(error.localizedDescription)"
            
            if currentPage == 1 {
                loadCachedPosts()
            }
        }
    }
    
    private func loadTrendingTopics() async {
        do {
            let topics = try await apiService.getTrendingTopics()
            trendingTopics = topics
            coreDataManager.cacheTrendingTopics(topics)
        } catch {
            // Generate from cached posts if API fails
            let allContent = posts.map { $0.content }.joined(separator: " ")
            trendingTopics = extractTrendingTopics(from: allContent)
        }
    }
    
    private func loadFeaturedCreators() async {
        do {
            let creators = try await apiService.getFeaturedCreators()
            featuredCreators = creators
            coreDataManager.cacheFeaturedCreators(creators)
        } catch {
            // Use unique creators from posts as fallback
            featuredCreators = Array(Set(posts.map { $0.author })).prefix(10).map { $0 }
        }
    }
    
    private func loadCachedPosts() {
        if let cached = coreDataManager.fetchCachedPosts() {
            posts = cached
        }
    }
    
    private func likeOriginalPost(_ post: Post) async {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        
        // Optimistic update
        posts[index].isLiked.toggle()
        posts[index].likeCount += posts[index].isLiked ? 1 : -1
        
        do {
            if posts[index].isLiked {
                let response = try await apiService.likePost(postId: post.id)
                posts[index].likeCount = response.likeCount
            } else {
                let response = try await apiService.unlikePost(postId: post.id)
                posts[index].likeCount = response.likeCount
            }
            
            // Update cache
            coreDataManager.cachePosts(posts)
            
        } catch {
            // Revert on error
            posts[index].isLiked.toggle()
            posts[index].likeCount += posts[index].isLiked ? 1 : -1
            errorMessage = "Failed to update like status"
        }
    }
    
    private func shareOriginalPost(_ post: Post) async {
        do {
            try await apiService.sharePost(postId: post.id)
            
            if let index = posts.firstIndex(where: { $0.id == post.id }) {
                posts[index].shareCount += 1
                coreDataManager.cachePosts(posts)
            }
        } catch {
            errorMessage = "Failed to share post"
        }
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
                content: post.content,
                author: post.author.username,
                authorAvatar: post.author.avatar ?? "",
                timestamp: post.createdAt,
                likes: post.likeCount,
                comments: post.commentCount,
                shares: post.shareCount,
                imageUrls: post.mediaUrls,
                videoUrl: nil,
                category: PostCategory(id: UUID(), name: "General", color: .blue),
                tags: extractTags(from: post.content),
                isLiked: post.isLiked,
                isBookmarked: false
            )
        }
    }
}