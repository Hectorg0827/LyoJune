import SwiftUI

struct RootView: View {

    @StateObject private var router = Router()

    // In a real app, these would be built by a dependency injection container.
    // For now, we construct them here at the top level.
    private let feedService: FeedServicing
    private let learnService: LearnServicing
    private let tutorService: TutorServicing
    private let messagingService: MessagingServicing
    private let webSocketService: WebSocketServicing

    init() {
        // This is a simplified dependency setup for demonstration.
        let authService = AuthService(baseURL: AppConfig.baseURL, session: .shared, storage: KeychainStorage())
        let httpClient = HTTPClient(baseURL: AppConfig.baseURL, authService: authService)

        self.feedService = FeedService(httpClient: httpClient)
        self.learnService = LearnService(httpClient: httpClient)
        self.tutorService = TutorService(httpClient: httpClient)
        self.messagingService = MessagingService(httpClient: httpClient)
        self.webSocketService = WebSocketService(webSocketURL: AppConfig.webSocketURL)
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            TabView {
                FeedView(
                    feedViewModel: .init(feedService: feedService),
                    storiesViewModel: .init(feedService: feedService)
                )
                .tabItem { Label("Feed", systemImage: "house") }

                CourseListView(viewModel: .init(learnService: learnService))
                    .tabItem { Label("Learn", systemImage: "books.vertical") }

                TutorView(viewModel: .init(tutorService: tutorService))
                    .tabItem { Label("Tutor", systemImage: "message.circle") }

                ThreadsListView(viewModel: .init(messagingService: messagingService))
                    .tabItem { Label("Messages", systemImage: "bubble.left.and.bubble.right") }

                let notificationService = NotificationService(httpClient: httpClient)
                NotificationsView(viewModel: .init(notificationService: notificationService))
                    .tabItem { Label("Notifications", systemImage: "bell") }

                // This assumes we have a way to get the current user's ID.
                let currentUserId = UUID() // Placeholder for the actual current user ID
                let profileService = ProfileAndSettingsService(httpClient: httpClient)
                let profileViewModel = ProfileViewModel(userId: currentUserId, profileService: profileService)
                ProfileView(viewModel: profileViewModel)
                    .tabItem { Label("Profile", systemImage: "person.crop.circle") }
            }
            .navigationDestination(for: DeepLink.self) { destination in
                router.view(for: destination)
            }
        }
        .environmentObject(router)
    }
}
