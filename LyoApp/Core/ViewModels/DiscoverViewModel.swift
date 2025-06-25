import SwiftUI

@MainActor
class DiscoverViewModel: ObservableObject {
    @Published var posts: [DiscoverPost] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMoreContent = true
    
    private var currentPage = 0
    private let pageSize = 10
    
    func loadPosts() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            let newPosts = DiscoverPost.mockPosts()
            posts = newPosts
            currentPage = 1
        } catch {
            errorMessage = "Failed to load posts: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadMorePosts() async {
        guard !isLoading && hasMoreContent else { return }
        
        isLoading = true
        
        do {
            try await Task.sleep(nanoseconds: 500_000_000)
            
            let newPosts = DiscoverPost.mockPosts(offset: currentPage * pageSize)
            posts.append(contentsOf: newPosts)
            currentPage += 1
            
            if newPosts.count < pageSize {
                hasMoreContent = false
            }
        } catch {
            errorMessage = "Failed to load more posts"
        }
        
        isLoading = false
    }
    
    func refreshPosts() async {
        currentPage = 0
        hasMoreContent = true
        posts.removeAll()
        await loadPosts()
    }
    
    func filteredPosts(searchText: String, category: String) -> [DiscoverPost] {
        var filtered = posts
        
        // Filter by category
        if category != "All" {
            filtered = filtered.filter { post in
                post.category.name.lowercased().contains(category.lowercased()) ||
                post.tags.contains { $0.lowercased().contains(category.lowercased()) }
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { post in
                post.content.lowercased().contains(searchText.lowercased()) ||
                post.author.lowercased().contains(searchText.lowercased()) ||
                post.tags.contains { $0.lowercased().contains(searchText.lowercased()) }
            }
        }
        
        return filtered
    }
}