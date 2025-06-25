import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var selectedTab: TabItem = .home
    @Published var isOnboarded = UserDefaults.standard.bool(forKey: "isOnboarded")
    @Published var showingSettings = false
    @Published var networkStatus: NetworkStatus = .connected
    @Published var currentTheme: AppTheme = .dark
    
    enum TabItem: Int, CaseIterable {
        case home = 0
        case discover = 1
        case learn = 2
        case post = 3
        case community = 4
        case profile = 5
        
        var title: String {
            switch self {
            case .home: return "Home"
            case .discover: return "Discover"
            case .learn: return "Learn"
            case .post: return "Post"
            case .community: return "Community"
            case .profile: return "Profile"
            }
        }
        
        var icon: String {
            switch self {
            case .home: return "house"
            case .discover: return "magnifyingglass"
            case .learn: return "book"
            case .post: return "plus.circle"
            case .community: return "person.3"
            case .profile: return "person"
            }
        }
        
        var selectedIcon: String {
            switch self {
            case .home: return "house.fill"
            case .discover: return "magnifyingglass"
            case .learn: return "book.fill"
            case .post: return "plus.circle.fill"
            case .community: return "person.3.fill"
            case .profile: return "person.fill"
            }
        }
    }
    
    enum NetworkStatus {
        case connected
        case disconnected
        case limited
    }
    
    enum AppTheme {
        case light
        case dark
        case system
    }
    
    func completeOnboarding() {
        isOnboarded = true
        UserDefaults.standard.set(true, forKey: "isOnboarded")
    }
    
    func resetOnboarding() {
        isOnboarded = false
        UserDefaults.standard.set(false, forKey: "isOnboarded")
    }
    
    func selectTab(_ tab: TabItem) {
        selectedTab = tab
    }
}