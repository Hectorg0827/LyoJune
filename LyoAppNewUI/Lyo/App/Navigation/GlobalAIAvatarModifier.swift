import SwiftUI

/// A view modifier that adds a global, floating AI Avatar button and the logic to present the AI chat sheet.
private struct GlobalAIAvatarModifier: ViewModifier {

    @EnvironmentObject private var coordinator: AICoordinator

    // In a real app, the dependencies for the TutorView would be passed down
    // from a higher-level coordinator or factory.
    private var tutorService: TutorServicing

    init() {
        // This is a simplified dependency setup for demonstration.
        let authService = AuthService(baseURL: AppConfig.baseURL, session: .shared, storage: KeychainStorage())
        let httpClient = HTTPClient(baseURL: AppConfig.baseURL, authService: authService)
        self.tutorService = TutorService(httpClient: httpClient)
    }

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottomTrailing) {
                AIAvatarButton(action: coordinator.showChat)
                    .padding()
            }
            .sheet(isPresented: $coordinator.isChatPresented) {
                // The sheet's content is the intent-gathering chat view.
                // We are reusing the TutorView for this.
                let viewModel = TutorViewModel(tutorService: tutorService)
                TutorView(viewModel: viewModel)
            }
    }
}

// MARK: - View Extension

extension View {

    /// Applies a global, floating AI Avatar button and its associated sheet presentation logic to the view.
    func globalAIAvatar() -> some View {
        self.modifier(GlobalAIAvatarModifier())
    }
}
