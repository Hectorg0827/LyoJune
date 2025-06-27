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
    private let proactiveAI = ProactiveAIManager.shared
    
    enum EmotionState: String, CaseIterable {
        case happy, encouraging, neutral, concerned, excited
        
        var emoji: String {
            switch self {
            case .happy: return "😊"
            case .encouraging: return "💪"
            case .neutral: return "🤖"
            case .concerned: return "🤔"
            case .excited: return "🎉"
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
        proactiveAI.$suggestions
            .assign(to: \.suggestions, on: self)
            .store(in: &cancellables)
        
        proactiveAI.$isActive
            .assign(to: \.isActive, on: self)
            .store(in: &cancellables)
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
        proactiveAI.startProactiveMode()
        generateWelcomeMessage()
    }
    
    func stopProactiveMode() {
        isActive = false
        proactiveAI.stopProactiveMode()
        suggestions.removeAll()
        shouldShowProactiveMessage = false
    }
    
    func updateLearningContext(_ context: LearningContext) {
        learningContext = context
        
        // Update proactive AI with new context
        let activity = UserActivity(
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
        
        proactiveAI.updateContext(userActivity: activity)
        
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
}

// MARK: - Performance Monitor
class PerformanceMonitor {
    private var sessionStartTime = Date()
    private var interactionCount = 0
    
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
        }
    }
}

// Extension for ProactiveAIManager
extension ProactiveAIManager {
    private func startIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.updateIdleTime()
            }
        }
    }
    
    private func updateIdleTime() {
        userIdleTime = Date().timeIntervalSince(lastUserInteraction)
        
        let idleTrigger = ProactiveTrigger.userIdleTime(duration: userIdleTime)
        if idleTrigger.shouldTrigger && !hasActiveTrigger(idleTrigger) {
            processTrigger(idleTrigger)
        }
    }
    
    func recordUserInteraction() {
        lastUserInteraction = Date()
        userIdleTime = 0
        
        // Remove idle-related triggers
        activeTriggers.removeAll { trigger in
            if case .userIdleTime = trigger {
                return true
            }
            return false
        }
    }
    
    // MARK: - Screen Focus Monitoring
    
    private func startScreenFocusMonitoring() {
        screenFocusTimer?.invalidate()
        screenFocusTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.updateScreenFocusTime()
            }
        }
    }
    
    private func updateScreenFocusTime() {
        screenFocusTime += 1.0
        
        let focusTrigger = ProactiveTrigger.screenFocus(screen: currentScreen, duration: screenFocusTime)
        if focusTrigger.shouldTrigger && !hasActiveTrigger(focusTrigger) {
            processTrigger(focusTrigger)
        }
    }
    
    func updateCurrentScreen(_ screen: String) {
        if currentScreen != screen {
            currentScreen = screen
            screenFocusTime = 0
            
            // Remove previous screen focus triggers
            activeTriggers.removeAll { trigger in
                if case .screenFocus = trigger {
                    return true
                }
                return false
            }
        }
    }
    
    // MARK: - Performance Monitoring
    
    private func startPerformanceMonitoring() {
        performanceMonitor.onPerformanceUpdate = { [weak self] score in
            self?.currentPerformanceScore = score
            
            let performanceTrigger = ProactiveTrigger.lowPerformance(score: score)
            if performanceTrigger.shouldTrigger && !(self?.hasActiveTrigger(performanceTrigger) ?? false) {
                self?.processTrigger(performanceTrigger)
            }
        }
    }
    
    func recordQuizResult(score: Double, topic: String) {
        performanceMonitor.recordQuizResult(score: score, topic: topic)
        
        if score < 0.6 {
            let struggleTrigger = ProactiveTrigger.learningStruggle(topic: topic)
            processTrigger(struggleTrigger)
        } else if score > 0.8 {
            let milestoneTrigger = ProactiveTrigger.sessionMilestone(achievement: "High score in \(topic)!")
            processTrigger(milestoneTrigger)
        }
    }
    
    // MARK: - Error Pattern Monitoring
    
    private func startErrorPatternMonitoring() {
        // Monitor for repeated errors in learning activities
    }
    
    func recordError() {
        errorCount += 1
        
        let errorTrigger = ProactiveTrigger.repeatedErrors(count: errorCount)
        if errorTrigger.shouldTrigger && !hasActiveTrigger(errorTrigger) {
            processTrigger(errorTrigger)
        }
    }
    
    func resetErrorCount() {
        errorCount = 0
        
        // Remove error-related triggers
        activeTriggers.removeAll { trigger in
            if case .repeatedErrors = trigger {
                return true
            }
            return false
        }
    }
    
    // MARK: - Voice Wake Word Detection
    
    func processWakeWord(_ phrase: String) {
        let wakeWordTrigger = ProactiveTrigger.voiceWakeWord(phrase: phrase)
        processTrigger(wakeWordTrigger)
    }
    
    // MARK: - Trigger Processing
    
    private func processTrigger(_ trigger: ProactiveTrigger) {
        guard config.proactiveAssistance else { return }
        
        activeTriggers.append(trigger)
        
        // Generate appropriate proactive message
        let message = generateProactiveMessage(for: trigger)
        currentProactiveMessage = message.content
        proactiveMessageEmotion = message.emotion
        shouldShowProactiveMessage = true
        
        // Schedule trigger cleanup based on priority
        scheduleTriggerCleanup(trigger)
    }
    
    private func generateProactiveMessage(for trigger: ProactiveTrigger) -> (content: String, emotion: GemmaAPIResponse.EmotionState) {
        switch trigger {
        case .userIdleTime(let duration):
            if duration > 60 {
                return ("I notice you've been away for a while. Would you like to continue where you left off?", .encouraging)
            } else {
                return ("Need help with anything? I'm here when you're ready!", .neutral)
            }
            
        case .lowPerformance(_):
            return ("I see you're working hard! Let me suggest some strategies that might help improve your understanding.", .encouraging)
            
        case .repeatedErrors(let count):
            if count >= 5 {
                return ("Don't get discouraged! Making mistakes is part of learning. Would you like me to explain this concept differently?", .encouraging)
            } else {
                return ("I notice this topic might be challenging. Let's break it down step by step!", .explaining)
            }
            
        case .voiceWakeWord(let phrase):
            return ("I heard you say '\(phrase)'. How can I help you today?", .questioning)
            
        case .screenFocus(let screen, _):
            switch screen {
            case "learn":
                return ("You've been studying for a while! Great dedication. Would you like a quick summary or practice quiz?", .encouraging)
            case "discover":
                return ("Exploring new topics? I can help you understand anything that catches your interest!", .neutral)
            default:
                return ("I'm here if you need any help or explanations!", .neutral)
            }
            
        case .learningStruggle(let topic):
            return ("I see you're working on \(topic). This can be tricky! Would you like me to explain it in a different way?", .explaining)
            
        case .encouragementNeeded:
            return ("You're doing great! Remember, every expert was once a beginner. Keep up the amazing work!", .celebrating)
            
        case .sessionMilestone(let achievement):
            return ("Congratulations! \(achievement) You're making excellent progress!", .celebrating)
        }
    }
    
    private func hasActiveTrigger(_ trigger: ProactiveTrigger) -> Bool {
        return activeTriggers.contains { activeTrigger in
            switch (activeTrigger, trigger) {
            case (.userIdleTime, .userIdleTime):
                return true
            case (.lowPerformance, .lowPerformance):
                return true
            case (.repeatedErrors, .repeatedErrors):
                return true
            case (.screenFocus(let screen1, _), .screenFocus(let screen2, _)):
                return screen1 == screen2
            case (.learningStruggle(let topic1), .learningStruggle(let topic2)):
                return topic1 == topic2
            default:
                return false
            }
        }
    }
    
    private func scheduleTriggerCleanup(_ trigger: ProactiveTrigger) {
        let delay: TimeInterval
        
        switch trigger.priority {
        case .immediate:
            delay = 30.0 // 30 seconds
        case .high:
            delay = 120.0 // 2 minutes
        case .medium:
            delay = 300.0 // 5 minutes
        case .low:
            delay = 600.0 // 10 minutes
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.removeTrigger(trigger)
        }
    }
    
    private func removeTrigger(_ trigger: ProactiveTrigger) {
        activeTriggers.removeAll { $0.priority == trigger.priority }
    }
    
    // MARK: - Manual Trigger Controls
    
    func dismissProactiveMessage() {
        shouldShowProactiveMessage = false
        currentProactiveMessage = nil
    }
    
    func triggerEncouragement() {
        let encouragementTrigger = ProactiveTrigger.encouragementNeeded
        processTrigger(encouragementTrigger)
    }
    
    func triggerMilestone(_ achievement: String) {
        let milestoneTrigger = ProactiveTrigger.sessionMilestone(achievement: achievement)
        processTrigger(milestoneTrigger)
    }
    
    // MARK: - Analytics and Insights
    
    func getProactiveAnalytics() -> ProactiveAnalytics {
        return ProactiveAnalytics(
            totalTriggers: activeTriggers.count,
            triggersByType: Dictionary(grouping: activeTriggers) { String(describing: type(of: $0)) }.mapValues { $0.count },
            averageIdleTime: userIdleTime,
            currentPerformance: currentPerformanceScore,
            errorRate: Double(errorCount) / max(1.0, Double(performanceMonitor.totalAttempts))
        )
    }
    
    deinit {
        idleTimer?.invalidate()
        screenFocusTimer?.invalidate()
    }
}

// MARK: - Performance Monitor

class PerformanceMonitor: ObservableObject {
    @Published var averageScore: Double = 1.0
    @Published var totalAttempts: Int = 0
    @Published var recentScores: [Double] = []
    
    var onPerformanceUpdate: ((Double) -> Void)?
    
    func recordQuizResult(score: Double, topic: String) {
        totalAttempts += 1
        recentScores.append(score)
        
        // Keep only recent 10 scores
        if recentScores.count > 10 {
            recentScores.removeFirst()
        }
        
        // Calculate average
        averageScore = recentScores.reduce(0, +) / Double(recentScores.count)
        
        onPerformanceUpdate?(averageScore)
    }
    
    func recordUserActivity(type: String, success: Bool) {
        let score = success ? 1.0 : 0.0
        recordQuizResult(score: score, topic: type)
    }
}

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