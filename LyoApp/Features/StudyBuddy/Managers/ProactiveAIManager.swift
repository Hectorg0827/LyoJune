import Foundation
import Combine
import SwiftUI

@MainActor
class ProactiveAIManager: ObservableObject {
    @Published var activeTriggers: [ProactiveTrigger] = []
    @Published var shouldShowProactiveMessage = false
    @Published var currentProactiveMessage: String?
    @Published var proactiveMessageEmotion: EmotionState = .neutral
    @Published var suggestions: [AISuggestion] = []
    @Published var isActive = false
    
    private var cancellables = Set<AnyCancellable>()
    private var idleTimer: Timer?
    private var screenFocusTimer: Timer?
    private var performanceMonitor = PerformanceMonitor()
    
    // User activity tracking
    @Published var userIdleTime: TimeInterval = 0
    @Published var currentScreen: String = "home"
    @Published var screenFocusTime: TimeInterval = 0
    @Published var lastUserInteraction: Date = Date()
    @Published var errorCount: Int = 0
    @Published var currentPerformanceScore: Double = 1.0
    @Published var learningContext: LearningContext?
    @Published var userEngagement: EngagementLevel = .moderate
    
    private let config: StudyBuddyConfig
    private let aiService = EnhancedAIService.shared
    private let gamificationService = GamificationAPIService.shared
    private let analyticsService = AnalyticsAPIService.shared
    // Removed circular reference to ProactiveAIManager.shared
    
    enum EmotionState: String, CaseIterable {
        case happy, encouraging, neutral, concerned, excited, celebrating
        
        var emoji: String {
            switch self {
            case .happy: return "😊"
            case .encouraging: return "💪"
            case .neutral: return "🤖"
            case .concerned: return "🤔"
            case .excited: return "🎉"
            case .celebrating: return "🥳"
            }
        }
        
        var toGemmaEmotion: GemmaAPIResponse.EmotionState {
            switch self {
            case .happy: return .encouraging
            case .encouraging: return .encouraging
            case .neutral: return .neutral
            case .concerned: return .concerned
            case .excited: return .celebrating
            case .celebrating: return .celebrating
            }
        }
    }
    
    enum EngagementLevel: String, CaseIterable {
        case low, moderate, high, struggling
        
        var description: String {
            switch self {
            case .low: return "Low engagement"
            case .moderate: return "Moderate engagement"
            case .high: return "High engagement"
            case .struggling: return "Struggling"
            }
        }
    }
    
    struct LearningContext {
        let courseId: String?
        let lessonId: String?
        let currentTopic: String?
        let difficulty: String?
        let timeSpent: TimeInterval
        let correctAnswers: Int
        let totalAttempts: Int
        
        var accuracy: Double {
            guard totalAttempts > 0 else { return 0 }
            return Double(correctAnswers) / Double(totalAttempts)
        }
    }
    
    public init(config: StudyBuddyConfig = .default) {
        self.config = config
        setupProactiveMonitoring()
        bindToProactiveAI()
    }
    
    deinit {
        cancellables.removeAll()
        idleTimer?.invalidate()
        screenFocusTimer?.invalidate()
    }
    
    private func bindToProactiveAI() {
        // Removed dependency on proactiveAI instance
        // Suggestions and isActive are now managed internally
    }
    
    private func setupProactiveMonitoring() {
        guard config.proactiveAssistance else { return }
        
        startIdleTimeMonitoring()
        startPerformanceMonitoring()
        startErrorPatternMonitoring()
        startScreenFocusMonitoring()
        startEngagementMonitoring()
    }
    
    // MARK: - Core Proactive Features
    
    func startProactiveMode() {
        isActive = true
        generateWelcomeMessage()
    }
    
    func stopProactiveMode() {
        isActive = false
        suggestions.removeAll()
        shouldShowProactiveMessage = false
    }
    
    func updateLearningContext(_ context: LearningContext) {
        learningContext = context
        
        // Update proactive AI with new context
        let _ = UserActivity(
            type: determineActivityType(from: context),
            duration: context.timeSpent,
            context: [
                "courseId": context.courseId ?? "",
                "lessonId": context.lessonId ?? "",
                "topic": context.currentTopic ?? "",
                "accuracy": String(context.accuracy)
            ],
            timestamp: Date()
        )
        
        // ProactiveAI context update removed
        
        // Update engagement level
        updateEngagementLevel(based: context)
        
        // Generate contextual suggestions
        generateContextualSuggestions(for: context)
    }
    
    func recordUserInteraction() {
        lastUserInteraction = Date()
        userIdleTime = 0
        
        // Reset idle monitoring
        idleTimer?.invalidate()
        startIdleTimeMonitoring()
    }
    
    func recordError() {
        errorCount += 1
        checkForStrugglePattern()
    }
    
    func recordSuccess() {
        errorCount = max(0, errorCount - 1)
        currentPerformanceScore = min(1.0, currentPerformanceScore + 0.1)
    }
    
    // MARK: - Monitoring Methods
    
    private func startIdleTimeMonitoring() {
        idleTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.userIdleTime += 1
                self?.checkIdleState()
            }
        }
    }
    
    private func startPerformanceMonitoring() {
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updatePerformanceScore()
            }
            .store(in: &cancellables)
    }
    
    private func startErrorPatternMonitoring() {
        $errorCount
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] count in
                if count >= 3 {
                    self?.triggerHelpSuggestion()
                }
            }
            .store(in: &cancellables)
    }
    
    private func startScreenFocusMonitoring() {
        screenFocusTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.screenFocusTime += 1
                self?.checkScreenFocus()
            }
        }
    }
    
    private func startEngagementMonitoring() {
        // Monitor multiple factors for engagement
        Publishers.CombineLatest3($userIdleTime, $errorCount, $currentPerformanceScore)
            .debounce(for: .seconds(5), scheduler: RunLoop.main)
            .sink { [weak self] idleTime, errors, performance in
                self?.updateEngagementLevel(idleTime: idleTime, errors: errors, performance: performance)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - State Checking Methods
    
    private func checkIdleState() {
        guard isActive else { return }
        
        switch userIdleTime {
        case 30...60:
            showGentleEncouragement()
        case 120...180:
            showBreakSuggestion()
        case 300...:
            showReturnPrompt()
        default:
            break
        }
    }
    
    private func checkScreenFocus() {
        guard isActive, screenFocusTime > 900 else { return } // 15 minutes
        
        showBreakReminder()
        screenFocusTime = 0
    }
    
    private func checkForStrugglePattern() {
        guard errorCount >= 3 else { return }
        
        userEngagement = .struggling
        triggerHelpSuggestion()
    }
    
    // MARK: - Suggestion Generation
    
    private func generateWelcomeMessage() {
        let message = "Hi! I'm here to help you learn. Let me know if you need any assistance!"
        showProactiveMessage(message, emotion: .happy)
    }
    
    private func generateContextualSuggestions(for context: LearningContext) {
        var newSuggestions: [AISuggestion] = []
        
        // Performance-based suggestions
        if context.accuracy < 0.5 && context.totalAttempts > 3 {
            newSuggestions.append(AISuggestion(
                id: UUID(),
                type: .help,
                title: "Need Help?",
                content: "I notice you might be struggling with this topic. Would you like me to explain it differently?",
                action: .getHelp
            ))
        }
        
        // Progress-based suggestions
        if context.timeSpent > 1800 { // 30 minutes
            newSuggestions.append(AISuggestion(
                id: UUID(),
                type: .tip,
                title: "Take a Break",
                content: "You've been learning for a while. How about a 5-minute break?",
                action: .takeQuiz
            ))
        }
        
        // Topic-specific suggestions
        if let topic = context.currentTopic {
            newSuggestions.append(AISuggestion(
                id: UUID(),
                type: .tip,
                title: "Practice Quiz",
                content: "Ready to test your understanding of \(topic) with a quick quiz?",
                action: .takeQuiz
            ))
        }
        
        suggestions.append(contentsOf: newSuggestions)
        
        // Keep only recent suggestions
        if suggestions.count > 5 {
            suggestions = Array(suggestions.suffix(5))
        }
    }
    
    private func showGentleEncouragement() {
        let messages = [
            "You're doing great! Keep up the momentum!",
            "Ready to continue your learning journey?",
            "Take your time - learning at your own pace is perfect!"
        ]
        
        showProactiveMessage(messages.randomElement()!, emotion: .encouraging)
    }
    
    private func showBreakSuggestion() {
        let message = "You've been focused for a while. Maybe it's time for a short break?"
        showProactiveMessage(message, emotion: .neutral)
    }
    
    private func showBreakReminder() {
        let message = "Remember to take breaks! Your brain learns better when it's refreshed."
        showProactiveMessage(message, emotion: .concerned)
    }
    
    private func showReturnPrompt() {
        let message = "Welcome back! Ready to continue where you left off?"
        showProactiveMessage(message, emotion: .happy)
    }
    
    private func triggerHelpSuggestion() {
        let suggestion = AISuggestion(
            id: UUID(),
            type: .help,
            title: "Let me help!",
            content: "I noticed you might be having trouble. Would you like me to explain this concept step by step?",
            action: .getHelp
        )
        
        suggestions.insert(suggestion, at: 0)
        showProactiveMessage(suggestion.content, emotion: .concerned)
    }
    
    // MARK: - Helper Methods
    
    private func showProactiveMessage(_ message: String, emotion: EmotionState) {
        currentProactiveMessage = message
        proactiveMessageEmotion = emotion
        shouldShowProactiveMessage = true
        
        // Auto-hide after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.shouldShowProactiveMessage = false
        }
    }
    
    private func updatePerformanceScore() {
        // Calculate performance based on various factors
        var score = currentPerformanceScore
        
        // Adjust based on error rate
        if errorCount > 0 {
            score -= Double(errorCount) * 0.1
        }
        
        // Adjust based on engagement
        switch userEngagement {
        case .high:
            score += 0.05
        case .low, .struggling:
            score -= 0.05
        case .moderate:
            break
        }
        
        currentPerformanceScore = max(0.0, min(1.0, score))
    }
    
    private func updateEngagementLevel(idleTime: TimeInterval, errors: Int, performance: Double) {
        if errors >= 5 || performance < 0.3 {
            userEngagement = .struggling
        } else if idleTime > 180 || performance < 0.6 {
            userEngagement = .low
        } else if performance > 0.8 && idleTime < 30 {
            userEngagement = .high
        } else {
            userEngagement = .moderate
        }
    }
    
    private func updateEngagementLevel(based context: LearningContext) {
        if context.accuracy < 0.3 || context.totalAttempts > 10 {
            userEngagement = .struggling
        } else if context.accuracy > 0.8 && context.timeSpent < 1800 {
            userEngagement = .high
        } else if context.timeSpent > 3600 || context.accuracy < 0.6 {
            userEngagement = .low
        } else {
            userEngagement = .moderate
        }
    }
    
    private func determineActivityType(from context: LearningContext) -> UserActivity.ActivityType {
        if context.accuracy < 0.5 && context.totalAttempts > 3 {
            return .struggling
        } else if context.accuracy >= 0.8 {
            return .completed
        } else {
            return .courseViewing
        }
    }
    
    func updateCurrentScreen(_ screen: String) {
        currentScreen = screen
        print("Updated current screen to: \(screen)")
    }
    
    func dismissProactiveMessage() {
        shouldShowProactiveMessage = false
        currentProactiveMessage = nil
        print("Dismissed proactive message")
    }
}

// MARK: - Performance Monitor
class PerformanceMonitor {
    private var sessionStartTime = Date()
    private var interactionCount = 0
    var totalAttempts = 0
    
    func recordInteraction() {
        interactionCount += 1
    }
    
    func getSessionDuration() -> TimeInterval {
        return Date().timeIntervalSince(sessionStartTime)
    }
    
    func getInteractionRate() -> Double {
        let duration = getSessionDuration()
        guard duration > 0 else { return 0 }
        return Double(interactionCount) / duration
    }
    
    func reset() {
        sessionStartTime = Date()
        interactionCount = 0
        totalAttempts = 0
    }
}

// MARK: - Proactive Trigger
enum ProactiveTrigger: Identifiable {
    case userIdleTime(duration: TimeInterval)
    case screenFocus(screen: String, duration: TimeInterval)
    case lowPerformance(score: Double)
    case learningStruggle(topic: String)
    case timeBasedReminder(time: Date)
    case errorFrequency(count: Int)
    case repeatedErrors(count: Int)
    case voiceWakeWord(phrase: String)
    case encouragementNeeded
    case sessionMilestone(achievement: String)
    
    var id: String {
        switch self {
        case .userIdleTime(let duration):
            return "idle_\(duration)"
        case .screenFocus(let screen, let duration):
            return "focus_\(screen)_\(duration)"
        case .lowPerformance(let score):
            return "performance_\(score)"
        case .learningStruggle(let topic):
            return "struggle_\(topic)"
        case .timeBasedReminder(let time):
            return "reminder_\(time.timeIntervalSince1970)"
        case .errorFrequency(let count):
            return "error_\(count)"
        case .repeatedErrors(let count):
            return "repeated_error_\(count)"
        case .voiceWakeWord(let phrase):
            return "voice_\(phrase)"
        case .encouragementNeeded:
            return "encouragement"
        case .sessionMilestone(let achievement):
            return "milestone_\(achievement)"
        }
    }
    
    var shouldTrigger: Bool {
        switch self {
        case .userIdleTime(let duration):
            return duration > 300 // 5 minutes
        case .screenFocus(_, let duration):
            return duration > 1800 // 30 minutes
        case .lowPerformance(let score):
            return score < 0.6
        case .learningStruggle(_):
            return true
        case .timeBasedReminder(_):
            return true
        case .errorFrequency(let count):
            return count > 5
        case .repeatedErrors(let count):
            return count > 3
        case .voiceWakeWord(_):
            return true
        case .encouragementNeeded:
            return true
        case .sessionMilestone(_):
            return true
        }
    }
}


// MARK: - Performance Monitor (consolidated - removed duplicate)

// MARK: - Analytics Types

struct ProactiveAnalytics {
    let totalTriggers: Int
    let triggersByType: [String: Int]
    let averageIdleTime: TimeInterval
    let currentPerformance: Double
    let errorRate: Double
}

// MARK: - Extensions

extension ProactiveTrigger: Equatable {
    static func == (lhs: ProactiveTrigger, rhs: ProactiveTrigger) -> Bool {
        switch (lhs, rhs) {
        case (.userIdleTime(let duration1), .userIdleTime(let duration2)):
            return abs(duration1 - duration2) < 1.0
        case (.lowPerformance(let score1), .lowPerformance(let score2)):
            return abs(score1 - score2) < 0.01
        case (.repeatedErrors(let count1), .repeatedErrors(let count2)):
            return count1 == count2
        case (.voiceWakeWord(let phrase1), .voiceWakeWord(let phrase2)):
            return phrase1 == phrase2
        case (.screenFocus(let screen1, let duration1), .screenFocus(let screen2, let duration2)):
            return screen1 == screen2 && abs(duration1 - duration2) < 1.0
        case (.learningStruggle(let topic1), .learningStruggle(let topic2)):
            return topic1 == topic2
        case (.encouragementNeeded, .encouragementNeeded):
            return true
        case (.sessionMilestone(let achievement1), .sessionMilestone(let achievement2)):
            return achievement1 == achievement2
        default:
            return false
        }
    }
}