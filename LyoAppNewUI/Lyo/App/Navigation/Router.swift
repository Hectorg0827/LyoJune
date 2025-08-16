import SwiftUI

@MainActor
final class Router: ObservableObject {

    @Published var path = NavigationPath()

    // In a real app, dependencies for destination views would be injected here.
    // For now, we will initialize them in the view builder.

    func navigate(to destination: DeepLink) {
        path.append(destination)
    }

    func handle(urlString: String) {
        guard let url = URL(string: urlString),
              url.scheme == "lyo",
              let host = url.host else {
            print("Invalid deep link string: \(urlString)")
            return
        }

        let pathComponents = url.pathComponents.filter { $0 != "/" }

        var deepLink: DeepLink?

        switch host {
        case "chat":
            if let chatId = pathComponents.first {
                deepLink = .chat(chatId: chatId)
            }
        case "course":
            if let courseId = pathComponents.first {
                deepLink = .courseOverview(courseId: courseId)
            }
        // Add other hosts like "post", "profile", etc. here
        default:
            print("Unknown deep link host: \(host)")
        }

        if let deepLink = deepLink {
            navigate(to: deepLink)
        }
    }

    @ViewBuilder
    func view(for destination: DeepLink) -> some View {
        // This is where we map a DeepLink to a View.
        // This switch statement will grow as we add more destinations.
        switch destination {
        case .chat(let chatId):
            let messagingService = MessagingService(httpClient: buildHttpClient())
            let webSocketService = WebSocketService(webSocketURL: AppConfig.webSocketURL)
            let viewModel = ChatViewModel(chatId: chatId, messagingService: messagingService, webSocketService: webSocketService)
            ChatView(viewModel: viewModel)

        case .courseOverview(let courseId):
            // In a real app, we would fetch the Course object from a cache or service.
            let course = Course(id: UUID(uuidString: courseId) ?? UUID(), title: "Course", description: "Details...", thumbnailURL: nil)
            let learnService = LearnService(httpClient: buildHttpClient())
            let viewModel = CourseOverviewViewModel(course: course, learnService: learnService)
            CourseOverviewView(course: course, viewModel: viewModel)

        case .profile(let userId):
            let profileService = ProfileAndSettingsService(httpClient: buildHttpClient())
            let viewModel = ProfileViewModel(userId: UUID(uuidString: userId) ?? UUID(), profileService: profileService)
            ProfileView(viewModel: viewModel)

        default:
            Text("Unknown Destination: \(String(describing: destination))")
        }
    }

    // Helper to build a default HTTPClient. In a real app, this would come from a DI container.
    private func buildHttpClient() -> HTTPClienting {
        // This creates a circular dependency if not handled carefully.
        // For now, we create a temporary auth service.
        // A better DI system would solve this.
        let tempAuthService = AuthService(baseURL: AppConfig.baseURL, session: .shared, storage: KeychainStorage())
        return HTTPClient(baseURL: AppConfig.baseURL, authService: tempAuthService)
    }
}
