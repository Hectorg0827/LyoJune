import Foundation
import AVFoundation
import Speech
import Combine

// MARK: - AI Service
@MainActor
class AIService: ObservableObject {
    static let shared = AIService()
    
    @Published var isListening = false
    @Published var isProcessing = false
    @Published var transcript = ""
    @Published var aiResponse = ""
    @Published var errorMessage: String?
    @Published var conversationHistory: [ConversationMessage] = []
    
    private let speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupSpeechRecognition()
    }
    
    deinit {
        cancellables.removeAll()
        stopListening()
    }
    
    // MARK: - Speech Recognition
    func requestSpeechPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
    }
    
    func startListening() async throws {
        guard await requestSpeechPermission() else {
            throw AIError.speechPermissionDenied
        }
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw AIError.speechRecognitionUnavailable
        }
        
        stopListening()
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            throw AIError.speechRecognitionSetupFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let result = result {
                    self.transcript = result.bestTranscription.formattedString
                    
                    if result.isFinal {
                        await self.processTranscript(self.transcript)
                    }
                }
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.stopListening()
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        isListening = true
    }
    
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
    }
    
    // MARK: - AI Processing
    func processTranscript(_ text: String) async {
        guard !text.isEmpty else { return }
        
        isProcessing = true
        errorMessage = nil
        
        let userMessage = ConversationMessage(
            id: UUID(),
            role: .user,
            content: text,
            timestamp: Date()
        )
        
        conversationHistory.append(userMessage)
        
        do {
            // In a real app, this would call your AI backend
            let response = try await callAIAPI(with: text, context: conversationHistory)
            
            let aiMessage = ConversationMessage(
                id: UUID(),
                role: .assistant,
                content: response,
                timestamp: Date()
            )
            
            conversationHistory.append(aiMessage)
            aiResponse = response
            
            // Speak the response
            await speakResponse(response)
            
            // Track analytics
            await AnalyticsAPIService.shared.trackEvent(
                "ai_interaction",
                parameters: [
                    "user_input_length": text.count,
                    "ai_response_length": response.count,
                    "interaction_type": "voice"
                ]
            )
            
        } catch {
            errorMessage = "Failed to process request: \(error.localizedDescription)"
        }
        
        isProcessing = false
    }
    
    func sendTextMessage(_ text: String) async {
        await processTranscript(text)
    }
    
    func clearConversation() {
        conversationHistory.removeAll()
        transcript = ""
        aiResponse = ""
        errorMessage = nil
    }
    
    // MARK: - Text-to-Speech
    func speakResponse(_ text: String) async {
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: text)
        
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.8
        
        // Use a more natural voice if available
        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }
        
        synthesizer.speak(utterance)
    }
    
    // MARK: - Context Awareness
    func updateContext(courseId: String?, lessonId: String?, userProgress: UserProgress?) {
        // Store context for AI to provide more relevant responses
        let contextMessage = ConversationMessage(
            id: UUID(),
            role: .system,
            content: createContextPrompt(courseId: courseId, lessonId: lessonId, userProgress: userProgress),
            timestamp: Date()
        )
        
        // Insert at beginning to maintain context
        conversationHistory.insert(contextMessage, at: 0)
        
        // Keep only recent history to avoid token limits
        if conversationHistory.count > 20 {
            conversationHistory = Array(conversationHistory.suffix(20))
        }
    }
    
    // MARK: - Private Methods
    private func setupSpeechRecognition() {
        guard speechRecognizer != nil else {
            errorMessage = "Speech recognition not available on this device"
            return
        }
    }
    
    private func callAIAPI(with text: String, context: [ConversationMessage]) async throws -> String {
        // In a real implementation, this would call your AI backend
        // For now, we'll simulate an AI response
        
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
        
        // Generate contextual response based on input
        return generateMockResponse(for: text, context: context)
    }
    
    private func generateMockResponse(for input: String, context: [ConversationMessage]) -> String {
        let lowercaseInput = input.lowercased()
        
        // Educational responses
        if lowercaseInput.contains("explain") || lowercaseInput.contains("what is") {
            return "I'd be happy to explain that concept! Let me break it down for you in simple terms with some examples."
        }
        
        if lowercaseInput.contains("help") || lowercaseInput.contains("stuck") {
            return "I understand you need help. Let me guide you through this step by step. What specific part would you like me to clarify?"
        }
        
        if lowercaseInput.contains("progress") || lowercaseInput.contains("how am i doing") {
            return "You're making great progress! Based on your recent activity, you're on track to complete your learning goals. Keep up the excellent work!"
        }
        
        if lowercaseInput.contains("motivate") || lowercaseInput.contains("encourage") {
            return "You're doing amazing! Remember, every expert was once a beginner. Your consistency and effort are building real skills that will serve you well."
        }
        
        if lowercaseInput.contains("quiz") || lowercaseInput.contains("test") {
            return "Let's test your knowledge! I can create a quick quiz based on what you've been learning. Are you ready for a challenge?"
        }
        
        // General responses
        return "That's a great question! I'm here to help you learn and grow. Could you tell me more about what you'd like to explore?"
    }
    
    private func createContextPrompt(courseId: String?, lessonId: String?, userProgress: UserProgress?) -> String {
        var context = "You are Lyo, an AI learning assistant. You help students learn effectively through personalized guidance."
        
        if let courseId = courseId {
            context += " The user is currently in course: \(courseId)."
        }
        
        if let lessonId = lessonId {
            context += " They are working on lesson: \(lessonId)."
        }
        
        if let progress = userProgress {
            context += " Their learning progress: \(progress.coursesCompleted) courses completed, \(progress.currentStreak) day streak."
        }
        
        context += " Provide helpful, encouraging, and educational responses."
        
        return context
    }
}

// MARK: - Models
struct ConversationMessage: Codable, Identifiable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    
    enum MessageRole: String, Codable {
        case user
        case assistant
        case system
    }
}

enum AIError: Error, LocalizedError {
    case speechPermissionDenied
    case speechRecognitionUnavailable
    case speechRecognitionSetupFailed
    case networkError
    case processingError
    
    var errorDescription: String? {
        switch self {
        case .speechPermissionDenied:
            return "Speech recognition permission is required"
        case .speechRecognitionUnavailable:
            return "Speech recognition is not available"
        case .speechRecognitionSetupFailed:
            return "Failed to setup speech recognition"
        case .networkError:
            return "Network connection required"
        case .processingError:
            return "Failed to process request"
        }
    }
}

// MARK: - Proactive AI Manager
@MainActor
class ProactiveAIManager: ObservableObject {
    static let shared = ProactiveAIManager()
    
    @Published var suggestions: [AISuggestion] = []
    @Published var isActive = false
    
    private var cancellables = Set<AnyCancellable>()
    private let aiService = AIService.shared
    
    private init() {
        setupProactiveMonitoring()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    func startProactiveMode() {
        isActive = true
        generateInitialSuggestions()
    }
    
    func stopProactiveMode() {
        isActive = false
        suggestions.removeAll()
    }
    
    func updateContext(userActivity: UserActivity) {
        guard isActive else { return }
        
        Task {
            await generateContextualSuggestions(for: userActivity)
        }
    }
    
    private func setupProactiveMonitoring() {
        // Monitor for idle time and learning patterns
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.checkForSuggestions()
                }
            }
            .store(in: &cancellables)
    }
    
    private func generateInitialSuggestions() {
        suggestions = [
            AISuggestion(
                id: UUID(),
                type: .tip,
                title: "Start Learning",
                content: "Ready to dive into your learning journey? I can help you pick up where you left off!",
                action: .startLearning
            ),
            AISuggestion(
                id: UUID(),
                type: .encouragement,
                title: "Daily Goal",
                content: "You're just 15 minutes away from maintaining your learning streak!",
                action: .continueStreak
            )
        ]
    }
    
    private func generateContextualSuggestions(for activity: UserActivity) async {
        // Generate suggestions based on user's current activity
        switch activity.type {
        case .courseViewing:
            if activity.duration > 300 { // 5 minutes
                addSuggestion(AISuggestion(
                    id: UUID(),
                    type: .tip,
                    title: "Take a Break",
                    content: "You've been learning for a while. How about a quick review quiz?",
                    action: .takeQuiz
                ))
            }
        case .struggling:
            addSuggestion(AISuggestion(
                id: UUID(),
                type: .help,
                title: "Need Help?",
                content: "I noticed you might be stuck. Would you like me to explain this concept differently?",
                action: .getHelp
            ))
        case .completed:
            addSuggestion(AISuggestion(
                id: UUID(),
                type: .celebration,
                title: "Great Job!",
                content: "Congratulations on completing that lesson! Ready for the next challenge?",
                action: .nextLesson
            ))
        }
    }
    
    private func checkForSuggestions() async {
        // Check learning patterns and generate suggestions
        if suggestions.isEmpty && isActive {
            generateInitialSuggestions()
        }
    }
    
    private func addSuggestion(_ suggestion: AISuggestion) {
        suggestions.append(suggestion)
        
        // Keep only recent suggestions
        if suggestions.count > 3 {
            suggestions.removeFirst()
        }
    }
}

// MARK: - AI Suggestion Models
struct AISuggestion: Identifiable, Codable {
    let id: UUID
    let type: SuggestionType
    let title: String
    let content: String
    let action: SuggestionAction
    let timestamp: Date
    
    init(id: UUID, type: SuggestionType, title: String, content: String, action: SuggestionAction) {
        self.id = id
        self.type = type
        self.title = title
        self.content = content
        self.action = action
        self.timestamp = Date()
    }
}

enum SuggestionType: String, Codable {
    case tip
    case encouragement
    case help
    case celebration
    case reminder
}

enum SuggestionAction: String, Codable {
    case startLearning
    case continueStreak
    case takeQuiz
    case getHelp
    case nextLesson
    case reviewProgress
}

struct UserActivity: Codable {
    let type: ActivityType
    let duration: TimeInterval
    let context: [String: String]
    let timestamp: Date
    
    enum ActivityType: String, Codable {
        case courseViewing
        case struggling
        case completed
        case idle
    }
}
