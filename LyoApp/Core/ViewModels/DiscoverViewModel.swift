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
    
    private var currentPage = 1
    private let pageSize = 20
    private var cancellables = Set<AnyCancellable>()
    private let postService = PostAPIService.shared
    private let dataManager = DataManager.shared
    private let analyticsService = AnalyticsAPIService.shared
    
    let categories = ["All", "Programming", "Design", "Data Science", "Marketing", "Business", "Art", "Music", "Language"]
    
    init() {
        setupNotifications()
        setupSearchDebounce()
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
        
        async let postsTask = loadPosts()
        async let trendingTask = loadTrendingTopics()
        async let creatorsTask = loadFeaturedCreators()
        
        await postsTask
        await trendingTask
        await creatorsTask
        
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
        currentPage = 1
        hasMoreContent = true
        posts.removeAll()
        discoverPosts.removeAll()
        await loadContent()
    }
    
    func searchContent() async {
        guard !searchText.isEmpty else {
            discoverPosts = []
            return
        }
        
        isSearching = true
        
        do {
            // In a real app, you'd have a dedicated search endpoint
            let searchResults: [Post] = try await postService.getFeed(page: 1, limit: 50).posts
            
            // Filter results based on search text and category
            let filtered = searchResults.filter { post in
                let matchesSearch = post.content.localizedCaseInsensitiveContains(searchText) ||
                                  post.author.username.localizedCaseInsensitiveContains(searchText)
                
                let matchesCategory = selectedCategory == "All" || 
                                    post.content.localizedCaseInsensitiveContains(selectedCategory)
                
                return matchesSearch && matchesCategory
            }
            
            // Convert to DiscoverPost format for compatibility
            discoverPosts = filtered.compactMap { post in
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
            await analyticsService.trackEvent(
                Constants.AnalyticsEvents.searchPerformed,
                parameters: [
                    "query": searchText,
                    "category": selectedCategory,
                    "results_count": discoverPosts.count
                ]
            )
            
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
        }
        
        // Track analytics
        await analyticsService.trackEvent(
            discoverPosts.first(where: { $0.id == post.id })?.isBookmarked == true ? "post_bookmarked" : "post_unbookmarked",
            parameters: ["post_id": post.id.uuidString]
        )
    }
    
    func followCreator(_ creator: User) async {
        // In a real app, you'd have a follow/unfollow endpoint
        // For now, just track analytics
        await analyticsService.trackEvent(
            "creator_followed",
            parameters: ["creator_id": creator.id, "creator_username": creator.username]
        )
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
            
            // Cache data
            dataManager.saveForOffline(posts, key: "discover_posts")
            
        } catch {
            errorMessage = "Failed to load posts: \(error.localizedDescription)"
            
            if currentPage == 1 {
                loadCachedPosts()
            }
        }
    }
    
    private func loadTrendingTopics() async {
        // For now, generate trending topics from posts
        // In a real app, this would come from a dedicated endpoint
        let allContent = posts.map { $0.content }.joined(separator: " ")
        trendingTopics = extractTrendingTopics(from: allContent)
        dataManager.saveForOffline(trendingTopics, key: "trending_topics")
    }
    
    private func loadFeaturedCreators() async {
        // For now, extract unique creators from posts
        // In a real app, this would come from a dedicated endpoint
        featuredCreators = Array(Set(posts.map { $0.author })).prefix(10).map { $0 }
        dataManager.saveForOffline(featuredCreators, key: "featured_creators")
    }
    
    private func loadCachedData() {
        loadCachedPosts()
        
        if let cached: [String] = dataManager.loadFromOffline([String].self, key: "trending_topics") {
            trendingTopics = cached
        }
        
        if let cached: [User] = dataManager.loadFromOffline([User].self, key: "featured_creators") {
            featuredCreators = cached
        }
    }
    
    private func loadCachedPosts() {
        if let cached: [Post] = dataManager.loadFromOffline([Post].self, key: "discover_posts") {
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
                let response: LikeResponse = try await postService.likePost(postId: post.id)
                posts[index].likeCount = response.likeCount
            } else {
                let response: LikeResponse = try await postService.unlikePost(postId: post.id)
                posts[index].likeCount = response.likeCount
            }
        } catch {
            // Revert on error
            posts[index].isLiked.toggle()
            posts[index].likeCount += posts[index].isLiked ? 1 : -1
            errorMessage = "Failed to update like status"
        }
    }
    
    private func shareOriginalPost(_ post: Post) async {
        do {
            let _: ShareResponse = try await postService.sharePost(postId: post.id)
            
            if let index = posts.firstIndex(where: { $0.id == post.id }) {
                posts[index].shareCount += 1
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