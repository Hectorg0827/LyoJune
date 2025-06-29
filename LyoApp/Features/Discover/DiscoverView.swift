import SwiftUI

struct DiscoverView: View {
    @StateObject private var viewModel = DiscoverViewModel()
    @State private var searchText = "" {
        didSet {
            viewModel.searchText = searchText
        }
    }
    @State private var selectedCategory = "All" {
        didSet {
            viewModel.selectedCategory = selectedCategory
        }
    }
    
    private let categories = ["All", "Tech", "Science", "Art", "Language", "Math", "History", "Physics"]
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.1), Color.gray.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: 0) {
                    // Dynamic Header
                    LyoHeaderView()
                    
                    // Category selector
                    CategorySelector(
                        selectedCategory: $selectedCategory,
                        categories: categories
                    )
                    
                    // Posts feed
                    PostsFeedView(
                        posts: viewModel.filteredPosts,
                        isLoading: viewModel.isLoading,
                        onRefresh: {
                            Task {
                                await viewModel.refreshContent()
                            }
                        },
                        onLoadMore: {
                            Task {
                                await viewModel.loadMoreContent()
                            }
                        }
                    )
                }
                
                // Study Buddy FAB
                StudyBuddyFAB(screenContext: "discover")
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Material.ultraThin, for: .navigationBar)
        }
        .onAppear {
            Task {
                await viewModel.loadContent()
            }
        }
    }
}

struct CategorySelector: View {
    @Binding var selectedCategory: String
    let categories: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    CategoryChip(
                        title: category,
                        isSelected: selectedCategory == category,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategory = category
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .fontWeight(isSelected ? .semibold : .medium)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Material.ultraThin)
                        .background(isSelected ? Color.blue.opacity(0.6) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
                .foregroundColor(.white)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct PostsFeedView: View {
    let posts: [DiscoverPost]
    let isLoading: Bool
    let onRefresh: () -> Void
    let onLoadMore: () -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(posts) { post in
                    DiscoverPostCard(post: post)
                        .onAppear {
                            if post.id == posts.last?.id {
                                onLoadMore()
                            }
                        }
                }
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .foregroundColor(.white)
                        .padding()
                }
            }
            .padding()
        }
        .refreshable {
            onRefresh()
        }
    }
}

struct DiscoverPostCard: View {
    let post: DiscoverPost
    @State private var isLiked = false
    @State private var isBookmarked = false
    @State private var showingComments = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Post header
            PostHeader(post: post, isBookmarked: $isBookmarked)
            
            // Post content
            PostContent(post: post)
            
            // Media if available
            if post.hasMedia {
                PostMediaView(post: post)
            }
            
            // Interaction bar
            PostInteractionBar(
                post: post,
                isLiked: $isLiked,
                showingComments: $showingComments
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Material.ultraThin)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct PostHeader: View {
    let post: DiscoverPost
    @Binding var isBookmarked: Bool
    
    var body: some View {
        HStack {
            Circle()
                .fill(post.category.gradient)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(post.author.prefix(1)))
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(post.author)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Text(post.timeAgo)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isBookmarked.toggle()
                }
            }) {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .foregroundColor(isBookmarked ? .yellow : .white.opacity(0.8))
                    .font(.system(size: 16))
            }
        }
        .padding()
    }
}

struct PostContent: View {
    let post: DiscoverPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(post.content)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
            
            // Tags
            if !post.tags.isEmpty {
                PostTagsView(tags: post.tags)
            }
        }
        .padding(.horizontal)
    }
}

struct PostTagsView: View {
    let tags: [String]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 80))
        ], alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text("#\(tag)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Material.ultraThin)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                            )
                    )
                    .foregroundColor(.blue.opacity(0.9))
            }
        }
    }
}

struct PostMediaView: View {
    let post: DiscoverPost
    
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .aspectRatio(16/9, contentMode: .fit)
            .cornerRadius(12)
            .overlay(
                VStack {
                    Image(systemName: post.mediaType?.icon ?? "photo")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(post.mediaType?.title ?? "Media")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            )
            .padding(.horizontal)
    }
}

struct PostInteractionBar: View {
    let post: DiscoverPost
    @Binding var isLiked: Bool
    @Binding var showingComments: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            // Like button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isLiked.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .white.opacity(0.8))
                    Text("\(post.likes + (isLiked ? 1 : 0))")
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // Comment button
            Button(action: {
                showingComments.toggle()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "message")
                        .foregroundColor(.white.opacity(0.8))
                    Text("\(post.comments)")
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // Share button
            Button(action: {}) {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.white.opacity(0.8))
                    Text("\(post.shares)")
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Spacer()
            
            Text("Read more")
                .font(.caption)
                .foregroundColor(.blue.opacity(0.8))
        }
        .font(.body)
        .padding()
    }
}

#Preview {
    DiscoverView()
}