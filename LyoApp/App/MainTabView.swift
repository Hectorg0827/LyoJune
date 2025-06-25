import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var tabBarOpacity: Double = 1.0
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeFeedView()
                .tabItem {
                    Image(systemName: appState.selectedTab == .home ? 
                          AppState.TabItem.home.selectedIcon : 
                          AppState.TabItem.home.icon)
                    Text(AppState.TabItem.home.title)
                }
                .tag(AppState.TabItem.home)
            
            DiscoverView()
                .tabItem {
                    Image(systemName: appState.selectedTab == .discover ? 
                          AppState.TabItem.discover.selectedIcon : 
                          AppState.TabItem.discover.icon)
                    Text(AppState.TabItem.discover.title)
                }
                .tag(AppState.TabItem.discover)
            
            LearnView()
                .tabItem {
                    Image(systemName: appState.selectedTab == .learn ? 
                          AppState.TabItem.learn.selectedIcon : 
                          AppState.TabItem.learn.icon)
                    Text(AppState.TabItem.learn.title)
                }
                .tag(AppState.TabItem.learn)
            
            PostView()
                .tabItem {
                    Image(systemName: appState.selectedTab == .post ? 
                          AppState.TabItem.post.selectedIcon : 
                          AppState.TabItem.post.icon)
                    Text(AppState.TabItem.post.title)
                }
                .tag(AppState.TabItem.post)
            
            CommunityView()
                .tabItem {
                    Image(systemName: appState.selectedTab == .community ? 
                          AppState.TabItem.community.selectedIcon : 
                          AppState.TabItem.community.icon)
                    Text(AppState.TabItem.community.title)
                }
                .tag(AppState.TabItem.community)
            
            ProfileView()
                .tabItem {
                    Image(systemName: appState.selectedTab == .profile ? 
                          AppState.TabItem.profile.selectedIcon : 
                          AppState.TabItem.profile.icon)
                    Text(AppState.TabItem.profile.title)
                }
                .tag(AppState.TabItem.profile)
        }
        .accentColor(.blue)
        .opacity(tabBarOpacity)
        .onChange(of: appState.selectedTab) { _, newValue in
            withAnimation(.easeInOut(duration: 0.2)) {
                tabBarOpacity = 0.8
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    tabBarOpacity = 1.0
                }
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
        .environmentObject(LyoAuthService())
}