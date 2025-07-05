//
//  BackgroundTaskManager.swift
//  LyoApp
//
//  Background processing for content sync, analytics, and maintenance
//

import Foundation
import BackgroundTasks
import UIKit

// MARK: - Background Task Types
enum BackgroundTaskType: String, CaseIterable {
    case contentSync = "com.lyoapp.content-sync"
    case analyticsUpload = "com.lyoapp.analytics-upload"
    case dataMaintenance = "com.lyoapp.data-maintenance"
    case notificationPrep = "com.lyoapp.notification-prep"
    case offlineContentDownload = "com.lyoapp.offline-download"
    
    var identifier: String {
        return rawValue
    }
    
    var displayName: String {
        switch self {
        case .contentSync: return "Content Sync"
        case .analyticsUpload: return "Analytics Upload"
        case .dataMaintenance: return "Data Maintenance"
        case .notificationPrep: return "Notification Preparation"
        case .offlineContentDownload: return "Offline Content Download"
        }
    }
    
    var frequency: TimeInterval {
        switch self {
        case .contentSync: return 15 * 60 // 15 minutes
        case .analyticsUpload: return 30 * 60 // 30 minutes
        case .dataMaintenance: return 24 * 60 * 60 // 24 hours
        case .notificationPrep: return 60 * 60 // 1 hour
        case .offlineContentDownload: return 60 * 60 // 1 hour
        }
    }
    
    var requiresNetworkAccess: Bool {
        switch self {
        case .contentSync, .analyticsUpload, .offlineContentDownload:
            return true
        case .dataMaintenance, .notificationPrep:
            return false
        }
    }
    
    var isProcessingTask: Bool {
        switch self {
        case .dataMaintenance, .offlineContentDownload:
            return true
        case .contentSync, .analyticsUpload, .notificationPrep:
            return false
        }
    }
}

// MARK: - Background Task Result
struct BackgroundTaskResult {
    let taskType: BackgroundTaskType
    let success: Bool
    let duration: TimeInterval
    let itemsProcessed: Int
    let error: Error?
    let completedAt: Date
    
    static func success(
        taskType: BackgroundTaskType,
        duration: TimeInterval,
        itemsProcessed: Int = 0
    ) -> BackgroundTaskResult {
        return BackgroundTaskResult(
            taskType: taskType,
            success: true,
            duration: duration,
            itemsProcessed: itemsProcessed,
            error: nil,
            completedAt: Date()
        )
    }
    
    static func failure(
        taskType: BackgroundTaskType,
        duration: TimeInterval,
        error: Error
    ) -> BackgroundTaskResult {
        return BackgroundTaskResult(
            taskType: taskType,
            success: false,
            duration: duration,
            itemsProcessed: 0,
            error: error,
            completedAt: Date()
        )
    }
}

// MARK: - Background Task Manager
@MainActor
class BackgroundTaskManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var activeTasks: Set<BackgroundTaskType> = []
    @Published var lastExecutionDates: [BackgroundTaskType: Date] = [:]
    @Published var taskResults: [BackgroundTaskResult] = []
    @Published var isBackgroundRefreshEnabled: Bool = false
    
    // MARK: - Private Properties
    private var backgroundTasks: [BackgroundTaskType: BGTask] = [:]
    private let maxResultsToKeep = 50
    
    // MARK: - Dependencies
    private let coreDataManager: DataManager
    private let networkManager: EnhancedNetworkManager
    private let notificationManager: NotificationManager
    private let spotlightManager: SpotlightManager
    
    // MARK: - User Defaults Keys
    private enum UserDefaultsKeys {
        static let lastExecutionPrefix = "bg_task_last_execution_"
        static let backgroundRefreshEnabled = "background_refresh_enabled"
    }
    
    // MARK: - Initialization
    init(
        coreDataManager: DataManager,
        networkManager: EnhancedNetworkManager,
        notificationManager: NotificationManager,
        spotlightManager: SpotlightManager
    ) {
        self.coreDataManager = coreDataManager
        self.networkManager = networkManager
        self.notificationManager = notificationManager
        self.spotlightManager = spotlightManager
        
        loadConfiguration()
        registerBackgroundTasks()
        setupAppLifecycleObservers()
    }
    
    // MARK: - Setup
    
    private func loadConfiguration() {
        isBackgroundRefreshEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.backgroundRefreshEnabled)
        
        // Load last execution dates
        for taskType in BackgroundTaskType.allCases {
            let key = UserDefaultsKeys.lastExecutionPrefix + taskType.rawValue
            if let date = UserDefaults.standard.object(forKey: key) as? Date {
                lastExecutionDates[taskType] = date
            }
        }
    }
    
    private func registerBackgroundTasks() {
        for taskType in BackgroundTaskType.allCases {
            let success = BGTaskScheduler.shared.register(
                forTaskWithIdentifier: taskType.identifier,
                using: nil
            ) { task in
                Task { @MainActor in
                    await self.handleBackgroundTask(task, type: taskType)
                }
            }
            
            if success {
                print("✅ Registered background task: \(taskType.displayName)")
            } else {
                print("❌ Failed to register background task: \(taskType.displayName)")
            }
        }
    }
    
    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                await self.scheduleBackgroundTasks()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                self.cancelAllBackgroundTasks()
            }
        }
    }
    
    // MARK: - Background Task Management
    
    /// Schedule all background tasks
    func scheduleBackgroundTasks() async {
        guard isBackgroundRefreshEnabled else {
            print("⚠️ Background refresh is disabled")
            return
        }
        
        let backgroundRefreshStatus = await UIApplication.shared.backgroundRefreshStatus
        guard backgroundRefreshStatus == .available else {
            print("⚠️ Background refresh not available: \(backgroundRefreshStatus)")
            return
        }
        
        for taskType in BackgroundTaskType.allCases {
            await scheduleBackgroundTask(taskType)
        }
    }
    
    /// Schedule specific background task
    func scheduleBackgroundTask(_ taskType: BackgroundTaskType) async {
        // Cancel existing task if any
        BGTaskScheduler.shared.cancel(taskWithIdentifier: taskType.identifier)
        
        let request: BGTaskRequest
        
        if taskType.isProcessingTask {
            let processingRequest = BGProcessingTaskRequest(identifier: taskType.identifier)
            processingRequest.requiresNetworkConnectivity = taskType.requiresNetworkAccess
            processingRequest.requiresExternalPower = taskType == .offlineContentDownload
            request = processingRequest
        } else {
            let appRefreshRequest = BGAppRefreshTaskRequest(identifier: taskType.identifier)
            request = appRefreshRequest
        }
        
        // Schedule for next execution
        let nextExecutionTime = calculateNextExecutionTime(for: taskType)
        request.earliestBeginDate = nextExecutionTime
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Scheduled \(taskType.displayName) for \(nextExecutionTime)")
        } catch {
            print("❌ Failed to schedule \(taskType.displayName): \(error)")
        }
    }
    
    /// Cancel all background tasks
    func cancelAllBackgroundTasks() {
        for taskType in BackgroundTaskType.allCases {
            BGTaskScheduler.shared.cancel(taskWithIdentifier: taskType.identifier)
        }
        print("🚫 Cancelled all background tasks")
    }
    
    /// Handle background task execution
    private func handleBackgroundTask(_ task: BGTask, type: BackgroundTaskType) async {
        let startTime = Date()
        activeTasks.insert(type)
        
        // Set expiration handler
        task.expirationHandler = {
            Task { @MainActor in
                self.activeTasks.remove(type)
                task.setTaskCompleted(success: false)
            }
        }
        
        do {
            let result = await executeBackgroundTask(type)
            
            // Record result
            taskResults.append(result)
            lastExecutionDates[type] = result.completedAt
            saveLastExecutionDate(for: type, date: result.completedAt)
            
            // Limit stored results
            if taskResults.count > maxResultsToKeep {
                taskResults.removeFirst(taskResults.count - maxResultsToKeep)
            }
            
            // Mark task as completed
            task.setTaskCompleted(success: result.success)
            
            print("✅ Completed background task: \(type.displayName) in \(result.duration)s")
            
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            let result = BackgroundTaskResult.failure(
                taskType: type,
                duration: duration,
                error: error
            )
            
            taskResults.append(result)
            task.setTaskCompleted(success: false)
            
            print("❌ Failed background task: \(type.displayName): \(error)")
        }
        
        activeTasks.remove(type)
        
        // Schedule next execution
        await scheduleBackgroundTask(type)
    }
    
    // MARK: - Task Execution
    
    private func executeBackgroundTask(_ taskType: BackgroundTaskType) async -> BackgroundTaskResult {
        let startTime = Date()
        
        do {
            let itemsProcessed: Int
            
            switch taskType {
            case .contentSync:
                itemsProcessed = await performContentSync()
            case .analyticsUpload:
                itemsProcessed = await performAnalyticsUpload()
            case .dataMaintenance:
                itemsProcessed = await performDataMaintenance()
            case .notificationPrep:
                itemsProcessed = await performNotificationPreparation()
            case .offlineContentDownload:
                itemsProcessed = await performOfflineContentDownload()
            }
            
            let duration = Date().timeIntervalSince(startTime)
            return .success(
                taskType: taskType,
                duration: duration,
                itemsProcessed: itemsProcessed
            )
            
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            return .failure(
                taskType: taskType,
                duration: duration,
                error: error
            )
        }
    }
    
    // MARK: - Specific Task Implementations
    
    private func performContentSync() async -> Int {
        print("🔄 Starting content sync...")
        
        // Sync user progress
        let progressSynced = await coreDataManager.syncUserProgress()
        
        // Sync course updates
        let courseUpdates = await coreDataManager.syncCDCourseUpdates()
        
        // Update Spotlight index
        await spotlightManager.indexAllContent()
        
        return progressSynced + courseUpdates
    }
    
    private func performAnalyticsUpload() async -> Int {
        print("📊 Starting analytics upload...")
        
        // Upload pending analytics events
        let eventsUploaded = await coreDataManager.uploadPendingAnalytics()
        
        // Clean up old analytics data
        await coreDataManager.cleanupOldAnalytics()
        
        return eventsUploaded
    }
    
    private func performDataMaintenance() async -> Int {
        print("🧹 Starting data maintenance...")
        
        var itemsProcessed = 0
        
        // Clean up temporary files
        itemsProcessed += await cleanupTemporaryFiles()
        
        // Compress old logs
        itemsProcessed += await compressOldLogs()
        
        // Optimize Core Data
        await coreDataManager.optimizeDatabase()
        itemsProcessed += 1
        
        // Clear expired cache
        itemsProcessed += await clearExpiredCache()
        
        return itemsProcessed
    }
    
    private func performNotificationPreparation() async -> Int {
        print("🔔 Starting notification preparation...")
        
        var itemsProcessed = 0
        
        // Schedule daily study reminders
        let studyReminders = await scheduleStudyReminders()
        itemsProcessed += studyReminders
        
        // Check for streak reminders
        let streakReminders = await checkStreakReminders()
        itemsProcessed += streakReminders
        
        // Prepare course completion notifications
        let completionNotifications = await prepareCDCourseCompletionNotifications()
        itemsProcessed += completionNotifications
        
        return itemsProcessed
    }
    
    private func performOfflineContentDownload() async -> Int {
        print("⬇️ Starting offline content download...")
        
        // Download priority content for offline access
        let downloadedItems = await coreDataManager.downloadOfflineContent()
        
        // Update offline content index
        await coreDataManager.updateOfflineIndex()
        
        return downloadedItems
    }
    
    // MARK: - Helper Methods
    
    private func calculateNextExecutionTime(for taskType: BackgroundTaskType) -> Date {
        let lastExecution = lastExecutionDates[taskType] ?? Date.distantPast
        let nextExecution = lastExecution.addingTimeInterval(taskType.frequency)
        let earliestNext = Date().addingTimeInterval(60) // At least 1 minute from now
        
        return max(nextExecution, earliestNext)
    }
    
    private func saveLastExecutionDate(for taskType: BackgroundTaskType, date: Date) {
        let key = UserDefaultsKeys.lastExecutionPrefix + taskType.rawValue
        UserDefaults.standard.set(date, forKey: key)
    }
    
    // MARK: - Maintenance Tasks
    
    private func cleanupTemporaryFiles() async -> Int {
        let tempDirectory = FileManager.default.temporaryDirectory
        var itemsProcessed = 0
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: tempDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            
            let cutoffDate = Date().addingTimeInterval(-24 * 60 * 60) // 24 hours ago
            
            for fileURL in contents {
                if let creationDate = try fileURL.resourceValues(forKeys: [.creationDateKey]).creationDate,
                   creationDate < cutoffDate {
                    try FileManager.default.removeItem(at: fileURL)
                    itemsProcessed += 1
                }
            }
        } catch {
            print("❌ Failed to cleanup temporary files: \(error)")
        }
        
        return itemsProcessed
    }
    
    private func compressOldLogs() async -> Int {
        // Implementation for log compression
        return 0
    }
    
    private func clearExpiredCache() async -> Int {
        // Implementation for cache cleanup
        return 0
    }
    
    // MARK: - Notification Tasks
    
    private func scheduleStudyReminders() async -> Int {
        // Get user's preferred study times
        let studyTimes = notificationManager.settings.studyReminderTimes
        var scheduled = 0
        
        for studyTime in studyTimes {
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: studyTime) ?? studyTime
            await notificationManager.scheduleStudyReminder(
                courseName: "your courses",
                time: tomorrow
            )
            scheduled += 1
        }
        
        return scheduled
    }
    
    private func checkStreakReminders() async -> Int {
        // Check if user needs streak reminder
        let currentStreak = await coreDataManager.getCurrentStreak()
        
        if currentStreak > 0 {
            await notificationManager.scheduleStreakReminder(streakCount: currentStreak)
            return 1
        }
        
        return 0
    }
    
    private func prepareCDCourseCompletionNotifications() async -> Int {
        // Check for courses near completion
        let nearCompletionCDCourses = await coreDataManager.getCDCoursesNearCompletion()
        
        for course in nearCompletionCDCourses {
            // Schedule encouragement notification
            let content = NotificationContent(
                type: .courseUpdate,
                title: "Almost There! 🎯",
                body: "You're \(Int((1.0 - course.progress) * 100))% away from completing \(course.title)!",
                userInfo: ["course_id": course.id, "course_name": course.title]
            )
            
            await notificationManager.scheduleNotification(
                content: content,
                schedule: .timeInterval(3600) // 1 hour from now
            )
        }
        
        return nearCompletionCDCourses.count
    }
    
    // MARK: - Settings
    
    func enableBackgroundRefresh(_ enabled: Bool) {
        isBackgroundRefreshEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: UserDefaultsKeys.backgroundRefreshEnabled)
        
        if enabled {
            Task {
                await scheduleBackgroundTasks()
            }
        } else {
            cancelAllBackgroundTasks()
        }
    }
}

// MARK: - Extensions for Data Types
extension BackgroundTaskManager {
    
    struct CDCourse {
        let id: String
        let title: String
        let progress: Double
    }
}

// MARK: - DataManager Extension
extension DataManager {
    
    func syncUserProgress() async -> Int {
        // Implementation for syncing user progress
        return 0
    }
    
    func syncCDCourseUpdates() async -> Int {
        // Implementation for syncing course updates
        return 0
    }
    
    func uploadPendingAnalytics() async -> Int {
        // Implementation for uploading analytics
        return 0
    }
    
    func cleanupOldAnalytics() async {
        // Implementation for cleaning up old analytics
    }
    
    func optimizeDatabase() async {
        // Implementation for database optimization
    }
    
    func downloadOfflineContent() async -> Int {
        // Implementation for downloading offline content
        return 0
    }
    
    func updateOfflineIndex() async {
        // Implementation for updating offline index
    }
    
    func getCurrentStreak() async -> Int {
        // Implementation for getting current streak
        return 0
    }
    
    func getCDCoursesNearCompletion() async -> [BackgroundTaskManager.CDCourse] {
        // Implementation for getting courses near completion
        return []
    }
}
