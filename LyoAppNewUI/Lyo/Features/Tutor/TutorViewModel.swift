import Foundation

@MainActor
final class TutorViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var messages: [TutorMessage] = []
    @Published private(set) var isSending: Bool = false
    @Published var errorToast: Toast? = nil

    // MARK: - Private Properties

    private let tutorService: TutorServicing
    private let learnerId: String = "user-123" // This would be fetched from a user session object in a real app.

    // MARK: - Initialization

    init(tutorService: TutorServicing) {
        self.tutorService = tutorService
    }

    // MARK: - Public Intent Methods

    /// Fetches the initial chat history or starts a new session.
    func loadInitialState() {
        Task {
            do {
                let state = try await tutorService.getState(for: learnerId)
                self.messages = state.history
            } catch {
                // If getState fails (e.g., 404 for a new user), start with a welcome message.
                self.messages = [
                    .init(id: UUID(), sender: .tutor, type: .text, text: "Hello! What would you like to learn about today?", question: nil)
                ]
            }
        }
    }

    /// Sends a text message from the user to the tutor.
    func sendMessage(_ text: String) {
        let userMessage = TutorMessage(id: UUID(), sender: .user, type: .text, text: text, question: nil)
        messages.append(userMessage)

        postTurn(text: text, selectedOptionId: nil)
    }

    /// Handles the user selecting an answer to a question.
    func answerQuestion(questionId: UUID, option: Question.Option) {
        let userMessage = TutorMessage(id: UUID(), sender: .user, type: .text, text: option.text, question: nil)
        messages.append(userMessage)

        // The `text` field could be empty if we only want to send the option ID.
        // This depends on the backend API contract.
        postTurn(text: option.text, selectedOptionId: option.id)
    }

    // MARK: - Private Logic

    private func postTurn(text: String, selectedOptionId: String?) {
        isSending = true

        Task {
            do {
                let responseMessages = try await tutorService.postTurn(text: text, selectedOptionId: selectedOptionId)
                self.messages.append(contentsOf: responseMessages)
            } catch {
                self.errorToast = Toast(message: "Failed to get response from tutor.", style: .error)
                // Optional: remove the user's message if the send fails, or add a "failed to send" state.
            }

            isSending = false
        }
    }
}
