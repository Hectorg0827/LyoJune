import SwiftUI
import Combine

@MainActor
class DiscoverViewModel: ObservableObject {
    @Published var posts: [Post] = []
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
    private let coreDataManager: DataManager
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
        // Set up real-time content updates
        if let contentPublisher = webSocketManager.contentUpdatesPublisher {
            contentPublisher
                .sink { [weak self] update in
                    self?.handleContentUpdate(update)
                }
                .store(in: &cancellables)
        }
        
        // Set up trending updates
        if let trendingPublisher = webSocketManager.trendingUpdatesPublisher {
            trendingPublisher
                .sink { [weak self] update in
                    self?.handleTrendingUpdate(update)
                }
                .store(in: &cancellables)
        }
    }
    
    private func handleWebSocketMessage(_ message: WebSocketMessage) {
        switch message.type {
        case .contentUpdate:
            if let contentData = message.data as? ContentUpdate {
                handleContentUpdate(contentData)
            }
        case .trendingUpdate:
            if let trendingData = message.data as? TrendingUpdate {
                handleTrendingUpdate(trendingData)
            }
        default:
            print("Unhandled WebSocket message type: \(message.type)")
        }
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
        let cachedPosts = coreDataManager.fetchCachedPosts()
        let cachedTrendingTopics = coreDataManager.fetchCachedTrendingTopics()
        let cachedFeaturedCreators = coreDataManager.fetchCachedFeaturedCreators()
        let cachedLastSync = coreDataManager.fetchLastSyncTime(for: "discover")
        
        DispatchQueue.main.async {
            self.posts = cachedPosts
            self.trendingTopics = cachedTrendingTopics
            self.featuredCreators = cachedFeaturedCreators
            self.lastSyncTime = cachedLastSync
        }
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
        await loadContent()
    }
    
    func syncData() async {
        guard !isOffline else { return }
        
        do {
            // Sync discover data with backend
            let syncResult = try await apiService.syncDiscoverData()
            
            DispatchQueue.main.async {
                self.lastSyncTime = Date()
                
                // Update UI with synced data
                if !syncResult.posts.isEmpty {
                    self.posts = syncResult.posts
                }
                
                // Cache the synced data
                self.coreDataManager.cachePosts(syncResult.posts)
                self.coreDataManager.setLastSyncTime(Date(), for: "discover")
            }
            
            NotificationCenter.default.post(name: NSNotification.Name("dataSyncCompleted"), object: "discover")
            
        } catch {
            print("Error syncing discover data: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Sync failed: \(error.localizedDescription)"
            }
        }
    }
    
    func searchContent() async {
        guard !searchText.isEmpty else {
            posts = []
            return
        }
        
        isSearching = true
        
        do {
            let searchResults = try await apiService.searchDiscoverContent(
                query: searchText,
                filters: currentFilters
            )
            
            DispatchQueue.main.async {
                self.posts = searchResults
            }
            
            // Cache search results
            coreDataManager.cachePosts(searchResults)
            
            // Track search analytics
            analyticsManager.track(event: "discover_search", parameters: [
                "query": searchText,
                "results_count": String(searchResults.count),
                "filters": currentFilters.joined(separator: ",")
            ])
            
        } catch {
            print("Error searching content: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Search failed: \(error.localizedDescription)"
                self.posts = []
            }
        }
        
        isSearching = false
    }
    
    func clearSearch() {
        searchText = ""
        selectedCategory = "All"
        posts = []
    }
    
    func likePost(_ post: Post) async {
        // Find the original post and like it
        if let originalPost = posts.first(where: { $0.id == post.id }) {
            await likeOriginalPost(originalPost)
        }
    }
    
    func sharePost(_ post: Post) async {
        // Find the original post and share it
        if let originalPost = posts.first(where: { $0.id == post.id }) {
            await shareOriginalPost(originalPost)
        }
    }
    
    func bookmarkPost(_ post: Post) async {
        do {
            let isBookmarked = try await apiService.toggleBookmark(postId: post.id)
            
            // Update bookmark status locally
            DispatchQueue.main.async {
                if let index = self.posts.firstIndex(where: { $0.id == post.id }) {
                    self.posts[index].isBookmarked = isBookmarked
                }
            }
            
            // Track analytics
            analyticsManager.track(event: isBookmarked ? "post_bookmarked" : "post_unbookmarked", parameters: [
                "post_id": post.id
            ])
            
        } catch {
            print("Error bookmarking post: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to bookmark post: \(error.localizedDescription)"
            }
        }
    }
    
    func followCreator(_ creator: User) async {
        do {
            try await apiService.followUser(userId: creator.id)
            
            // Track analytics
            analyticsManager.track(event: "creator_followed", parameters: [
                "creator_id": creator.id.uuidString,
                "creator_name": creator.displayName
            ])
            
        } catch {
            print("Error following creator: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to follow creator: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Private Methods
    private func loadPosts() async {
        do {
            let response = try await apiService.getDiscoverPosts(
                page: currentPage,
                limit: 20,
                category: selectedCategory == "All" ? nil : selectedCategory
            )
            
            DispatchQueue.main.async {
                if self.currentPage == 1 {
                    self.posts = response.posts
                } else {
                    self.posts.append(contentsOf: response.posts)
                }
                
                self.hasMoreContent = response.hasMorePages
            }
            
            // Cache the posts
            coreDataManager.cachePosts(response.posts)
            print("Loaded \(response.posts.count) discover posts")
            
        } catch {
            print("Error loading posts: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load posts: \(error.localizedDescription)"
            }
            
            // Load cached posts if API fails
            if currentPage == 1 {
                await loadCachedPosts()
            }
        }
    }
    
    private func loadTrendingTopics() async {
        do {
            let topics = try await apiService.getTrendingTopics()
            DispatchQueue.main.async {
                self.trendingTopics = topics
            }
            
            // Cache trending topics
            coreDataManager.cacheTrendingTopics(topics)
            print("Loaded \(topics.count) trending topics")
            
        } catch {
            print("Error loading trending topics: \(error)")
            // Use cached data as fallback
            let cachedTopics = coreDataManager.fetchCachedTrendingTopics()
            DispatchQueue.main.async {
                self.trendingTopics = cachedTopics
            }
        }
    }
    
    private func loadFeaturedCreators() async {
        do {
            let creators = try await apiService.getFeaturedCreators()
            DispatchQueue.main.async {
                self.featuredCreators = creators
            }
            
            // Cache featured creators
            coreDataManager.cacheFeaturedCreators(creators)
            print("Loaded \(creators.count) featured creators")
            
        } catch {
            print("Error loading featured creators: \(error)")
            // Use cached data as fallback
            let cachedCreators = coreDataManager.fetchCachedFeaturedCreators()
            DispatchQueue.main.async {
                self.featuredCreators = cachedCreators
            }
            
            // Use unique creators from posts as additional fallback
            if featuredCreators.isEmpty && !posts.isEmpty {
                let uniqueAuthors = Array(Set(posts.map { $0.author.name }))
                featuredCreators = Array(uniqueAuthors.prefix(10).compactMap { name in
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
                )                })
            }
        }
    }
    
    private func loadCachedPosts() async {
        let cached = coreDataManager.fetchCachedPosts()
        DispatchQueue.main.async {
            self.posts = cached
        }
    }
    
    private func likeOriginalPost(_ post: Post) async {
        guard let postIndex = posts.firstIndex(where: { $0.id == post.id }) else { return }
        
        do {
            let updatedPost = try await apiService.likePost(postId: post.id)
            
            DispatchQueue.main.async {
                self.posts[postIndex] = updatedPost
            }
            
            // Cache updated posts
            coreDataManager.cachePosts(posts)
            print("Updated like status for post: \(post.id)")
            
        } catch {
            print("Error liking post: \(error)")
        }
    }
    
    private func shareOriginalPost(_ post: Post) async {
        do {
            let updatedPost = try await apiService.sharePost(postId: post.id)
            
            // Update local post data
            if let postIndex = posts.firstIndex(where: { $0.id == post.id }) {
                DispatchQueue.main.async {
                    self.posts[postIndex] = updatedPost
                }
                
                // Cache updated posts
                coreDataManager.cachePosts(posts)
            }
            
            print("Shared post: \(post.id)")
            
        } catch {
            print("Error sharing post: \(error)")
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

// MARK: - WebSocket Handlers
extension DiscoverViewModel {
    private func handleContentUpdate(_ update: ContentUpdate) {
        DispatchQueue.main.async {
            // Update posts if content changed
            if let postIndex = self.posts.firstIndex(where: { $0.id == update.contentId }) {
                // Update the post with new data from update
                // This would depend on the ContentUpdate structure
                print("Content update received for post: \(update.contentId)")
            }
        }
    }
    
    private func handleTrendingUpdate(_ update: TrendingUpdate) {
        DispatchQueue.main.async {
            // Update trending topics if they changed
            self.trendingTopics = update.topics
            
            // Cache updated trending topics
            self.coreDataManager.cacheTrendingTopics(update.topics)
            print("Trending topics updated: \(update.topics)")
        }
    }
}

// MARK: - Filtered Posts Computed Property
extension DiscoverViewModel {
    var filteredPosts: [Post] {
        var filtered = searchText.isEmpty ? posts : posts.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
        
        if selectedCategory != "All" {
            filtered = filtered.filter { post in
                post.category.rawValue.localizedCaseInsensitiveContains(selectedCategory) ||
                post.tags.contains { $0.localizedCaseInsensitiveContains(selectedCategory) }
            }
        }
        
        return filtered
    }
}
