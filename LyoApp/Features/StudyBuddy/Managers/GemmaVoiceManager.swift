import Foundation
import AVFoundation
import Speech
import Combine
import SwiftUI

@MainActor
class GemmaVoiceManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isListening = false
    @Published var isProcessing = false
    @Published var currentTranscript = ""
    @Published var lastError: String?
    @Published var voiceEnabled = true
    @Published var connectionStatus: ConnectionStatus = .connected
    @Published var conversationHistory: [ConversationMessage] = []
    @Published var currentContext: LearningContext?
    
    // MARK: - Private Properties
    private let aiService = EnhancedAIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Secure API configuration
    private var gemmaAPIEndpoint: String {
        return ConfigurationManager.shared.string(for: .gemmaApiEndpoint) ?? "https://api.google.com/gemma/v1/generate"
    }
    
    private var apiKey: String {
        return ConfigurationManager.shared.gemmaApiKey ?? "YOUR_GEMMA_API_KEY"
    }
    
    enum ConnectionStatus {
        case connected
        case connecting
        case disconnected
        case error(String)
        
        var description: String {
            switch self {
            case .connected: return "Connected"
            case .connecting: return "Connecting..."
            case .disconnected: return "Disconnected"
            case .error(let message): return "Error: \(message)"
            }
        }
    }
    
    // MARK: - Singleton
    static let shared = GemmaVoiceManager()
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupBindings()
        connectionStatus = .connected
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Setup Methods
    private func setupBindings() {
        // Bind to AI service properties
        aiService.$isListening
            .assign(to: \.isListening, on: self)
            .store(in: &cancellables)
        
        aiService.$isProcessing
            .assign(to: \.isProcessing, on: self)
            .store(in: &cancellables)
        
        aiService.$transcript
            .assign(to: \.currentTranscript, on: self)
            .store(in: &cancellables)
        
        aiService.$errorMessage
            .assign(to: \.lastError, on: self)
            .store(in: &cancellables)
        
        aiService.$conversationHistory
            .assign(to: \.conversationHistory, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Voice Control Methods
    func startListening() async {
        guard voiceEnabled else {
            lastError = "Voice recognition is disabled"
            return
        }
        
        do {
            try await aiService.startListening()
            connectionStatus = .connected
        } catch {
            lastError = error.localizedDescription
            connectionStatus = .error(error.localizedDescription)
        }
    }
    
    func stopListening() {
        aiService.stopListening()
    }
    
    func toggleListening() async {
        if isListening {
            stopListening()
        } else {
            await startListening()
        }
    }
    
    // MARK: - Text Interaction
    func sendTextMessage(_ text: String) async {
        await aiService.sendTextMessage(text)
        
        // Track interaction analytics
        await AnalyticsAPIService.shared.trackEvent(
            "voice_assistant_text_interaction",
            parameters: [
                "message_length": text.count,
                "has_context": currentContext != nil,
                "course_id": currentContext?.courseId ?? "",
                "lesson_id": currentContext?.lessonId ?? ""
            ]
        )
    }
    
    // MARK: - Context Management
    func updateLearningContext(
        courseId: String? = nil,
        lessonId: String? = nil,
        currentTopic: String? = nil,
        userProgress: UserProgress? = nil,
        difficulty: String? = nil
    ) {
        currentContext = LearningContext(
            courseId: courseId,
            lessonId: lessonId,
            currentTopic: currentTopic,
            userProgress: userProgress,
            difficulty: difficulty
        )
        
        // Update AI service context
        aiService.updateContext(
            courseId: courseId,
            lessonId: lessonId,
            userProgress: userProgress
        )
    }
    
    func clearContext() {
        currentContext = nil
        clearConversation()
    }
    
    // MARK: - Conversation Management
    func clearConversation() {
        aiService.clearConversation()
    }
    
    func getLastAIResponse() -> String? {
        return conversationHistory.last(where: { $0.role == .assistant })?.content
    }
    
    // MARK: - Learning Assistant Features
    func explainConcept(_ concept: String) async {
        let prompt = generateExplanationPrompt(for: concept)
        await sendTextMessage(prompt)
    }
    
    func askForHelp(with topic: String) async {
        let prompt = generateHelpPrompt(for: topic)
        await sendTextMessage(prompt)
    }
    
    func requestQuiz(on topic: String? = nil) async {
        let prompt = generateQuizPrompt(for: topic)
        await sendTextMessage(prompt)
    }
    
    func getStudyTips() async {
        let prompt = generateStudyTipsPrompt()
        await sendTextMessage(prompt)
    }
    
    func checkProgress() async {
        let prompt = generateProgressPrompt()
        await sendTextMessage(prompt)
    }
    
    // MARK: - Voice Settings
    func toggleVoiceEnabled() {
        voiceEnabled.toggle()
        if !voiceEnabled && isListening {
            stopListening()
        }
    }
    
    func setVoiceEnabled(_ enabled: Bool) {
        voiceEnabled = enabled
        if !enabled && isListening {
            stopListening()
        }
    }
    
    // MARK: - Connection Management
    func reconnect() async {
        connectionStatus = .connecting
        
        // Simulate reconnection delay
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        connectionStatus = .connected
    }
    
    func disconnect() {
        stopListening()
        connectionStatus = .disconnected
    }
    
    // MARK: - Prompt Generation
    private func generateExplanationPrompt(for concept: String) -> String {
        var prompt = "Please explain the concept of \(concept)"
        
        if let context = currentContext {
            if let topic = context.currentTopic {
                prompt += " in the context of \(topic)"
            }
            if let difficulty = context.difficulty {
                prompt += " at a \(difficulty) level"
            }
        }
        
        prompt += ". Use simple language and provide examples if possible."
        return prompt
    }
    
    private func generateHelpPrompt(for topic: String) -> String {
        var prompt = "I need help with \(topic)"
        
        if let context = currentContext {
            if let courseId = context.courseId {
                prompt += " in my current course"
            }
            if let lessonId = context.lessonId {
                prompt += " for this lesson"
            }
        }
        
        prompt += ". Can you break it down step by step?"
        return prompt
    }
    
    private func generateQuizPrompt(for topic: String?) -> String {
        let subject = topic ?? currentContext?.currentTopic ?? "the current topic"
        return "Can you create a quick quiz to test my understanding of \(subject)? Please ask me one question at a time."
    }
    
    private func generateStudyTipsPrompt() -> String {
        var prompt = "Can you give me some study tips"
        
        if let context = currentContext {
            if let topic = context.currentTopic {
                prompt += " for learning \(topic)"
            }
        }
        
        prompt += "? Focus on effective techniques I can use right now."
        return prompt
    }
    
    private func generateProgressPrompt() -> String {
        var prompt = "How am I doing with my learning progress?"
        
        if let context = currentContext, let progress = context.userProgress {
            prompt += " I've completed \(progress.coursesCompleted) courses and have a \(progress.currentStreak) day streak."
        }
        
        return prompt
    }
    
    // MARK: - Analytics Tracking
    func trackInteraction(type: String, details: [String: Any] = [:]) async {
        var parameters = details
        parameters["interaction_type"] = type
        parameters["voice_enabled"] = voiceEnabled
        parameters["has_context"] = currentContext != nil
        
        if let context = currentContext {
            parameters["course_id"] = context.courseId ?? ""
            parameters["lesson_id"] = context.lessonId ?? ""
            parameters["current_topic"] = context.currentTopic ?? ""
        }
        
        await AnalyticsAPIService.shared.trackEvent("voice_assistant_interaction", parameters: parameters)
    }
}

// MARK: - Public Interface Extensions
extension GemmaVoiceManager {
    
    var isConnected: Bool {
        if case .connected = connectionStatus {
            return true
        }
        return false
    }
    
    var hasError: Bool {
        if case .error = connectionStatus {
            return true
        }
        return false
    }
    
    var canListen: Bool {
        return voiceEnabled && isConnected && !isProcessing
    }
    
    var statusColor: Color {
        switch connectionStatus {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .disconnected:
            return .gray
        case .error:
            return .red
        }
    }
}

// MARK: - Convenience Methods
extension GemmaVoiceManager {
    
    func quickHelp() async {
        await sendTextMessage("I need help with what I'm currently learning. Can you assist me?")
    }
    
    func explainLastConcept() async {
        if let topic = currentContext?.currentTopic {
            await explainConcept(topic)
        } else {
            await sendTextMessage("Can you explain the last concept we were discussing?")
        }
    }
    
    func motivationalMessage() async {
        await sendTextMessage("I could use some motivation with my learning. Can you encourage me?")
    }
    
    func summarizeSession() async {
        await sendTextMessage("Can you summarize what we've learned in this session?")
    }
    
    private func checkSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self?.voiceEnabled = true
                case .denied, .restricted, .notDetermined:
                    self?.voiceEnabled = false
                    self?.lastError = "Speech recognition not authorized"
                @unknown default:
                    self?.voiceEnabled = false
                    self?.lastError = "Unknown speech recognition status"
                }
            }
        }
    }
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            lastError = "Audio session setup failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Voice Recording Control
    func startListening() {
        guard voiceEnabled, !isListening else { return }
        
        // Cancel any ongoing recognition
        stopListening()
        
        do {
            // Setup recognition request
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                lastError = "Unable to create recognition request"
                return
            }
            
            recognitionRequest.shouldReportPartialResults = true
            
            // Setup audio engine
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            // Start recognition task
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    DispatchQueue.main.async {
                        self.currentTranscript = result.bestTranscription.formattedString
                        
                        // If result is final, process with Gemma AI
                        if result.isFinal {
                            self.processVoiceInput(result.bestTranscription.formattedString)
                        }
                    }
                }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.lastError = "Recognition error: \(error.localizedDescription)"
                        self.stopListening()
                    }
                }
            }
            
            isListening = true
            lastError = nil
            
        } catch {
            lastError = "Failed to start listening: \(error.localizedDescription)"
        }
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
    
    // MARK: - Gemma AI Integration
    func processVoiceInput(_ transcript: String) {
        Task {
            await processWithGemmaAI(transcript)
        }
    }
    
    func processTextInput(_ text: String) async -> GemmaAPIResponse? {
        return await processWithGemmaAI(text)
    }
    
    private func processWithGemmaAI(_ input: String) async -> GemmaAPIResponse? {
        isProcessing = true
        connectionStatus = .connecting
        
        do {
            let request = createGemmaRequest(for: input)
            let response = try await sendGemmaRequest(request)
            
            connectionStatus = .connected
            isProcessing = false
            
            return response
            
        } catch {
            lastError = "AI processing failed: \(error.localizedDescription)"
            connectionStatus = .error(error.localizedDescription)
            isProcessing = false
            return nil
        }
    }
    
    private func createGemmaRequest(for input: String) -> GemmaAPIRequest {
        let context = GemmaAPIRequest.ConversationContext(
            previousMessages: [], // Should be populated from conversation session
            currentScreen: getCurrentScreenContext(),
            userProfile: getUserContext()
        )
        
        return GemmaAPIRequest(
            prompt: input,
            context: context,
            settings: .default
        )
    }
    
    private func sendGemmaRequest(_ request: GemmaAPIRequest) async throws -> GemmaAPIResponse {
        // Create URL request
        guard let url = URL(string: gemmaAPIEndpoint) else {
            throw GemmaError.invalidEndpoint
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Encode request body
        let requestData = try JSONEncoder().encode(request)
        urlRequest.httpBody = requestData
        
        // Send request
        let (data, response) = try await session.data(for: urlRequest)
        
        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GemmaError.invalidResponse
        }
        
        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            throw GemmaError.httpError(httpResponse.statusCode)
        }
        
        // Decode response
        let gemmaResponse = try JSONDecoder().decode(GemmaAPIResponse.self, from: data)
        return gemmaResponse
    }
    
    // MARK: - Context Helpers
    private func getCurrentScreenContext() -> String {
        // This should be updated by the main app when screens change
        return "learning_home" // Default context
    }
    
    private func getUserContext() -> GemmaAPIRequest.UserContext {
        return GemmaAPIRequest.UserContext(
            learningGoals: ["Swift Programming", "iOS Development"],
            currentCourse: "SwiftUI Fundamentals",
            difficultyLevel: "intermediate",
            preferredLanguage: "en"
        )
    }
    
    // MARK: - Wake Word Detection
    func startWakeWordDetection() {
        // Implement continuous listening for "Hey Lyo" or similar wake word
        // This would require a lightweight local speech recognition or
        // a dedicated wake word detection library
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.checkForWakeWord()
            }
        }
    }
    
    private func checkForWakeWord() {
        // Placeholder for wake word detection logic
        // In a real implementation, this would use a specialized wake word detection service
    }
    
    // MARK: - Mock Response (for development)
    func getMockResponse(for input: String) -> GemmaAPIResponse {
        let responses = [
            "That's a great question! Let me help you understand this concept better.",
            "I can see you're working hard on this. Would you like me to break this down into smaller steps?",
            "Excellent progress! You're really getting the hang of this.",
            "Don't worry if this seems challenging - that's how we learn and grow!",
            "Let me suggest a different approach that might make this clearer.",
            "I notice you might be struggling with this concept. Should we review the basics first?"
        ]
        
        return GemmaAPIResponse(
            response: responses.randomElement() ?? "I'm here to help!",
            confidence: 0.85,
            suggestions: ["Try a practice quiz", "Review the lesson", "Ask for clarification"],
            emotion: .encouraging,
            actions: nil
        )
    }

// MARK: - SFSpeechRecognizerDelegate
extension GemmaVoiceManager: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        DispatchQueue.main.async {
            self.voiceEnabled = available
        }
    }
}

// MARK: - Error Types
enum GemmaError: LocalizedError {
    case invalidEndpoint
    case invalidResponse
    case httpError(Int)
    case encodingError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidEndpoint:
            return "Invalid API endpoint"
        case .invalidResponse:
            return "Invalid API response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .encodingError:
            return "Request encoding failed"
        case .decodingError:
            return "Response decoding failed"
        }
    }
}