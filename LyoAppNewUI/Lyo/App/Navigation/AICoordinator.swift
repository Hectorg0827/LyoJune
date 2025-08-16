import Foundation

/// An observable object responsible for coordinating global AI-related UI actions,
/// such as presenting the AI chat interface.
@MainActor
final class AICoordinator: ObservableObject {

    @Published var isChatPresented: Bool = false

    func showChat() {
        isChatPresented = true
    }

    func hideChat() {
        isChatPresented = false
    }
}
