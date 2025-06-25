import Foundation
import Combine
import SwiftUI

@MainActor
class ProactiveAIManager: ObservableObject {
    @Published var activeTriggers: [ProactiveTrigger] = []
    @Published var shouldShowProactiveMessage = false
    @Published var currentProactiveMessage: String?
    @Published var proactiveMessageEmotion: GemmaAPIResponse.EmotionState = .neutral
    
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
    
    private let config: StudyBuddyConfig
    
    init(config: StudyBuddyConfig = .default) {
        self.config = config
        setupProactiveMonitoring()
    }
    
    private func setupProactiveMonitoring() {
        guard config.proactiveAssistance else { return }
        
        // Start idle time monitoring
        startIdleTimeMonitoring()
        
        // Start performance monitoring
        startPerformanceMonitoring()
        
        // Monitor for error patterns
        startErrorPatternMonitoring()
        
        // Set up screen focus monitoring
        startScreenFocusMonitoring()
    }
    
    // MARK: - Idle Time Monitoring
    
    private func startIdleTimeMonitoring() {
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