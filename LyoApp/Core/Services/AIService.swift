import Foundation
import AVFoundation
import Speech
import Combine
import SwiftUI

// Models are now defined in their respective files under Core/Models
// and are available project-wide. No direct imports are needed as
// they are part of the same application target.

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
    private let authService = EnhancedAuthService.shared
    private let apiClient = NetworkManager.shared
    
    private init() {
        setupSpeechRecognition()
    }
    
    deinit {
        cancellables.removeAll()
        // Note: stopListening() removed due to main actor isolation
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
        // Call the real AI backend API
        let userId = authService.currentUser?.id.uuidString // EnhancedAuthService has a currentUser property
        
        let request = AIRequest(
            message: text,
            context: context,
            userId: userId
        )
        
        do {
            // Getting the raw response and manually extracting the data
            let response: AIResponse = try await apiClient.post(
                endpoint: Constants.API.Endpoints.ai,
                body: request
            )
            
            // Extract message from response
            return response.message
        } catch {
            print("AI API call failed: \(error)")
            // Fall back to a simple response rather than mock data
            throw AIError.networkError
        }
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
            context += " Their learning progress: \(progress.totalCoursesCompleted) courses completed, \(progress.streakDays) day streak."
        }
        
        context += " Provide helpful, encouraging, and educational responses."
        
        return context
    }
}
