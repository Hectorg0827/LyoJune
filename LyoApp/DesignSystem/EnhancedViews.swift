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
        .onChange(of: appState.selectedTab) { newTab in
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
        HapticManager.shared.selection()
        
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
                .animation(AnimationSystem.Presets.spring, value: isSelected)
            
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
    @State private var isLoading = true
    
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
            
            if isLoading && viewModel.videos.isEmpty {
                SkeletonLoader.feedList()
                    .transition(AnimationSystem.Presets.fadeInOut)
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
                                Task {
                                    await viewModel.loadMoreVideos()
                                }
                            }
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .ignoresSafeArea()
                .transition(AnimationSystem.Presets.slideUp)
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
                    HapticManager.shared.impact(.medium)
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
            await viewModel.refreshVideos()
        }
    }
    
    private func loadContent() async {
        isLoading = true
        await viewModel.loadVideos()
        
        // Simulate loading delay for better UX
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        withAnimation(AnimationSystem.Presets.easeInOut) {
            isLoading = false
        }
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
                SkeletonLoader.image(width: .infinity, height: .infinity)
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
                        
                        if let description = video.description {
                            Text(description)
                                .font(DesignTokens.Typography.bodyMedium)
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(3)
                        }
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: DesignTokens.Spacing.medium) {
                        // Like button
                        AnimatedButton(
                            icon: isLiked ? "heart.fill" : "heart",
                            isActive: isLiked,
                            action: {
                                HapticManager.shared.impact(.light)
                                isLiked.toggle()
                            }
                        )
                        
                        // Bookmark button
                        AnimatedButton(
                            icon: isBookmarked ? "bookmark.fill" : "bookmark",
                            isActive: isBookmarked,
                            action: {
                                HapticManager.shared.impact(.light)
                                isBookmarked.toggle()
                            }
                        )
                        
                        // Share button
                        AnimatedButton(
                            icon: "square.and.arrow.up",
                            isActive: false,
                            action: {
                                HapticManager.shared.impact(.light)
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
                HapticManager.shared.impact(.soft)
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
                        .backdrop(blur: 10)
                )
                .scaleEffect(isActive ? 1.2 : 1.0)
                .animation(AnimationSystem.Presets.bounceIn, value: isActive)
        }
        .buttonStyle(HapticButtonStyle())
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
