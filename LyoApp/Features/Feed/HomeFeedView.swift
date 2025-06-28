import SwiftUI

// MARK: - Phase 2 Enhanced Home Feed View
// Modern, performant, and engaging video feed experience

struct HomeFeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @State private var currentVideoIndex = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isHeaderVisible = true
    @State private var scrollDirection: ScrollDirection = .none
    @State private var feedOpacity: Double = 1.0
    @State private var lastScrollPosition: CGFloat = 0
    
    enum ScrollDirection {
        case up, down, none
    }
    
    var body: some View {
        ZStack {
            // Dynamic background with video-aware colors
            modernBackground
                .ignoresSafeArea()
            
            // Main feed content
            feedContentView
            
            // Enhanced dynamic header
            enhancedHeaderView
            
            // Modern study buddy FAB
            modernStudyBuddyFAB
            
            // Enhanced loading states
            loadingStateView
        }
        .onAppear {
            setupFeed()
        }
        .refreshable {
            await viewModel.refreshFeed()
        }
    }
    
    // MARK: - Enhanced UI Components
    
    @ViewBuilder
    private var modernBackground: some View {
        ZStack {
            // Base dynamic background
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: currentVideoBackgroundColor.opacity(0.1), location: 0.0),
                    .init(color: ModernDesignSystem.Colors.backgroundPrimary, location: 0.3),
                    .init(color: ModernDesignSystem.Colors.backgroundSecondary, location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .animation(ModernDesignSystem.Animations.easeInOut, value: currentVideoIndex)
            
            // Subtle pattern overlay
            PatternOverlay()
                .opacity(0.02)
        }
    }
    
    @ViewBuilder
    private var feedContentView: some View {
        TabView(selection: $currentVideoIndex) {
            ForEach(Array(viewModel.videos.enumerated()), id: \.offset) { index, video in
                EnhancedTikTokVideoView(
                    video: video,
                    isCurrentVideo: currentVideoIndex == index,
                    onScrollDetection: { direction in
                        handleScrollDetection(direction)
                    }
                )
                .tag(index)
                .onAppear {
                    handleVideoAppearance(index: index)
                }
                .onDisappear {
                    handleVideoDisappearance(index: index)
                }
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .ignoresSafeArea()
        .opacity(feedOpacity)
        .animation(ModernDesignSystem.Animations.easeInOut, value: feedOpacity)
        .onChange(of: currentVideoIndex) { _, newIndex in
            handleVideoIndexChange(newIndex)
        }
    }
    
    @ViewBuilder
    private var enhancedHeaderView: some View {
        VStack {
            EnhancedLyoHeaderView(
                isMinimized: !isHeaderVisible,
                currentVideoTitle: currentVideo?.title,
                onHeaderTap: {
                    withAnimation(ModernDesignSystem.Animations.springSnappy) {
                        isHeaderVisible.toggle()
                    }
                }
            )
            .opacity(isHeaderVisible ? 1.0 : 0.3)
            .scaleEffect(isHeaderVisible ? 1.0 : 0.9)
            .animation(ModernDesignSystem.Animations.spring, value: isHeaderVisible)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var modernStudyBuddyFAB: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                EnhancedStudyBuddyFAB(
                    screenContext: "home",
                    isExpanded: isHeaderVisible,
                    onTap: {
                        HapticManager.shared.mediumImpact()
                        // Handle study buddy action
                    }
                )
                .padding(.trailing, ModernDesignSystem.Spacing.lg)
                .padding(.bottom, ModernDesignSystem.Spacing.xl)
            }
        }
        .ignoresSafeArea(.keyboard)
    }
    
    @ViewBuilder
    private var loadingStateView: some View {
        if viewModel.isLoading && viewModel.videos.isEmpty {
            ModernLoadingView(
                message: "Loading amazing content...",
                style: .shimmer
            )
            .transition(.opacity.combined(with: .scale))
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentVideo: Video? {
        guard currentVideoIndex < viewModel.videos.count else { return nil }
        return viewModel.videos[currentVideoIndex]
    }
    
    private var currentVideoBackgroundColor: Color {
        // Extract dominant color from current video or use default
        return ModernDesignSystem.Colors.accent
    }
    
    // MARK: - Private Methods
    
    private func setupFeed() {
        Task {
            await viewModel.loadVideos()
        }
    }
    
    private func handleVideoAppearance(index: Int) {
        if index == viewModel.videos.count - 2 {
            Task {
                await viewModel.loadMoreVideos()
            }
        }
        
        // Track video view
        if let video = viewModel.videos[safe: index] {
            // Analytics tracking would go here
        }
    }
    
    private func handleVideoDisappearance(index: Int) {
        // Handle video cleanup if needed
    }
    
    private func handleVideoIndexChange(_ newIndex: Int) {
        HapticManager.shared.lightImpact()
        
        // Update background color based on video
        withAnimation(ModernDesignSystem.Animations.easeInOut) {
            // Background color change animation
        }
    }
    
    private func handleScrollDetection(_ direction: ScrollDirection) {
        guard scrollDirection != direction else { return }
        
        scrollDirection = direction
        
        withAnimation(ModernDesignSystem.Animations.springSnappy) {
            switch direction {
            case .up:
                isHeaderVisible = false
            case .down:
                isHeaderVisible = true
            case .none:
                break
            }
        }
    }
}

// Use canonical EnhancedTikTokVideoView from DesignSystem/EnhancedViews.swift

// MARK: - Supporting Views

struct EnhancedLyoHeaderView: View {
    let isMinimized: Bool
    let currentVideoTitle: String?
    let onHeaderTap: () -> Void
    
    var body: some View {
        Button(action: onHeaderTap) {
            HStack {
                Text("LyoApp")
                    .font(isMinimized ? ModernDesignSystem.Typography.headlineSmall : ModernDesignSystem.Typography.headlineLarge)
                    .fontWeight(.bold)
                    .foregroundColor(ModernDesignSystem.Colors.primary)
                
                if let title = currentVideoTitle, isMinimized {
                    Text("• \(title)")
                        .font(ModernDesignSystem.Typography.bodyMedium)
                        .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "bell")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(ModernDesignSystem.Colors.textPrimary)
            }
            .padding(.horizontal, ModernDesignSystem.Spacing.lg)
            .padding(.vertical, ModernDesignSystem.Spacing.md)
            .background(
                Rectangle()
                    .fill(ModernDesignSystem.Colors.backgroundPrimary.opacity(0.8))
                    .blur(radius: 10)
            )
        }
    }
}

struct EnhancedStudyBuddyFAB: View {
    let screenContext: String
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ModernDesignSystem.Spacing.sm) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 20, weight: .medium))
                
                if isExpanded {
                    Text("Study Buddy")
                        .font(ModernDesignSystem.Typography.bodyMedium.weight(.semibold))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, isExpanded ? ModernDesignSystem.Spacing.lg : ModernDesignSystem.Spacing.md)
            .padding(.vertical, ModernDesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.full)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                ModernDesignSystem.Colors.accent,
                                ModernDesignSystem.Colors.secondary
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(
                color: ModernDesignSystem.Colors.accent.opacity(0.3),
                radius: 10,
                x: 0,
                y: 5
            )
        }
        .scaleEffect(isExpanded ? 1.0 : 0.9)
        .animation(ModernDesignSystem.Animations.springSnappy, value: isExpanded)
    }
}

// Use canonical ModernLoadingView from DesignSystem/ModernViews.swift

struct ModernTag: View {
    let text: String
    let style: Style
    
    enum Style {
        case primary, secondary, accent
    }
    
    var backgroundColor: Color {
        switch style {
        case .primary: return ModernDesignSystem.Colors.primary.opacity(0.2)
        case .secondary: return ModernDesignSystem.Colors.secondary.opacity(0.2)
        case .accent: return ModernDesignSystem.Colors.accent.opacity(0.2)
        }
    }
    
    var textColor: Color {
        switch style {
        case .primary: return ModernDesignSystem.Colors.primary
        case .secondary: return ModernDesignSystem.Colors.secondary
        case .accent: return ModernDesignSystem.Colors.accent
        }
    }
    
    var body: some View {
        Text("#\(text)")
            .font(ModernDesignSystem.Typography.caption.weight(.medium))
            .foregroundColor(textColor)
            .padding(.horizontal, ModernDesignSystem.Spacing.sm)
            .padding(.vertical, ModernDesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.full)
                    .fill(backgroundColor)
            )
    }
}

// MARK: - Extensions

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    HomeFeedView()
        .preferredColorScheme(.dark)
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