import SwiftUI

struct HomeFeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @State private var currentVideoIndex = 0
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            GlassBackground()
            
            TabView(selection: $currentVideoIndex) {
                ForEach(Array(viewModel.videos.enumerated()), id: \.offset) { index, video in
                    TikTokVideoView(
                        video: video,
                        isCurrentVideo: currentVideoIndex == index
                    )
                    .tag(index)
                    .onAppear {
                        if index == viewModel.videos.count - 2 {
                            Task {
                                await viewModel.loadMoreVideos()
                            }
                        }
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .ignoresSafeArea()
            
            // Dynamic Header
            VStack {
                LyoHeaderView()
                Spacer()
            }
            
            // Study Buddy FAB
            StudyBuddyFAB(screenContext: "home")
            
            // Loading indicator
            if viewModel.isLoading && viewModel.videos.isEmpty {
                ProgressView()
                    .scaleEffect(1.5)
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            Task {
                await viewModel.loadVideos()
            }
        }
    }
}


struct TikTokVideoView: View {
    let video: EducationalVideo
    let isCurrentVideo: Bool
    @State private var isLiked = false
    @State private var isBookmarked = false
    @State private var showComments = false
    @State private var isFollowing = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Video Background with Glassmorphism
                VideoBackground(video: video)
                
                // Content Overlay
                VStack {
                    Spacer()
                    
                    HStack(alignment: .bottom) {
                        // Left side - Video info
                        VideoInfoSection(
                            video: video,
                            isFollowing: $isFollowing
                        )
                        
                        Spacer()
                        
                        // Right side - Actions
                        VideoActionsSection(
                            video: video,
                            isLiked: $isLiked,
                            isBookmarked: $isBookmarked,
                            showComments: $showComments
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .ignoresSafeArea()
        .onTapGesture(count: 2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isLiked.toggle()
            }
        }
    }
}

struct VideoBackground: View {
    let video: EducationalVideo
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        video.category.color.opacity(0.4),
                        Color.black.opacity(0.8),
                        video.category.color.opacity(0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                VStack {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.8))
                        .shadow(color: .black.opacity(0.3), radius: 10)
                    
                    Text("Educational Video")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            )
    }
}

struct VideoInfoSection: View {
    let video: EducationalVideo
    @Binding var isFollowing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author info
            HStack {
                Circle()
                    .fill(video.category.gradient)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(video.author.prefix(1)))
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("@\(video.author)")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Text(video.category.name)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                FollowButton(isFollowing: $isFollowing)
            }
            
            // Video title
            VideoTitleCard(title: video.title)
            
            // Tags
            VideoTagsScroll(tags: video.tags)
        }
    }
}

struct FollowButton: View {
    @Binding var isFollowing: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isFollowing.toggle()
            }
        }) {
            Text(isFollowing ? "Following" : "Follow")
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Material.ultraThin)
                        .background(isFollowing ? Color.clear : Color.blue.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
                .foregroundColor(.white)
        }
        .scaleEffect(isFollowing ? 0.95 : 1.0)
    }
}

struct VideoTitleCard: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.body)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Material.ultraThin)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .multilineTextAlignment(.leading)
            .lineLimit(3)
    }
}

struct VideoTagsScroll: View {
    let tags: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
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
}

struct VideoActionsSection: View {
    let video: EducationalVideo
    @Binding var isLiked: Bool
    @Binding var isBookmarked: Bool
    @Binding var showComments: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Like button
            ActionButton(
                icon: isLiked ? "heart.fill" : "heart",
                count: video.likes + (isLiked ? 1 : 0),
                color: isLiked ? .red : .white,
                action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isLiked.toggle()
                    }
                }
            )
            
            // Comment button
            ActionButton(
                icon: "message",
                count: video.comments,
                color: .white,
                action: { showComments.toggle() }
            )
            
            // Share button
            ActionButton(
                icon: "square.and.arrow.up",
                text: "Share",
                color: .white,
                action: {}
            )
            
            // Bookmark button
            BookmarkButton(isBookmarked: $isBookmarked)
        }
    }
}

struct ActionButton: View {
    let icon: String
    var count: Int?
    var text: String?
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Circle()
                    .fill(Material.ultraThin)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(color)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                if let count = count {
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                } else if let text = text {
                    Text(text)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct BookmarkButton: View {
    @Binding var isBookmarked: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isBookmarked.toggle()
            }
        }) {
            Circle()
                .fill(Material.ultraThin)
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.title2)
                        .foregroundColor(isBookmarked ? .yellow : .white)
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
        .scaleEffect(isBookmarked ? 1.1 : 1.0)
    }
}

#Preview {
    HomeFeedView()
}