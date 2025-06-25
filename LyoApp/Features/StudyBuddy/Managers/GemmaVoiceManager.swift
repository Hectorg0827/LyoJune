import Foundation
import AVFoundation
import Speech
import Combine

@MainActor
class GemmaVoiceManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isListening = false
    @Published var isProcessing = false
    @Published var currentTranscript = ""
    @Published var lastError: String?
    @Published var voiceEnabled = true
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    // MARK: - Private Properties
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    
    // API Configuration
    private let gemmaAPIEndpoint = "https://api.gemini.google.com/v1/chat/completions" // Placeholder - replace with actual Gemma endpoint
    private let apiKey = "YOUR_GEMMA_API_KEY" // Should be loaded from secure storage
    
    // Session Management
    private var session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    enum ConnectionStatus {
        case connected
        case connecting
        case disconnected
        case error(String)
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupSpeechRecognizer()
        setupAudioSession()
    }
    
    // MARK: - Speech Recognition Setup
    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        speechRecognizer?.delegate = self
        
        // Request speech recognition permission
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