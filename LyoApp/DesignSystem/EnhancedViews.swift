import SwiftUI

/// Enhanced Main Tab View with modern design system
struct EnhancedMainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var tabBarOpacity: Double = 1.0
    @State private var previousTab: AppState.TabItem = .home
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            EnhancedHomeFeedView()
                .tabItem {
                    TabItemView(
                        item: .home,
                        isSelected: appState.selectedTab == .home
                    )
                }
                .tag(AppState.TabItem.home)
            
            EnhancedDiscoverView()
                .tabItem {
                    TabItemView(
                        item: .discover,
                        isSelected: appState.selectedTab == .discover
                    )
                }
                .tag(AppState.TabItem.discover)
            
            EnhancedLearnView()
                .tabItem {
                    TabItemView(
                        item: .learn,
                        isSelected: appState.selectedTab == .learn
                    )
                }
                .tag(AppState.TabItem.learn)
            
            EnhancedPostView()
                .tabItem {
                    TabItemView(
                        item: .post,
                        isSelected: appState.selectedTab == .post
                    )
                }
                .tag(AppState.TabItem.post)
            
            EnhancedCommunityView()
                .tabItem {
                    TabItemView(
                        item: .community,
                        isSelected: appState.selectedTab == .community
                    )
                }
                .tag(AppState.TabItem.community)
            
            EnhancedProfileView()
                .tabItem {
                    TabItemView(
                        item: .profile,
                        isSelected: appState.selectedTab == .profile
                    )
                }
                .tag(AppState.TabItem.profile)
        }
        .accentColor(DesignTokens.Colors.primary)
        .onAppear {
            setupTabBarAppearance()
        }
        .onChange(of: appState.selectedTab) { _, newTab in
            handleTabChange(from: previousTab, to: newTab)
            previousTab = newTab
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        
        // Configure transparent background
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor(DesignTokens.Colors.surface.opacity(0.8))
        
        // Configure item colors
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(DesignTokens.Colors.textSecondary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(DesignTokens.Colors.textSecondary),
            .font: UIFont.systemFont(ofSize: 12, weight: .medium)
        ]
        
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(DesignTokens.Colors.primary)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(DesignTokens.Colors.primary),
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func handleTabChange(from previousTab: AppState.TabItem, to newTab: AppState.TabItem) {
        // Haptic feedback for tab changes
        HapticManager.shared.selectionFeedback()
        
        // Log analytics or perform other actions
        print("Tab changed from \(previousTab) to \(newTab)")
    }
}

/// Enhanced Tab Item View with modern design
struct TabItemView: View {
    let item: AppState.TabItem
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.extraSmall) {
            Image(systemName: isSelected ? item.selectedIcon : item.icon)
                .font(.system(size: 20, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.textSecondary)
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            
            Text(item.title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.textSecondary)
        }
    }
}

/// Enhanced Home Feed View with modern loading states
struct EnhancedHomeFeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @State private var currentVideoIndex = 0
    @State private var dragOffset: CGFloat = 0
    
    
    var body: some View {
        ZStack {
            // Modern gradient background
            LinearGradient(
                colors: [
                    DesignTokens.Colors.background,
                    DesignTokens.Colors.surface.opacity(0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.videos.isEmpty {
                SkeletonLoader.feedList()
                    .transition(.opacity)
            } else {
                TabView(selection: $currentVideoIndex) {
                    ForEach(Array(viewModel.videos.enumerated()), id: \.offset) { index, video in
                        EnhancedTikTokVideoView(
                            video: video,
                            isCurrentVideo: currentVideoIndex == index
                        )
                        .tag(index)
                        .onAppear {
                            if index == viewModel.videos.count - 2 {
                                // Load more videos if needed
                            }
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .ignoresSafeArea()
                .transition(.slide)
            }
            
            // Dynamic Header
            VStack {
                LyoHeaderView()
                Spacer()
            }
            
            // Enhanced Study Buddy FAB
            EnhancedFloatingActionButton(
                icon: "brain.head.profile",
                action: {
                    HapticManager.shared.selectionFeedback()
                    // Handle Study Buddy action
                }
            )
        }
        .onAppear {
            Task {
                await loadContent()
            }
        }
        .refreshable {
            // Use existing method or create simple refresh
            viewModel.isLoading = true
            await viewModel.loadContent()
        }
    }
    
    private func loadContent() async {
        // Load videos using available method or mock data
        await viewModel.loadContent()
    }
}

/// Enhanced TikTok-style video view
struct EnhancedTikTokVideoView: View {
    let video: EducationalVideo
    let isCurrentVideo: Bool
    @State private var isLiked = false
    @State private var isBookmarked = false
    
    var body: some View {
        ZStack {
            // Video placeholder (replace with actual video player)
            AsyncImage(url: URL(string: video.thumbnailURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                SkeletonLoader.rectangle(width: 200, height: 300)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            
            // Overlay gradient
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Content overlay
            VStack {
                Spacer()
                
                HStack(alignment: .bottom) {
                    // Video info
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                        Text(video.title)
                            .font(DesignTokens.Typography.headlineSmall)
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        Text("By \(video.author)")
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: DesignTokens.Spacing.medium) {
                        // Like button
                        AnimatedButton(
                            icon: isLiked ? "heart.fill" : "heart",
                            isActive: isLiked,
                            action: {
                                HapticManager.shared.selectionFeedback()
                                isLiked.toggle()
                            }
                        )
                        
                        // Bookmark button
                        AnimatedButton(
                            icon: isBookmarked ? "bookmark.fill" : "bookmark",
                            isActive: isBookmarked,
                            action: {
                                HapticManager.shared.selectionFeedback()
                                isBookmarked.toggle()
                            }
                        )
                        
                        // Share button
                        AnimatedButton(
                            icon: "square.and.arrow.up",
                            isActive: false,
                            action: {
                                HapticManager.shared.selectionFeedback()
                                // Handle share action
                            }
                        )
                    }
                }
                .padding(DesignTokens.Spacing.medium)
            }
        }
        .onAppear {
            if isCurrentVideo {
                HapticManager.shared.selectionFeedback()
            }
        }
    }
}

/// Animated button for video interactions
struct AnimatedButton: View {
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(isActive ? DesignTokens.Colors.primary : .white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .background(.ultraThinMaterial)
                )
                .scaleEffect(isActive ? 1.2 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isActive)
        }
        .buttonStyle(.plain)
    }
}

// Placeholder views for other enhanced views
struct EnhancedDiscoverView: View {
    var body: some View {
        DiscoverView() // Will be enhanced later
    }
}

struct EnhancedLearnView: View {
    var body: some View {
        LearnView() // Will be enhanced later
    }
}

struct EnhancedPostView: View {
    var body: some View {
        PostView() // Will be enhanced later
    }
}

struct EnhancedCommunityView: View {
    var body: some View {
        CommunityView() // Will be enhanced later
    }
}

struct EnhancedProfileView: View {
    var body: some View {
        Text("Profile View")
            .font(DesignTokens.Typography.headlineLarge)
            .foregroundColor(DesignTokens.Colors.textPrimary)
    }
}

struct EnhancedAuthenticationView: View {
    var body: some View {
        AuthenticationView() // Will be enhanced later
    }
}

#Preview {
    EnhancedMainTabView()
        .environmentObject(AppState())
}
