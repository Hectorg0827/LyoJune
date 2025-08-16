import SwiftUI

/// A view modifier that adds a global, floating AI Avatar button and the logic to present the AI chat sheet.
private struct GlobalAIAvatarModifier: ViewModifier {

    @EnvironmentObject private var coordinator: AICoordinator
    @EnvironmentObject private var router: Router

    // In a real app, these dependencies would be passed down or provided by a DI container.
    private let tutorService: TutorServicing
    private let aiGeneratorService: AIGeneratorServicing

    init() {
        // This is a simplified dependency setup for demonstration.
        let authService = AuthService(baseURL: AppConfig.baseURL, session: .shared, storage: KeychainStorage())
        let httpClient = HTTPClient(baseURL: AppConfig.baseURL, authService: authService)
        self.tutorService = TutorService(httpClient: httpClient)
        self.aiGeneratorService = AIGeneratorService(httpClient: httpClient)
    }

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottomTrailing) {
                AIAvatarButton(action: coordinator.showChat)
                    .padding()
            }
            .sheet(isPresented: $coordinator.isChatPresented) {
                // The sheet's content is the intent-gathering chat view.
                let viewModel = TutorViewModel(
                    tutorService: tutorService,
                    aiGeneratorService: aiGeneratorService,
                    router: router,
                    aiCoordinator: coordinator
                )
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
