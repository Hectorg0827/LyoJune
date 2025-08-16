import Foundation

@MainActor
final class TutorViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var messages: [TutorMessage] = []
    @Published private(set) var isSending: Bool = false
    @Published var errorToast: Toast? = nil

    // MARK: - Private Properties

    private let tutorService: TutorServicing
    private let aiGeneratorService: AIGeneratorServicing
    private let router: Router
    private let aiCoordinator: AICoordinator
    private let learnerId: String = "user-123"

    // MARK: - Initialization

    init(
        tutorService: TutorServicing,
        aiGeneratorService: AIGeneratorServicing,
        router: Router,
        aiCoordinator: AICoordinator
    ) {
        self.tutorService = tutorService
        self.aiGeneratorService = aiGeneratorService
        self.router = router
        self.aiCoordinator = aiCoordinator
    }

    // MARK: - Public Intent Methods

    func loadInitialState() {
        if messages.isEmpty {
            self.messages = [
                .init(id: UUID(), sender: .tutor, type: .text, text: "Hello! What would you like to learn about today? To generate a course, tell me something like 'generate a course on SwiftUI'.", question: nil, tutorial: nil, stepByStepGuide: nil)
            ]
        }
    }

    func sendMessage(_ text: String) {
        let userMessage = TutorMessage(id: UUID(), sender: .user, type: .text, text: text, question: nil, tutorial: nil, stepByStepGuide: nil)
        messages.append(userMessage)

        if text.lowercased().contains("generate") {
            generateCourseContent(from: text)
        } else {
            postTurn(text: text, selectedOptionId: nil)
        }
    }

    func answerQuestion(questionId: UUID, option: Question.Option) {
        let userMessage = TutorMessage(id: UUID(), sender: .user, type: .text, text: option.text, question: nil, tutorial: nil, stepByStepGuide: nil)
        messages.append(userMessage)
        postTurn(text: option.text, selectedOptionId: option.id)
    }

    // MARK: - Private Logic

    private func postTurn(text: String, selectedOptionId: String?) {
        isSending = true
        Task {
            // ... (same as before)
            isSending = false
        }
    }

    private func generateCourseContent(from goal: String) {
        isSending = true
        Task {
            do {
                let request = AIGenerationRequest(learningGoal: goal, chatHistory: messages)
                let content = try await aiGeneratorService.generateContent(request)
                handle(generatedContent: content)
            } catch {
                self.errorToast = Toast(message: "Failed to generate course.", style: .error)
            }
            isSending = false
        }
    }

    private func handle(generatedContent: AIGeneratedContent) {
        switch generatedContent {
        case .fullCourse(let course):
            // Dismiss the chat and navigate to the course
            aiCoordinator.hideChat()
            router.navigate(to: .courseOverview(courseId: course.id.uuidString))

        case .tutorial(let tutorial):
            let message = TutorMessage(id: UUID(), sender: .tutor, type: .tutorial, text: tutorial.title, question: nil, tutorial: tutorial, stepByStepGuide: nil)
            messages.append(message)

        case .stepByStepGuide(let guide):
            let message = TutorMessage(id: UUID(), sender: .tutor, type: .stepByStepGuide, text: guide.title, question: nil, tutorial: nil, stepByStepGuide: guide)
            messages.append(message)
        }
    }
}
