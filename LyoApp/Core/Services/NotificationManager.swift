//
//  NotificationManager.swift
//  LyoApp
//
//  Advanced notification system with rich content, categories, and actions
//

import Foundation
import UserNotifications
import UIKit
import SwiftUI

// MARK: - Notification Types
enum NotificationType: String, CaseIterable {
    case studyReminder = "study_reminder"
    case streakReminder = "streak_reminder"
    case newCourse = "new_course"
    case achievementUnlocked = "achievement_unlocked"
    case friendActivity = "friend_activity"
    case courseUpdate = "course_update"
    case liveClass = "live_class"
    case assignment = "assignment"
    case message = "message"
    case systemUpdate = "system_update"
    
    var categoryIdentifier: String {
        return "category_\(rawValue)"
    }
    
    var displayName: String {
        switch self {
        case .studyReminder: return "Study Reminders"
        case .streakReminder: return "Streak Reminders"
        case .newCourse: return "New Courses"
        case .achievementUnlocked: return "Achievements"
        case .friendActivity: return "Friend Activity"
        case .courseUpdate: return "Course Updates"
        case .liveClass: return "Live Classes"
        case .assignment: return "Assignments"
        case .message: return "Messages"
        case .systemUpdate: return "System Updates"
        }
    }
    
    var defaultEnabled: Bool {
        switch self {
        case .studyReminder, .streakReminder, .achievementUnlocked, .liveClass, .assignment:
            return true
        case .newCourse, .friendActivity, .courseUpdate, .message, .systemUpdate:
            return false
        }
    }
    
    var priority: NotificationPriority {
        switch self {
        case .liveClass, .assignment:
            return .high
        case .studyReminder, .streakReminder, .achievementUnlocked:
            return .medium
        default:
            return .low
        }
    }
}

enum NotificationPriority: String {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var interruptionLevel: UNNotificationInterruptionLevel {
        switch self {
        case .low: return .passive
        case .medium: return .active
        case .high: return .timeSensitive
        }
    }
}

// MARK: - Notification Actions
enum NotificationAction: String, CaseIterable {
    case startStudying = "START_STUDYING"
    case viewCourse = "VIEW_COURSE"
    case markComplete = "MARK_COMPLETE"
    case snooze = "SNOOZE"
    case dismiss = "DISMISS"
    case reply = "REPLY"
    case viewAchievement = "VIEW_ACHIEVEMENT"
    case joinClass = "JOIN_CLASS"
    case viewAssignment = "VIEW_ASSIGNMENT"
    
    var title: String {
        switch self {
        case .startStudying: return "Start Studying"
        case .viewCourse: return "View Course"
        case .markComplete: return "Mark Complete"
        case .snooze: return "Snooze 15m"
        case .dismiss: return "Dismiss"
        case .reply: return "Reply"
        case .viewAchievement: return "View Achievement"
        case .joinClass: return "Join Class"
        case .viewAssignment: return "View Assignment"
        }
    }
    
    var isDestructive: Bool {
        return self == .dismiss
    }
    
    var isForeground: Bool {
        switch self {
        case .startStudying, .viewCourse, .viewAchievement, .joinClass, .viewAssignment:
            return true
        default:
            return false
        }
    }
    
    var textInputButtonTitle: String? {
        return self == .reply ? "Send" : nil
    }
    
    var textInputPlaceholder: String? {
        return self == .reply ? "Type your reply..." : nil
    }
}

// MARK: - Notification Content
struct NotificationContent {
    let type: NotificationType
    let title: String
    let body: String
    let subtitle: String?
    let badge: Int?
    let sound: UNNotificationSound?
    let userInfo: [String: Any]
    let attachments: [NotificationAttachment]
    let categoryIdentifier: String
    let threadIdentifier: String?
    let targetContentIdentifier: String?
    
    init(
        type: NotificationType,
        title: String,
        body: String,
        subtitle: String? = nil,
        badge: Int? = nil,
        sound: UNNotificationSound? = .default,
        userInfo: [String: Any] = [:],
        attachments: [NotificationAttachment] = [],
        threadIdentifier: String? = nil,
        targetContentIdentifier: String? = nil
    ) {
        self.type = type
        self.title = title
        self.body = body
        self.subtitle = subtitle
        self.badge = badge
        self.sound = sound
        self.userInfo = userInfo
        self.attachments = attachments
        self.categoryIdentifier = type.categoryIdentifier
        self.threadIdentifier = threadIdentifier
        self.targetContentIdentifier = targetContentIdentifier
    }
}

struct NotificationAttachment {
    let identifier: String
    let url: URL
    let options: [String: Any]?
    
    init(identifier: String, url: URL, options: [String: Any]? = nil) {
        self.identifier = identifier
        self.url = url
        self.options = options
    }
}

// MARK: - Notification Schedule
enum NotificationSchedule {
    case immediate
    case date(Date)
    case timeInterval(TimeInterval)
    case calendar(DateComponents, repeats: Bool)
    case location(CLLocationCoordinate2D, radius: Double, notifyOnEntry: Bool, notifyOnExit: Bool)
}

// MARK: - Notification Settings
struct NotificationSettings: Codable {
    var enabledTypes: Set<String>
    var quietHoursEnabled: Bool
    var quietHoursStart: Date
    var quietHoursEnd: Date
    var studyReminderTimes: [Date]
    var streakReminderTime: Date
    var soundEnabled: Bool
    var badgeEnabled: Bool
    var bannerEnabled: Bool
    
    static let `default` = NotificationSettings(
        enabledTypes: Set(NotificationType.allCases.filter { $0.defaultEnabled }.map { $0.rawValue }),
        quietHoursEnabled: true,
        quietHoursStart: Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date(),
        quietHoursEnd: Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date(),
        studyReminderTimes: [
            Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date(),
            Calendar.current.date(from: DateComponents(hour: 19, minute: 0)) ?? Date()
        ],
        streakReminderTime: Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date(),
        soundEnabled: true,
        badgeEnabled: true,
        bannerEnabled: true
    )
}

// MARK: - NotificationManager
@MainActor
class NotificationManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var settings = NotificationSettings.default
    @Published var pendingNotifications: [UNNotificationRequest] = []
    @Published var deliveredNotifications: [UNNotification] = []
    
    // MARK: - Private Properties
    private let center = UNUserNotificationCenter.current()
    private let settingsKey = "notification_settings"
    
    // MARK: - Initialization
    override init() {
        super.init()
        center.delegate = self
        loadSettings()
        setupNotificationCategories()
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// Request notification permissions
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(
                options: [.alert, .badge, .sound, .providesAppNotificationSettings, .criticalAlert]
            )
            
            await updateAuthorizationStatus()
            
            if granted {
                await registerForRemoteNotifications()
            }
            
            return granted
        } catch {
            print("❌ Failed to request notification authorization: \(error)")
            return false
        }
    }
    
    /// Check current authorization status
    func checkAuthorizationStatus() {
        Task {
            await updateAuthorizationStatus()
        }
    }
    
    private func updateAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }
    
    /// Register for remote notifications
    private func registerForRemoteNotifications() async {
        await UIApplication.shared.registerForRemoteNotifications()
    }
    
    // MARK: - Notification Categories & Actions
    
    private func setupNotificationCategories() {
        let categories = NotificationType.allCases.map { createCategory(for: $0) }
        center.setNotificationCategories(Set(categories))
    }
    
    private func createCategory(for type: NotificationType) -> UNNotificationCategory {
        let actions = getActions(for: type).map { createAction(for: $0) }
        
        return UNNotificationCategory(
            identifier: type.categoryIdentifier,
            actions: actions,
            intentIdentifiers: [],
            options: [.customDismissAction, .allowInCarPlay]
        )
    }
    
    private func getActions(for type: NotificationType) -> [NotificationAction] {
        switch type {
        case .studyReminder:
            return [.startStudying, .snooze, .dismiss]
        case .streakReminder:
            return [.startStudying, .dismiss]
        case .newCourse:
            return [.viewCourse, .dismiss]
        case .achievementUnlocked:
            return [.viewAchievement, .dismiss]
        case .friendActivity:
            return [.viewCourse, .dismiss]
        case .courseUpdate:
            return [.viewCourse, .dismiss]
        case .liveClass:
            return [.joinClass, .snooze, .dismiss]
        case .assignment:
            return [.viewAssignment, .markComplete, .snooze]
        case .message:
            return [.reply, .dismiss]
        case .systemUpdate:
            return [.dismiss]
        }
    }
    
    private func createAction(for action: NotificationAction) -> UNNotificationAction {
        let options: UNNotificationActionOptions = {
            var opts: UNNotificationActionOptions = []
            if action.isDestructive { opts.insert(.destructive) }
            if action.isForeground { opts.insert(.foreground) }
            return opts
        }()
        
        if let buttonTitle = action.textInputButtonTitle,
           let placeholder = action.textInputPlaceholder {
            return UNTextInputNotificationAction(
                identifier: action.rawValue,
                title: action.title,
                options: options,
                textInputButtonTitle: buttonTitle,
                textInputPlaceholder: placeholder
            )
        } else {
            return UNNotificationAction(
                identifier: action.rawValue,
                title: action.title,
                options: options
            )
        }
    }
    
    // MARK: - Scheduling Notifications
    
    /// Schedule a notification
    func scheduleNotification(
        content: NotificationContent,
        schedule: NotificationSchedule,
        identifier: String? = nil
    ) async -> Bool {
        
        // Check if type is enabled
        guard settings.enabledTypes.contains(content.type.rawValue) else {
            print("⚠️ Notification type \(content.type.rawValue) is disabled")
            return false
        }
        
        // Check quiet hours
        if settings.quietHoursEnabled && isInQuietHours() {
            print("⚠️ Notification scheduled during quiet hours")
            // Could reschedule for after quiet hours instead
        }
        
        let request = try? await createNotificationRequest(
            content: content,
            schedule: schedule,
            identifier: identifier ?? UUID().uuidString
        )
        
        guard let request = request else {
            return false
        }
        
        do {
            try await center.add(request)
            await refreshPendingNotifications()
            print("✅ Scheduled notification: \(request.identifier)")
            return true
        } catch {
            print("❌ Failed to schedule notification: \(error)")
            return false
        }
    }
    
    private func createNotificationRequest(
        content: NotificationContent,
        schedule: NotificationSchedule,
        identifier: String
    ) async throws -> UNNotificationRequest {
        
        let unContent = UNMutableNotificationContent()
        unContent.title = content.title
        unContent.body = content.body
        unContent.subtitle = content.subtitle ?? ""
        unContent.badge = content.badge as? NSNumber
        unContent.sound = settings.soundEnabled ? (content.sound ?? .default) : nil
        unContent.userInfo = content.userInfo
        unContent.categoryIdentifier = content.categoryIdentifier
        unContent.threadIdentifier = content.threadIdentifier ?? content.type.rawValue
        unContent.targetContentIdentifier = content.targetContentIdentifier
        unContent.interruptionLevel = content.type.priority.interruptionLevel
        
        // Add attachments
        var attachments: [UNNotificationAttachment] = []
        for attachment in content.attachments {
            if let unAttachment = try? UNNotificationAttachment(
                identifier: attachment.identifier,
                url: attachment.url,
                options: attachment.options
            ) {
                attachments.append(unAttachment)
            }
        }
        unContent.attachments = attachments
        
        // Create trigger based on schedule
        let trigger = createTrigger(for: schedule)
        
        return UNNotificationRequest(
            identifier: identifier,
            content: unContent,
            trigger: trigger
        )
    }
    
    private func createTrigger(for schedule: NotificationSchedule) -> UNNotificationTrigger? {
        switch schedule {
        case .immediate:
            return nil
        case .date(let date):
            let timeInterval = date.timeIntervalSinceNow
            return timeInterval > 0 ? UNTimeIntervalNotificationTrigger(
                timeInterval: timeInterval,
                repeats: false
            ) : nil
        case .timeInterval(let interval):
            return UNTimeIntervalNotificationTrigger(
                timeInterval: interval,
                repeats: false
            )
        case .calendar(let dateComponents, let repeats):
            return UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: repeats
            )
        case .location(let coordinate, let radius, let notifyOnEntry, let notifyOnExit):
            let region = CLCircularRegion(
                center: coordinate,
                radius: radius,
                identifier: UUID().uuidString
            )
            region.notifyOnEntry = notifyOnEntry
            region.notifyOnExit = notifyOnExit
            return UNLocationNotificationTrigger(region: region, repeats: false)
        }
    }
    
    // MARK: - Quick Notification Methods
    
    /// Schedule study reminder
    func scheduleStudyReminder(courseName: String, time: Date) async {
        let content = NotificationContent(
            type: .studyReminder,
            title: "Time to Study! 📚",
            body: "Ready to continue with \(courseName)?",
            userInfo: ["course_name": courseName]
        )
        
        await scheduleNotification(
            content: content,
            schedule: .date(time)
        )
    }
    
    /// Schedule streak reminder
    func scheduleStreakReminder(streakCount: Int) async {
        let content = NotificationContent(
            type: .streakReminder,
            title: "Don't break your streak! 🔥",
            body: "You're on a \(streakCount)-day streak. Keep it going!",
            badge: 1,
            userInfo: ["streak_count": streakCount]
        )
        
        await scheduleNotification(
            content: content,
            schedule: .date(settings.streakReminderTime)
        )
    }
    
    /// Show achievement notification
    func showAchievementUnlocked(title: String, description: String, badgeImageURL: URL? = nil) async {
        var attachments: [NotificationAttachment] = []
        
        if let imageURL = badgeImageURL {
            attachments.append(NotificationAttachment(
                identifier: "achievement_badge",
                url: imageURL
            ))
        }
        
        let content = NotificationContent(
            type: .achievementUnlocked,
            title: "Achievement Unlocked! 🏆",
            body: "\(title) - \(description)",
            attachments: attachments,
            userInfo: ["achievement_title": title, "achievement_description": description]
        )
        
        await scheduleNotification(
            content: content,
            schedule: .immediate
        )
    }
    
    // MARK: - Management
    
    /// Cancel notification
    func cancelNotification(identifier: String) async {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        await refreshPendingNotifications()
    }
    
    /// Cancel all notifications of a type
    func cancelNotifications(ofType type: NotificationType) async {
        let pending = await center.pendingNotificationRequests()
        let identifiersToRemove = pending
            .filter { $0.content.categoryIdentifier == type.categoryIdentifier }
            .map { $0.identifier }
        
        center.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        await refreshPendingNotifications()
    }
    
    /// Cancel all notifications
    func cancelAllNotifications() async {
        center.removeAllPendingNotificationRequests()
        await refreshPendingNotifications()
    }
    
    /// Clear delivered notifications
    func clearDeliveredNotifications() async {
        center.removeAllDeliveredNotifications()
        await refreshDeliveredNotifications()
    }
    
    /// Refresh pending notifications
    func refreshPendingNotifications() async {
        pendingNotifications = await center.pendingNotificationRequests()
    }
    
    /// Refresh delivered notifications
    func refreshDeliveredNotifications() async {
        deliveredNotifications = await center.deliveredNotifications()
    }
    
    // MARK: - Settings
    
    /// Update notification settings
    func updateSettings(_ newSettings: NotificationSettings) {
        settings = newSettings
        saveSettings()
    }
    
    /// Toggle notification type
    func toggleNotificationType(_ type: NotificationType, enabled: Bool) {
        if enabled {
            settings.enabledTypes.insert(type.rawValue)
        } else {
            settings.enabledTypes.remove(type.rawValue)
        }
        saveSettings()
    }
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decodedSettings = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            settings = decodedSettings
        }
    }
    
    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }
    
    // MARK: - Helper Methods
    
    private func isInQuietHours() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        
        let startHour = calendar.component(.hour, from: settings.quietHoursStart)
        let startMinute = calendar.component(.minute, from: settings.quietHoursStart)
        let endHour = calendar.component(.hour, from: settings.quietHoursEnd)
        let endMinute = calendar.component(.minute, from: settings.quietHoursEnd)
        
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        let currentMinutes = currentHour * 60 + currentMinute
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute
        
        if startMinutes <= endMinutes {
            // Same day (e.g., 10 PM - 11 PM)
            return currentMinutes >= startMinutes && currentMinutes <= endMinutes
        } else {
            // Crosses midnight (e.g., 10 PM - 8 AM)
            return currentMinutes >= startMinutes || currentMinutes <= endMinutes
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .badge, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handleNotificationResponse(response)
        completionHandler()
    }
    
    private func handleNotificationResponse(_ response: UNNotificationResponse) {
        let notification = response.notification
        let userInfo = notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case NotificationAction.startStudying.rawValue:
            // Navigate to study session
            NotificationCenter.default.post(
                name: .startStudySession,
                object: nil,
                userInfo: userInfo
            )
            
        case NotificationAction.viewCourse.rawValue:
            // Navigate to course
            NotificationCenter.default.post(
                name: .viewCourse,
                object: nil,
                userInfo: userInfo
            )
            
        case NotificationAction.snooze.rawValue:
            // Reschedule for 15 minutes later
            Task {
                let newTime = Date().addingTimeInterval(15 * 60)
                if let courseName = userInfo["course_name"] as? String {
                    await scheduleStudyReminder(courseName: courseName, time: newTime)
                }
            }
            
        case NotificationAction.reply.rawValue:
            if let textResponse = response as? UNTextInputNotificationResponse {
                // Handle text reply
                NotificationCenter.default.post(
                    name: .replyToMessage,
                    object: nil,
                    userInfo: ["reply_text": textResponse.userText]
                )
            }
            
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            NotificationCenter.default.post(
                name: .notificationTapped,
                object: nil,
                userInfo: userInfo
            )
        
        default:
            break
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let startStudySession = Notification.Name("startStudySession")
    static let viewCourse = Notification.Name("viewCourse")
    static let replyToMessage = Notification.Name("replyToMessage")
    static let notificationTapped = Notification.Name("notificationTapped")
}

// MARK: - Import CoreLocation for location notifications
import CoreLocation
