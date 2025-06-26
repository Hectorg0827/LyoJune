import SwiftUI
import Foundation

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var tabBarOpacity: Double = 1.0
    @State private var previousTab: AppState.TabItem = .home
    @Namespace private var tabAnimation
    
    var body: some View {
        ZStack {
            // Dynamic background that adapts to selected tab
            tabBackground
                .ignoresSafeArea()
            
            TabView(selection: $appState.selectedTab) {
                HomeFeedView()
                    .tabItem {
                        tabItemView(for: .home)
                    }
                    .tag(AppState.TabItem.home)
                
                DiscoverView()
                    .tabItem {
                        tabItemView(for: .discover)
                    }
                    .tag(AppState.TabItem.discover)
                
                LearnView()
                    .tabItem {
                        tabItemView(for: .learn)
                    }
                    .tag(AppState.TabItem.learn)
                
                PostView()
                    .tabItem {
                        tabItemView(for: .post)
                    }
                    .tag(AppState.TabItem.post)
                
                CommunityView()
                    .tabItem {
                        tabItemView(for: .community)
                    Text(AppState.TabItem.community.title)
                }
                .tag(AppState.TabItem.community)
            
            ProfileView()
                .tabItem {
                    tabItemView(for: .profile)
                }
                .tag(AppState.TabItem.profile)
        }
        .accentColor(ModernDesignSystem.Colors.primary)
        .onAppear {
            configureTabBarAppearance()
        }
        .onChange(of: appState.selectedTab) { _, newValue in
            handleTabChange(from: previousTab, to: newValue)
            previousTab = newValue
        }
        .overlay {
            GamificationOverlay()
        }
    } // End of ZStack
    } // End of body property
    
    // MARK: - Private Views
    
    @ViewBuilder
    private func tabItemView(for tab: AppState.TabItem) -> some View {
        VStack(spacing: ModernDesignSystem.Spacing.xs) {
            Image(systemName: appState.selectedTab == tab ? tab.selectedIcon : tab.icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(appState.selectedTab == tab ? ModernDesignSystem.Colors.primary : ModernDesignSystem.Colors.neutral400)
                .scaleEffect(appState.selectedTab == tab ? 1.1 : 1.0)
                .animation(ModernDesignSystem.Animations.springSnappy, value: appState.selectedTab)
            
            Text(tab.title)
                .font(ModernDesignSystem.Typography.caption)
                .foregroundColor(appState.selectedTab == tab ? ModernDesignSystem.Colors.primary : ModernDesignSystem.Colors.neutral400)
        }
    }
    
    @ViewBuilder
    private var tabBackground: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: backgroundColorTop, location: 0.0),
                .init(color: backgroundColorBottom, location: 1.0)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .animation(ModernDesignSystem.Animations.easeInOut, value: appState.selectedTab)
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColorTop: Color {
        switch appState.selectedTab {
        case .home:
            return ModernDesignSystem.Colors.backgroundSecondary
        case .discover:
            return ModernDesignSystem.Colors.accent.opacity(0.1)
        case .learn:
            return ModernDesignSystem.Colors.success.opacity(0.1)
        case .post:
            return ModernDesignSystem.Colors.secondary.opacity(0.1)
        case .community:
            return ModernDesignSystem.Colors.warning.opacity(0.1)
        case .profile:
            return ModernDesignSystem.Colors.primary.opacity(0.1)
        }
    }
    
    private var backgroundColorBottom: Color {
        ModernDesignSystem.Colors.backgroundPrimary
    }
    
    // MARK: - Private Methods
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        
        // Modern blur effect
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundEffect = blurEffect
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func handleTabChange(from previousTab: AppState.TabItem, to newTab: AppState.TabItem) {
        // Haptic feedback for tab changes
        HapticManager.shared.selectionChanged()
        
        // Smooth animation
        withAnimation(ModernDesignSystem.Animations.springSnappy) {
            tabBarOpacity = 0.9
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(ModernDesignSystem.Animations.springSnappy) {
                tabBarOpacity = 1.0
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
        .environmentObject(EnhancedAuthService.shared)
}