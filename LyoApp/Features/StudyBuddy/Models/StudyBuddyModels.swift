import Foundation
import AVFoundation

// MARK: - AI Message Models

struct AIMessage: Identifiable, Codable {
    var id = UUID()
    let content: String
    let sender: MessageSender
    let timestamp: Date
    let messageType: MessageType
    let confidence: Double?
    let audioURL: URL?
    
    enum MessageSender: String, Codable {
        case user = "user"
        case ai = "ai"
        case system = "system"
    }
    
    enum MessageType: String, Codable {
        case text = "text"
        case voice = "voice"
        case suggestion = "suggestion"
        case emotion = "emotion"
        case error = "error"
    }
}

// MARK: - Voice Recognition Models

struct VoiceRecognitionResult {
    let transcript: String
    let confidence: Double
    let isFinal: Bool
    let duration: TimeInterval
}

struct GemmaAPIRequest: Codable {
    let prompt: String
    let context: ConversationContext?
    let settings: AISettings
    
    struct ConversationContext: Codable {
        let previousMessages: [AIMessage]
        let currentScreen: String
        let userProfile: UserContext?
    }
    
    struct UserContext: Codable {
        let learningGoals: [String]
        let currentCourse: String?
        let difficultyLevel: String
        let preferredLanguage: String
    }
    
    struct AISettings: Codable {
        let temperature: Double
        let maxTokens: Int
        let topP: Double
        let presencePenalty: Double
        
        static let `default` = AISettings(
            temperature: 0.7,
            maxTokens: 500,
            topP: 0.9,
            presencePenalty: 0.1
        )
    }
}

struct GemmaAPIResponse: Codable {
    let response: String
    let confidence: Double
    let suggestions: [String]?
    let emotion: EmotionState?
    let actions: [AIAction]?
    
    enum EmotionState: String, Codable {
        case neutral = "neutral"
        case encouraging = "encouraging"
        case explaining = "explaining"
        case questioning = "questioning"
        case celebrating = "celebrating"
        case concerned = "concerned"
    }
    
    struct AIAction: Codable {
        let type: ActionType
        let data: [String: String]
        
        enum ActionType: String, Codable {
            case navigate = "navigate"
            case highlight = "highlight"
            case suggest = "suggest"
            case quiz = "quiz"
            case reminder = "reminder"
        }
    }
}

// MARK: - Avatar Animation States

enum AvatarAnimationState: Equatable {
    case idle
    case listening
    case speaking
    case thinking
    case celebrating
    case concerned
    case blinking
    case mouthMoving(intensity: Double)
    
    var animationDuration: TimeInterval {
        switch self {
        case .idle: return 2.0
        case .listening: return 0.5
        case .speaking: return 0.3
        case .thinking: return 1.5
        case .celebrating: return 3.0
        case .concerned: return 2.0
        case .blinking: return 0.2
        case .mouthMoving: return 0.1
        }
    }
}

// MARK: - Study Buddy Configuration

struct StudyBuddyConfig {
    let isEnabled: Bool
    let voiceEnabled: Bool
    let proactiveAssistance: Bool
    let wakeWordEnabled: Bool
    let autoMinimize: Bool
    let responsiveness: ResponsivenessLevel
    let personality: PersonalityType
    
    enum ResponsivenessLevel: String, CaseIterable {
        case minimal = "minimal"
        case balanced = "balanced"
        case proactive = "proactive"
        case intensive = "intensive"
    }
    
    enum PersonalityType: String, CaseIterable {
        case friendly = "friendly"
        case professional = "professional"
        case encouraging = "encouraging"
        case casual = "casual"
    }
    
    static let `default` = StudyBuddyConfig(
        isEnabled: true,
        voiceEnabled: true,
        proactiveAssistance: true,
        wakeWordEnabled: true,
        autoMinimize: true,
        responsiveness: .balanced,
        personality: .encouraging
    )
}

// MARK: - Conversation Session

class ConversationSession: ObservableObject {
    @Published var messages: [AIMessage] = []
    @Published var isActive: Bool = false
    @Published var currentContext: String = ""
    @Published var sessionDuration: TimeInterval = 0
    
    private var startTime: Date?
    
    func startSession(context: String) {
        isActive = true
        currentContext = context
        startTime = Date()
        addSystemMessage("Study Buddy is here to help! How can I assist you with your learning today?")
    }
    
    func endSession() {
        isActive = false
        if let start = startTime {
            sessionDuration = Date().timeIntervalSince(start)
        }
        addSystemMessage("Study session ended. Great work today!")
    }
    
    func addMessage(_ message: AIMessage) {
        messages.append(message)
    }
    
    func addUserMessage(_ content: String, type: AIMessage.MessageType = .text) {
        let message = AIMessage(
            content: content,
            sender: .user,
            timestamp: Date(),
            messageType: type,
            confidence: nil,
            audioURL: nil
        )
        addMessage(message)
    }
    
    func addAIMessage(_ content: String, emotion: GemmaAPIResponse.EmotionState = .neutral) {
        let message = AIMessage(
            content: content,
            sender: .ai,
            timestamp: Date(),
            messageType: .text,
            confidence: 0.95,
            audioURL: nil
        )
        addMessage(message)
    }
    
    private func addSystemMessage(_ content: String) {
        let message = AIMessage(
            content: content,
            sender: .system,
            timestamp: Date(),
            messageType: .text,
            confidence: nil,
            audioURL: nil
        )
        addMessage(message)
    }
}

