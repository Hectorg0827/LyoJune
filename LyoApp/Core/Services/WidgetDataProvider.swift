//
//  WidgetDataProvider.swift
//  LyoApp
//
//  Data provider for iOS widgets with timeline management
//

import Foundation
import WidgetKit
import SwiftUI

// MARK: - Widget Data Types
struct WidgetUserData: Codable {
    let currentStreak: Int
    let totalLessonsCompleted: Int
    let weeklyGoalProgress: Double
    let nextLessonTitle: String?
    let nextLessonProgress: Double
    let lastStudyDate: Date?
    let achievements: [WidgetAchievement]
    let todayStudyTime: TimeInterval
    let weeklyStudyTime: TimeInterval
    
    static let placeholder = WidgetUserData(
        currentStreak: 7,
        totalLessonsCompleted: 42,
        weeklyGoalProgress: 0.6,
        nextLessonTitle: "Swift Functions",
        nextLessonProgress: 0.3,
        lastStudyDate: Date().addingTimeInterval(-3600),
        achievements: [
            WidgetAchievement(
                id: "first-week",
                title: "First Week",
                imageName: "trophy.fill",
                isRecent: true
            )
        ],
        todayStudyTime: 1800, // 30 minutes
        weeklyStudyTime: 7200 // 2 hours
    )
    
    static let empty = WidgetUserData(
        currentStreak: 0,
        totalLessonsCompleted: 0,
        weeklyGoalProgress: 0.0,
        nextLessonTitle: nil,
        nextLessonProgress: 0.0,
        lastStudyDate: nil,
        achievements: [],
        todayStudyTime: 0,
        weeklyStudyTime: 0
    )
}

struct WidgetAchievement: Codable, Identifiable {
    let id: String
    let title: String
    let imageName: String
    let isRecent: Bool
    let earnedDate: Date?
    
    init(id: String, title: String, imageName: String, isRecent: Bool, earnedDate: Date? = nil) {
        self.id = id
        self.title = title
        self.imageName = imageName
        self.isRecent = isRecent
        self.earnedDate = earnedDate ?? (isRecent ? Date() : nil)
    }
}

struct WidgetCourse: Codable, Identifiable {
    let id: String
    let title: String
    let progress: Double
    let nextLessonTitle: String?
    let totalLessons: Int
    let completedLessons: Int
    let lastAccessed: Date?
    
    var progressText: String {
        return "\(completedLessons)/\(totalLessons) lessons"
    }
    
    var progressPercentText: String {
        return "\(Int(progress * 100))%"
    }
}

// MARK: - Widget Timeline Entry
struct LyoWidgetEntry: TimelineEntry {
    let date: Date
    let userData: WidgetUserData
    let relevantCourses: [WidgetCourse]
    let isPlaceholder: Bool
    
    init(date: Date, userData: WidgetUserData, relevantCourses: [WidgetCourse] = [], isPlaceholder: Bool = false) {
        self.date = date
        self.userData = userData
        self.relevantCourses = relevantCourses
        self.isPlaceholder = isPlaceholder
    }
    
    static let placeholder = LyoWidgetEntry(
        date: Date(),
        userData: .placeholder,
        relevantCourses: [
            WidgetCourse(
                id: "swift-basics",
                title: "Swift Basics",
                progress: 0.3,
                nextLessonTitle: "Functions",
                totalLessons: 15,
                completedLessons: 5,
                lastAccessed: Date().addingTimeInterval(-3600)
            )
        ],
        isPlaceholder: true
    )
}

// MARK: - Widget Data Provider
@MainActor
class WidgetDataProvider: ObservableObject {
    
    // MARK: - Shared Instance
    static let shared = WidgetDataProvider(
        coreDataManager: EnhancedCoreDataManager.shared
    )
    
    // MARK: - Published Properties
    @Published var currentData: WidgetUserData = .empty
    @Published var lastUpdated: Date?
    
    // MARK: - Private Properties
    private let coreDataManager: EnhancedCoreDataManager
    private let userDefaults: UserDefaults
    private let widgetDataKey = "widget_user_data"
    private let updateInterval: TimeInterval = 15 * 60 // 15 minutes
    
    // MARK: - Initialization
    init(coreDataManager: EnhancedCoreDataManager) {
        self.coreDataManager = coreDataManager
        
        // Use App Group UserDefaults for widget data sharing
        self.userDefaults = UserDefaults(suiteName: "group.com.lyoapp.widgets") ?? .standard
        
        loadCachedData()
    }
    
    // MARK: - Data Management
    
    /// Get current widget data for timeline
    func getWidgetData() async -> WidgetUserData {
        // Check if we need to refresh data
        if shouldRefreshData() {
            await refreshWidgetData()
        }
        
        return currentData
    }
    
    /// Get timeline entries for widget
    func getTimelineEntries(for family: WidgetFamily, count: Int = 10) async -> [LyoWidgetEntry] {
        let currentData = await getWidgetData()
        let relevantCourses = await getRelevantCourses(for: family)
        
        var entries: [LyoWidgetEntry] = []
        let now = Date()
        
        // Current entry
        entries.append(LyoWidgetEntry(
            date: now,
            userData: currentData,
            relevantCourses: relevantCourses
        ))
        
        // Future entries with updated data
        for i in 1..<count {
            let futureDate = Calendar.current.date(byAdding: .minute, value: i * 15, to: now) ?? now
            let futureData = await generateFutureData(currentData, at: futureDate)
            
            entries.append(LyoWidgetEntry(
                date: futureDate,
                userData: futureData,
                relevantCourses: relevantCourses
            ))
        }
        
        return entries
    }
    
    /// Refresh widget data from Core Data
    func refreshWidgetData() async {
        do {
            let userData = try await fetchUserDataFromCoreData()
            
            // Update current data
            currentData = userData
            lastUpdated = Date()
            
            // Cache for widget extension
            cacheWidgetData(userData)
            
            // Reload all widget timelines
            WidgetCenter.shared.reloadAllTimelines()
            
            print("✅ Widget data refreshed successfully")
            
        } catch {
            print("❌ Failed to refresh widget data: \(error)")
        }
    }
    
    /// Force refresh widget timelines
    func forceRefreshWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Data Fetching
    
    private func fetchUserDataFromCoreData() async throws -> WidgetUserData {
        // This would integrate with your actual Core Data entities
        // For now, returning simulated data
        
        let streak = await coreDataManager.getCurrentStreak()
        let completedLessons = await coreDataManager.getTotalCompletedLessons()
        let weeklyGoal = await coreDataManager.getWeeklyGoalProgress()
        let nextLesson = await coreDataManager.getNextLesson()
        let achievements = await coreDataManager.getRecentAchievements()
        let studyTime = await coreDataManager.getTodayStudyTime()
        let weeklyStudyTime = await coreDataManager.getWeeklyStudyTime()
        
        return WidgetUserData(
            currentStreak: streak,
            totalLessonsCompleted: completedLessons,
            weeklyGoalProgress: weeklyGoal,
            nextLessonTitle: nextLesson?.title,
            nextLessonProgress: nextLesson?.progress ?? 0.0,
            lastStudyDate: await coreDataManager.getLastStudyDate(),
            achievements: achievements.map { achievement in
                WidgetAchievement(
                    id: achievement.id,
                    title: achievement.title,
                    imageName: achievement.imageName,
                    isRecent: achievement.isRecent,
                    earnedDate: achievement.earnedDate
                )
            },
            todayStudyTime: studyTime,
            weeklyStudyTime: weeklyStudyTime
        )
    }
    
    private func getRelevantCourses(for family: WidgetFamily) async -> [WidgetCourse] {
        let maxCourses: Int = {
            switch family {
            case .systemSmall: return 1
            case .systemMedium: return 2
            case .systemLarge: return 3
            case .systemExtraLarge: return 4
            @unknown default: return 2
            }
        }()
        
        let activeCourses = await coreDataManager.getActiveCourses(limit: maxCourses)
        
        return activeCourses.map { course in
            WidgetCourse(
                id: course.id,
                title: course.title,
                progress: course.progress,
                nextLessonTitle: course.nextLessonTitle,
                totalLessons: course.totalLessons,
                completedLessons: course.completedLessons,
                lastAccessed: course.lastAccessed
            )
        }
    }
    
    private func generateFutureData(_ currentData: WidgetUserData, at date: Date) async -> WidgetUserData {
        // Generate slightly updated future data for timeline
        // This could include streak updates, goal progress changes, etc.
        
        let hoursSinceNow = date.timeIntervalSince(Date()) / 3600
        
        // Simulate potential changes
        var futureData = currentData
        
        // If it's a new day, potentially increment streak
        if Calendar.current.isDate(date, inSameDayAs: Date().addingTimeInterval(24 * 60 * 60)) {
            // Don't actually increment, just show potential
            futureData = WidgetUserData(
                currentStreak: currentData.currentStreak,
                totalLessonsCompleted: currentData.totalLessonsCompleted,
                weeklyGoalProgress: min(1.0, currentData.weeklyGoalProgress + 0.1),
                nextLessonTitle: currentData.nextLessonTitle,
                nextLessonProgress: currentData.nextLessonProgress,
                lastStudyDate: currentData.lastStudyDate,
                achievements: currentData.achievements,
                todayStudyTime: 0, // Reset for new day
                weeklyStudyTime: currentData.weeklyStudyTime
            )
        }
        
        return futureData
    }
    
    // MARK: - Caching
    
    private func cacheWidgetData(_ data: WidgetUserData) {
        do {
            let encodedData = try JSONEncoder().encode(data)
            userDefaults.set(encodedData, forKey: widgetDataKey)
            userDefaults.set(Date(), forKey: "\(widgetDataKey)_timestamp")
            print("✅ Cached widget data")
        } catch {
            print("❌ Failed to cache widget data: \(error)")
        }
    }
    
    private func loadCachedData() {
        guard let data = userDefaults.data(forKey: widgetDataKey),
              let decodedData = try? JSONDecoder().decode(WidgetUserData.self, from: data) else {
            currentData = .empty
            return
        }
        
        currentData = decodedData
        
        if let timestamp = userDefaults.object(forKey: "\(widgetDataKey)_timestamp") as? Date {
            lastUpdated = timestamp
        }
    }
    
    private func shouldRefreshData() -> Bool {
        guard let lastUpdated = lastUpdated else { return true }
        
        return Date().timeIntervalSince(lastUpdated) > updateInterval
    }
    
    // MARK: - Widget Intents
    
    /// Handle widget tap intent
    func handleWidgetTap(with url: URL) {
        // Parse widget deep link and post notification for app to handle
        NotificationCenter.default.post(
            name: .widgetTapped,
            object: nil,
            userInfo: ["url": url]
        )
    }
    
    /// Handle widget action intent
    func handleWidgetAction(_ action: WidgetAction) {
        switch action {
        case .startStudySession:
            NotificationCenter.default.post(name: .widgetStartStudySession, object: nil)
        case .continueLesson:
            NotificationCenter.default.post(name: .widgetContinueLesson, object: nil)
        case .viewProgress:
            NotificationCenter.default.post(name: .widgetViewProgress, object: nil)
        case .viewAchievements:
            NotificationCenter.default.post(name: .widgetViewAchievements, object: nil)
        }
    }
}

// MARK: - Widget Actions
enum WidgetAction: String, CaseIterable {
    case startStudySession = "start_study_session"
    case continueLesson = "continue_lesson"
    case viewProgress = "view_progress"
    case viewAchievements = "view_achievements"
    
    var title: String {
        switch self {
        case .startStudySession: return "Start Studying"
        case .continueLesson: return "Continue Lesson"
        case .viewProgress: return "View Progress"
        case .viewAchievements: return "View Achievements"
        }
    }
    
    var systemImage: String {
        switch self {
        case .startStudySession: return "play.circle.fill"
        case .continueLesson: return "arrow.right.circle.fill"
        case .viewProgress: return "chart.line.uptrend.xyaxis"
        case .viewAchievements: return "trophy.fill"
        }
    }
    
    var deepLinkURL: URL? {
        return URL(string: "lyoapp://widget/\(rawValue)")
    }
}

// MARK: - Notification Names for Widget
extension Notification.Name {
    static let widgetTapped = Notification.Name("widgetTapped")
    static let widgetStartStudySession = Notification.Name("widgetStartStudySession")
    static let widgetContinueLesson = Notification.Name("widgetContinueLesson")
    static let widgetViewProgress = Notification.Name("widgetViewProgress")
    static let widgetViewAchievements = Notification.Name("widgetViewAchievements")
}

// MARK: - Enhanced Core Data Manager Extensions for Widget
extension EnhancedCoreDataManager {
    
    func getCurrentStreak() async -> Int {
        // Implementation for getting current streak
        return 5 // Placeholder
    }
    
    func getTotalCompletedLessons() async -> Int {
        // Implementation for getting total completed lessons
        return 23 // Placeholder
    }
    
    func getWeeklyGoalProgress() async -> Double {
        // Implementation for getting weekly goal progress
        return 0.7 // Placeholder
    }
    
    func getNextLesson() async -> (title: String, progress: Double)? {
        // Implementation for getting next lesson
        return ("Advanced Swift", 0.2) // Placeholder
    }
    
    func getRecentAchievements() async -> [(id: String, title: String, imageName: String, isRecent: Bool, earnedDate: Date)] {
        // Implementation for getting recent achievements
        return [
            ("streak_7", "Week Warrior", "flame.fill", true, Date().addingTimeInterval(-3600))
        ] // Placeholder
    }
    
    func getTodayStudyTime() async -> TimeInterval {
        // Implementation for getting today's study time
        return 1800 // 30 minutes placeholder
    }
    
    func getWeeklyStudyTime() async -> TimeInterval {
        // Implementation for getting weekly study time
        return 7200 // 2 hours placeholder
    }
    
    func getLastStudyDate() async -> Date? {
        // Implementation for getting last study date
        return Date().addingTimeInterval(-7200) // 2 hours ago placeholder
    }
    
    func getActiveCourses(limit: Int) async -> [(id: String, title: String, progress: Double, nextLessonTitle: String?, totalLessons: Int, completedLessons: Int, lastAccessed: Date?)] {
        // Implementation for getting active courses
        return [
            ("swift-basics", "Swift Basics", 0.6, "Functions", 20, 12, Date().addingTimeInterval(-3600)),
            ("ui-design", "UI Design", 0.3, "Color Theory", 15, 4, Date().addingTimeInterval(-86400))
        ] // Placeholder
    }
}
