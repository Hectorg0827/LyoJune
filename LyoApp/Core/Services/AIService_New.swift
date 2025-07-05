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
    private let authService = EnhancedAuthService.shared
    private let apiClient = NetworkManager.shared
    
    private init() {
        setupSpeechRecognition()
    }
    
    deinit {
        cancellables.removeAll()
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
        // Check for permission
        let hasPermission = await requestSpeechPermission()
        guard hasPermission else {
            throw AIError.speechPermissionDenied
        }
        
        // Check if speech recognizer is available
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw AIError.speechRecognitionUnavailable
        }
        
        // Set up audio session
        try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: .duckOthers)
        try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            throw AIError.speechRecognitionSetupFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                self.transcript = result.bestTranscription.formattedString
            }
            
            if error != nil {
                self.stopListening()
            }
        }
        
        // Set up audio engine
        let audioSession = AVAudioSession.sharedInstance()
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
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
        recognitionTask = nil
        recognitionRequest = nil
        
        isListening = false
    }
    
    // MARK: - AI Processing
    func processAIRequest(_ text: String, courseId: String? = nil, lessonId: String? = nil) async {
        guard !text.isEmpty else { return }
        
        isProcessing = true
        
        // Add user message to history
        let userMessage = ConversationMessage(
            role: .user,
            content: text
        )
        conversationHistory.append(userMessage)
        
        do {
            // Call AI API and get response
            let response = try await callAIAPI(with: text, context: conversationHistory)
            
            // Add AI message to history
            let aiMessage = ConversationMessage(
                role: .assistant,
                content: response
            )
            conversationHistory.append(aiMessage)
            aiResponse = response
        } catch {
            errorMessage = "Sorry, I couldn't process your request: \(error.localizedDescription)"
        }
        
        isProcessing = false
    }
    
    func clearConversation() {
        conversationHistory.removeAll()
        aiResponse = ""
        transcript = ""
    }
    
    func addSystemContext(courseId: String? = nil, lessonId: String? = nil, userProgress: UserProgress? = nil) {
        let contextPrompt = createContextPrompt(courseId: courseId, lessonId: lessonId, userProgress: userProgress)
        
        let contextMessage = ConversationMessage(
            role: .system,
            content: contextPrompt
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
            let response: AIResponse = try await apiClient.post(
                endpoint: Constants.API.Endpoints.ai,
                body: request
            )
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
            context += " Their overall progress is \(Int(progress.overallProgress * 100))%."
            if let strengths = progress.strengths, !strengths.isEmpty {
                context += " Their strengths include: \(strengths.joined(separator: ", "))."
            }
            if let weaknesses = progress.weaknesses, !weaknesses.isEmpty {
                context += " Areas they need help with: \(weaknesses.joined(separator: ", "))."
            }
        }
        
        context += " Provide concise, helpful responses that maintain a positive, encouraging tone. Avoid long explanations unless asked for details."
        
        return context
    }
}

// MARK: - AI Suggestion Models (moved from duplicate ProactiveAIManager)
struct AISuggestion: Identifiable, Codable {
    let id: UUID
    let type: SuggestionType
    let content: String
    let relatedCourse: String?
    let timestamp: Date
    
    enum SuggestionType: String, Codable {
        case review = "review"
        case practice = "practice"
        case exploration = "exploration"
        case reminder = "reminder"
        case motivation = "motivation"
    }
}

struct UserProgress {
    let userId: String
    let overallProgress: Double
    let strengths: [String]?
    let weaknesses: [String]?
    let lastActive: Date
    let completedCourses: Int
    let activeCourses: Int
}
