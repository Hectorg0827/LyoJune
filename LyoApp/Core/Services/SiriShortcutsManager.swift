//
//  SiriShortcutsManager.swift
//  LyoApp
//
//  Siri Shortcuts integration for voice commands and automation
//

import Foundation
import Intents
import IntentsUI
import SwiftUI

// MARK: - Custom Intent Definitions
enum LyoAppIntent: String, CaseIterable {
    case startStudySession = "StartStudySession"
    case checkProgress = "CheckProgress"
    case continueLesson = "ContinueLesson"
    case viewStreak = "ViewStreak"
    case openCourse = "OpenCourse"
    case markLessonComplete = "MarkLessonComplete"
    case setStudyReminder = "SetStudyReminder"
    case viewCDAchievements = "ViewCDAchievements"
    
    var title: String {
        switch self {
        case .startStudySession: return "Start Study Session"
        case .checkProgress: return "Check Learning Progress"
        case .continueLesson: return "Continue Current Lesson"
        case .viewStreak: return "View Study Streak"
        case .openCourse: return "Open Course"
        case .markLessonComplete: return "Mark Lesson Complete"
        case .setStudyReminder: return "Set Study Reminder"
        case .viewCDAchievements: return "View CDAchievements"
        }
    }
    
    var subtitle: String {
        switch self {
        case .startStudySession: return "Begin a new study session in LyoApp"
        case .checkProgress: return "See your learning progress and stats"
        case .continueLesson: return "Resume where you left off"
        case .viewStreak: return "Check your current study streak"
        case .openCourse: return "Access a specific course"
        case .markLessonComplete: return "Mark current lesson as completed"
        case .setStudyReminder: return "Set a reminder to study"
        case .viewCDAchievements: return "See your earned achievements"
        }
    }
    
    var suggestedPhrase: String {
        switch self {
        case .startStudySession: return "Start studying with LyoApp"
        case .checkProgress: return "Show my learning progress"
        case .continueLesson: return "Continue my lesson"
        case .viewStreak: return "What's my study streak?"
        case .openCourse: return "Open my course"
        case .markLessonComplete: return "Mark lesson as complete"
        case .setStudyReminder: return "Remind me to study"
        case .viewCDAchievements: return "Show my achievements"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .startStudySession: return "play.circle.fill"
        case .checkProgress: return "chart.line.uptrend.xyaxis"
        case .continueLesson: return "arrow.right.circle.fill"
        case .viewStreak: return "flame.fill"
        case .openCourse: return "book.fill"
        case .markLessonComplete: return "checkmark.circle.fill"
        case .setStudyReminder: return "bell.fill"
        case .viewCDAchievements: return "trophy.fill"
        }
    }
}

// MARK: - Shortcut Result
struct ShortcutResult {
    let success: Bool
    let title: String
    let message: String
    let userInfo: [String: Any]
    
    static func success(title: String, message: String, userInfo: [String: Any] = [:]) -> ShortcutResult {
        return ShortcutResult(success: true, title: title, message: message, userInfo: userInfo)
    }
    
    static func failure(title: String, message: String) -> ShortcutResult {
        return ShortcutResult(success: false, title: title, message: message, userInfo: [:])
    }
}

// MARK: - SiriShortcutsManager
@MainActor
class SiriShortcutsManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var donatedShortcuts: [INVoiceShortcut] = []
    @Published var availableShortcuts: [NSUserActivity] = []
    
    // MARK: - Private Properties
    private let shortcutCenter = INVoiceShortcutCenter.shared
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupShortcuts()
    }
    
    // MARK: - Setup
    
    private func setupShortcuts() {
        createUserActivities()
        refreshDonatedShortcuts()
    }
    
    private func createUserActivities() {
        availableShortcuts = LyoAppIntent.allCases.map { intent in
            let activity = NSUserActivity(activityType: "com.lyoapp.\(intent.rawValue)")
            activity.title = intent.title
            activity.subtitle = intent.subtitle
            activity.suggestedInvocationPhrase = intent.suggestedPhrase
            activity.isEligibleForSearch = true
            activity.isEligibleForPrediction = true
            activity.isEligibleForHandoff = false
            
            // Add metadata
            activity.userInfo = [
                "intent_type": intent.rawValue,
                "title": intent.title,
                "subtitle": intent.subtitle
            ]
            
            // Add keywords for better search
            let keywords: Set<String> = {
                switch intent {
                case .startStudySession:
                    return ["study", "learn", "session", "start", "begin"]
                case .checkProgress:
                    return ["progress", "stats", "analytics", "check"]
                case .continueLesson:
                    return ["continue", "resume", "lesson", "current"]
                case .viewStreak:
                    return ["streak", "fire", "daily", "consecutive"]
                case .openCourse:
                    return ["course", "open", "access", "view"]
                case .markLessonComplete:
                    return ["complete", "finish", "done", "mark"]
                case .setStudyReminder:
                    return ["reminder", "notification", "alert", "schedule"]
                case .viewCDAchievements:
                    return ["achievements", "badges", "awards", "trophies"]
                }
            }()
            
            activity.keywords = keywords
            
            return activity
        }
    }
    
    // MARK: - Donation
    
    /// Donate shortcut for improved Siri suggestions
    func donateShortcut(_ intent: LyoAppIntent, userInfo: [String: Any] = [:]) {
        guard let activity = availableShortcuts.first(where: { 
            $0.userInfo?["intent_type"] as? String == intent.rawValue 
        }) else { return }
        
        // Update user info with context
        var updatedUserInfo = activity.userInfo ?? [:]
        updatedUserInfo.merge(userInfo) { _, new in new }
        activity.userInfo = updatedUserInfo
        
        // Make current
        activity.becomeCurrent()
        
        print("✅ Donated shortcut: \(intent.title)")
    }
    
    /// Donate study session shortcut with course context
    func donateStudySession(courseId: String, courseName: String) {
        donateShortcut(.startStudySession, userInfo: [
            "course_id": courseId,
            "course_name": courseName
        ])
    }
    
    /// Donate progress check after significant milestone
    func donateProgressCheck(streakCount: Int, completedLessons: Int) {
        donateShortcut(.checkProgress, userInfo: [
            "streak_count": streakCount,
            "completed_lessons": completedLessons
        ])
    }
    
    /// Donate continue lesson when user pauses mid-lesson
    func donateContinueLesson(lessonId: String, lessonTitle: String, progress: Double) {
        donateShortcut(.continueLesson, userInfo: [
            "lesson_id": lessonId,
            "lesson_title": lessonTitle,
            "progress": progress
        ])
    }
    
    // MARK: - Voice Shortcut Management
    
    /// Add voice shortcut for an intent
    func addVoiceShortcut(for intent: LyoAppIntent) {
        guard let activity = availableShortcuts.first(where: { 
            $0.userInfo?["intent_type"] as? String == intent.rawValue 
        }) else { return }
        
        let shortcut = INShortcut(userActivity: activity)
        let viewController = INUIAddVoiceShortcutViewController(shortcut: shortcut)
        viewController.delegate = self
        
        // Present view controller (would need to be handled by the calling view)
        NotificationCenter.default.post(
            name: .presentVoiceShortcutViewController,
            object: viewController
        )
    }
    
    /// Edit existing voice shortcut
    func editVoiceShortcut(_ voiceShortcut: INVoiceShortcut) {
        let viewController = INUIEditVoiceShortcutViewController(voiceShortcut: voiceShortcut)
        viewController.delegate = self
        
        NotificationCenter.default.post(
            name: .presentVoiceShortcutViewController,
            object: viewController
        )
    }
    
    /// Delete voice shortcut
    func deleteVoiceShortcut(_ voiceShortcut: INVoiceShortcut) {
        shortcutCenter.removeVoiceShortcut(voiceShortcut) { error in
            if let error = error {
                print("❌ Failed to delete voice shortcut: \(error)")
            } else {
                print("✅ Deleted voice shortcut")
                Task { @MainActor in
                    self.refreshDonatedShortcuts()
                }
            }
        }
    }
    
    /// Refresh donated shortcuts
    func refreshDonatedShortcuts() {
        shortcutCenter.getAllVoiceShortcuts { shortcuts, error in
            Task { @MainActor in
                if let shortcuts = shortcuts {
                    self.donatedShortcuts = shortcuts
                } else if let error = error {
                    print("❌ Failed to get voice shortcuts: \(error)")
                }
            }
        }
    }
    
    // MARK: - Intent Handling
    
    /// Handle shortcut intent
    func handleShortcut(_ intent: LyoAppIntent, userInfo: [String: Any] = [:]) async -> ShortcutResult {
        switch intent {
        case .startStudySession:
            return await handleStartStudySession(userInfo: userInfo)
        case .checkProgress:
            return await handleCheckProgress(userInfo: userInfo)
        case .continueLesson:
            return await handleContinueLesson(userInfo: userInfo)
        case .viewStreak:
            return await handleViewStreak(userInfo: userInfo)
        case .openCourse:
            return await handleOpenCourse(userInfo: userInfo)
        case .markLessonComplete:
            return await handleMarkLessonComplete(userInfo: userInfo)
        case .setStudyReminder:
            return await handleSetStudyReminder(userInfo: userInfo)
        case .viewCDAchievements:
            return await handleViewCDAchievements(userInfo: userInfo)
        }
    }
    
    // MARK: - Intent Handlers
    
    private func handleStartStudySession(userInfo: [String: Any]) async -> ShortcutResult {
        // Navigate to study session
        let courseName = userInfo["course_name"] as? String ?? "your course"
        
        NotificationCenter.default.post(
            name: .siriStartStudySession,
            object: nil,
            userInfo: userInfo
        )
        
        return .success(
            title: "Study Session Started",
            message: "Ready to continue with \(courseName)!",
            userInfo: userInfo
        )
    }
    
    private func handleCheckProgress(userInfo: [String: Any]) async -> ShortcutResult {
        // Get current progress (would typically come from a service)
        let streakCount = userInfo["streak_count"] as? Int ?? 0
        let completedLessons = userInfo["completed_lessons"] as? Int ?? 0
        
        NotificationCenter.default.post(
            name: .siriCheckProgress,
            object: nil,
            userInfo: userInfo
        )
        
        return .success(
            title: "Your Progress",
            message: "🔥 \(streakCount) day streak • 📚 \(completedLessons) lessons completed",
            userInfo: userInfo
        )
    }
    
    private func handleContinueLesson(userInfo: [String: Any]) async -> ShortcutResult {
        let lessonTitle = userInfo["lesson_title"] as? String ?? "your lesson"
        let progress = userInfo["progress"] as? Double ?? 0.0
        let progressPercent = Int(progress * 100)
        
        NotificationCenter.default.post(
            name: .siriContinueLesson,
            object: nil,
            userInfo: userInfo
        )
        
        return .success(
            title: "Lesson Resumed",
            message: "Continuing \(lessonTitle) from \(progressPercent)%",
            userInfo: userInfo
        )
    }
    
    private func handleViewStreak(userInfo: [String: Any]) async -> ShortcutResult {
        let streakCount = userInfo["streak_count"] as? Int ?? 0
        
        NotificationCenter.default.post(
            name: .siriViewStreak,
            object: nil,
            userInfo: userInfo
        )
        
        return .success(
            title: "Study Streak",
            message: "🔥 You're on a \(streakCount) day streak! Keep it up!",
            userInfo: userInfo
        )
    }
    
    private func handleOpenCourse(userInfo: [String: Any]) async -> ShortcutResult {
        let courseName = userInfo["course_name"] as? String ?? "course"
        
        NotificationCenter.default.post(
            name: .siriOpenCourse,
            object: nil,
            userInfo: userInfo
        )
        
        return .success(
            title: "Course Opened",
            message: "Opening \(courseName)",
            userInfo: userInfo
        )
    }
    
    private func handleMarkLessonComplete(userInfo: [String: Any]) async -> ShortcutResult {
        let lessonTitle = userInfo["lesson_title"] as? String ?? "lesson"
        
        NotificationCenter.default.post(
            name: .siriMarkLessonComplete,
            object: nil,
            userInfo: userInfo
        )
        
        return .success(
            title: "Lesson Completed",
            message: "Great job completing \(lessonTitle)! 🎉",
            userInfo: userInfo
        )
    }
    
    private func handleSetStudyReminder(userInfo: [String: Any]) async -> ShortcutResult {
        // This would integrate with NotificationManager
        NotificationCenter.default.post(
            name: .siriSetStudyReminder,
            object: nil,
            userInfo: userInfo
        )
        
        return .success(
            title: "Reminder Set",
            message: "I'll remind you to study later!",
            userInfo: userInfo
        )
    }
    
    private func handleViewCDAchievements(userInfo: [String: Any]) async -> ShortcutResult {
        NotificationCenter.default.post(
            name: .siriViewCDAchievements,
            object: nil,
            userInfo: userInfo
        )
        
        return .success(
            title: "Your CDAchievements",
            message: "Check out all your earned badges and trophies!",
            userInfo: userInfo
        )
    }
}

// MARK: - INUIAddVoiceShortcutViewControllerDelegate
extension SiriShortcutsManager: INUIAddVoiceShortcutViewControllerDelegate {
    
    func addVoiceShortcutViewController(
        _ controller: INUIAddVoiceShortcutViewController,
        didFinishWith voiceShortcut: INVoiceShortcut?,
        error: Error?
    ) {
        controller.dismiss(animated: true) {
            if let error = error {
                print("❌ Failed to add voice shortcut: \(error)")
            } else if voiceShortcut != nil {
                print("✅ Added voice shortcut")
                self.refreshDonatedShortcuts()
            }
        }
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true)
    }
}

// MARK: - INUIEditVoiceShortcutViewControllerDelegate
extension SiriShortcutsManager: INUIEditVoiceShortcutViewControllerDelegate {
    
    func editVoiceShortcutViewController(
        _ controller: INUIEditVoiceShortcutViewController,
        didUpdate voiceShortcut: INVoiceShortcut?,
        error: Error?
    ) {
        controller.dismiss(animated: true) {
            if let error = error {
                print("❌ Failed to update voice shortcut: \(error)")
            } else {
                print("✅ Updated voice shortcut")
                self.refreshDonatedShortcuts()
            }
        }
    }
    
    func editVoiceShortcutViewController(
        _ controller: INUIEditVoiceShortcutViewController,
        didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID
    ) {
        controller.dismiss(animated: true) {
            print("✅ Deleted voice shortcut")
            self.refreshDonatedShortcuts()
        }
    }
    
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true)
    }
}

// MARK: - Notification Names for Siri Shortcuts
extension Notification.Name {
    static let presentVoiceShortcutViewController = Notification.Name("presentVoiceShortcutViewController")
    static let siriStartStudySession = Notification.Name("siriStartStudySession")
    static let siriCheckProgress = Notification.Name("siriCheckProgress")
    static let siriContinueLesson = Notification.Name("siriContinueLesson")
    static let siriViewStreak = Notification.Name("siriViewStreak")
    static let siriOpenCourse = Notification.Name("siriOpenCourse")
    static let siriMarkLessonComplete = Notification.Name("siriMarkLessonComplete")
    static let siriSetStudyReminder = Notification.Name("siriSetStudyReminder")
    static let siriViewCDAchievements = Notification.Name("siriViewCDAchievements")
}
