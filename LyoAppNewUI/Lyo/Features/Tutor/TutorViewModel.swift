import Foundation

@MainActor
final class TutorViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var messages: [TutorMessage] = []
    @Published private(set) var isSending: Bool = false
    @Published var errorToast: Toast? = nil
    @Published var generatedContent: AIGeneratedContent? = nil

    // Voice-to-Text Properties
    @Published private(set) var isListening: Bool = false
    @Published private(set) var liveTranscript: String = ""
    @Published var permissionManager = SpeechPermissionManager()

    // MARK: - Private Properties

    private let tutorService: TutorServicing
    private let aiGeneratorService: AIGeneratorServicing
    private let speechService: SpeechRecognitionServicing
    private let onDeviceAIService: OnDeviceAIServicing? // Optional because it might fail to init
    private let router: Router
    private let aiCoordinator: AICoordinator
    private let learnerId: String = "user-123"
    private var speechTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        tutorService: TutorServicing,
        aiGeneratorService: AIGeneratorServicing,
        speechService: SpeechRecognitionServicing,
        onDeviceAIService: OnDeviceAIServicing?,
        router: Router,
        aiCoordinator: AICoordinator
    ) {
        self.tutorService = tutorService
        self.aiGeneratorService = aiGeneratorService
        self.speechService = speechService
        self.onDeviceAIService = onDeviceAIService
        self.router = router
        self.aiCoordinator = aiCoordinator
    }

    // MARK: - Public Intent Methods

    func loadInitialState() { /* ... */ }
    func answerQuestion(questionId: UUID, option: Question.Option) { /* ... */ }

    func sendMessage(_ text: String) {
        let userMessage = TutorMessage(id: UUID(), sender: .user, type: .text, text: text, question: nil, tutorial: nil, stepByStepGuide: nil)
        messages.append(userMessage)

        // The on-device model would handle intent detection from text as well,
        // but for now, we keep the simple keyword-based trigger.
        if text.lowercased().contains("generate") {
            generateCourseContent(from: text)
        } else {
            postTurn(text: text, selectedOptionId: nil)
        }
    }

    // MARK: - Voice Methods

    func toggleListening() {
        isListening.toggle()
        if isListening {
            startListening()
        } else {
            stopListeningAndProcessIntent()
        }
    }

    private func startListening() { /* ... same as before ... */ }

    private func stopListeningAndProcessIntent() {
        speechService.stopListening()
        speechTask?.cancel()
        speechTask = nil

        let transcript = liveTranscript
        liveTranscript = ""

        guard !transcript.isEmpty else { return }

        // Now, process the final transcript
        Task {
            // Add the user's transcribed message to the chat
            let userMessage = TutorMessage(id: UUID(), sender: .user, type: .text, text: transcript, question: nil, tutorial: nil, stepByStepGuide: nil)
            self.messages.append(userMessage)

            // Use the on-device AI for intent detection
            await classifyIntent(for: transcript)
        }
    }

    private func classifyIntent(for text: String) async {
        guard let onDeviceAIService = onDeviceAIService else {
            // Fallback if the on-device model isn't available
            sendMessage(text)
            return
        }

        let intentPrompt = "Classify the intent of this text: '\(text)'. Respond with 'generate' or 'question'."
        do {
            let intent = try await onDeviceAIService.generate(prompt: intentPrompt)

            if intent.lowercased().contains("generate") {
                generateCourseContent(from: text)
            } else {
                postTurn(text: text, selectedOptionId: nil)
            }
        } catch {
            // Fallback on error
            postTurn(text: text, selectedOptionId: nil)
        }
    }

    // MARK: - Private Logic

    private func postTurn(text: String, selectedOptionId: String?) { /* ... */ }
    private func generateCourseContent(from goal: String) { /* ... */ }
    private func handle(generatedContent: AIGeneratedContent) { /* ... */ }
}
