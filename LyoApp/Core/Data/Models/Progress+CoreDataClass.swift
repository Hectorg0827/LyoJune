//
//  Progress+CoreDataClass.swift
//  LyoApp
//
//  Created by LyoApp Development Team on 12/25/24.
//  Copyright © 2024 LyoApp. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

@objc(Progress)
public class Progress: NSManagedObject {
    
    // MARK: - Enums
    
    enum ProgressStatus: String, CaseIterable, Codable {
        case notStarted = "not_started"
        case inProgress = "in_progress"
        case completed = "completed"
        case paused = "paused"
        case failed = "failed"
        
        var displayName: String {
            switch self {
            case .notStarted: return "Not Started"
            case .inProgress: return "In Progress"
            case .completed: return "Completed"
            case .paused: return "Paused"
            case .failed: return "Failed"
            }
        }
        
        var emoji: String {
            switch self {
            case .notStarted: return "⏸️"
            case .inProgress: return "🔄"
            case .completed: return "✅"
            case .paused: return "⏸️"
            case .failed: return "❌"
            }
        }
    }
    
    enum StudyMode: String, CaseIterable, Codable {
        case focused = "focused"
        case casual = "casual"
        case review = "review"
        case exam = "exam"
        
        var displayName: String {
            switch self {
            case .focused: return "Focused Study"
            case .casual: return "Casual Learning"
            case .review: return "Review Mode"
            case .exam: return "Exam Preparation"
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Progress status as enum
    var statusEnum: ProgressStatus {
        get {
            if isCompleted {
                return .completed
            } else if isPaused {
                return .paused
            } else if completionPercentage > 0 {
                return .inProgress
            } else {
                return .notStarted
            }
        }
    }
    
    /// Study mode as enum
    var studyModeEnum: StudyMode {
        get { StudyMode(rawValue: studyMode ?? "") ?? .casual }
        set { studyMode = newValue.rawValue }
    }
    
    /// Time spent formatted as string
    var formattedTimeSpent: String {
        let hours = Int(timeSpent) / 3600
        let minutes = Int(timeSpent) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Progress percentage as formatted string
    var formattedProgress: String {
        return String(format: "%.1f%%", completionPercentage)
    }
    
    /// Check if progress is active (accessed recently)
    var isActive: Bool {
        guard let lastAccessed = lastAccessed else { return false }
        let daysSinceAccess = Calendar.current.dateComponents([.day], 
                                                            from: lastAccessed, 
                                                            to: Date()).day ?? 0
        return daysSinceAccess <= 7
    }
    
    /// Check if progress is stale (not accessed in a while)
    var isStale: Bool {
        guard let lastAccessed = lastAccessed else { return true }
        let daysSinceAccess = Calendar.current.dateComponents([.day], 
                                                            from: lastAccessed, 
                                                            to: Date()).day ?? 0
        return daysSinceAccess > 30
    }
    
    /// Current study streak for this item
    var currentStreak: Int {
        return Int(streakCount)
    }
    
    /// Estimated time to complete
    var estimatedTimeToComplete: TimeInterval {
        guard let lesson = lesson else {
            guard let course = course else { return 0 }
            let remainingProgress = 100.0 - completionPercentage
            let estimatedTotal = course.totalDuration
            return estimatedTotal * (remainingProgress / 100.0)
        }
        
        let remainingProgress = 100.0 - completionPercentage
        return lesson.duration * (remainingProgress / 100.0)
    }
    
    /// Points earned from this progress
    var pointsEarned: Int {
        if isCompleted {
            let basePoints = lesson?.pointsReward ?? (course?.difficultyEnum.points ?? 10)
            let bonusMultiplier = score > 90 ? 1.5 : score > 80 ? 1.2 : 1.0
            return Int(Double(basePoints) * bonusMultiplier)
        }
        return 0
    }
    
    // MARK: - CloudKit Integration
    
    var cloudKitRecord: CKRecord? {
        get {
            guard let recordData = cloudKitRecordData else { return nil }
            return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKRecord.self, from: recordData)
        }
        set {
            cloudKitRecordData = newValue.flatMap { 
                try? NSKeyedArchiver.archivedData(withRootObject: $0, requiringSecureCoding: true) 
            }
            cloudKitRecordID = newValue?.recordID.recordName
        }
    }
    
    var needsCloudKitSync: Bool {
        return cloudKitSyncDate == nil || 
               (lastModified != nil && lastModified! > cloudKitSyncDate!)
    }
    
    // MARK: - Progress Management
    
    /// Update progress percentage
    func updateProgress(_ percentage: Double) {
        let newPercentage = min(100.0, max(0.0, percentage))
        let previousPercentage = completionPercentage
        
        completionPercentage = newPercentage
        lastAccessed = Date()
        lastModified = Date()
        
        // Mark as completed if reaching 100%
        if newPercentage >= 100.0 && !isCompleted {
            markAsCompleted()
        }
        
        // Update milestones
        updateMilestones(from: previousPercentage, to: newPercentage)
        
        // Track significant progress jumps
        if newPercentage - previousPercentage >= 25.0 {
            recordMilestone(percentage: newPercentage)
        }
    }
    
    /// Mark progress as completed
    func markAsCompleted(withScore score: Double? = nil) {
        isCompleted = true
        completionPercentage = 100.0
        completedAt = Date()
        lastAccessed = Date()
        lastModified = Date()
        
        if let score = score {
            self.score = score
        }
        
        // Update streak
        updateStreak()
        
        // Award points to user
        if let user = user {
            user.totalPointsEarned += Int32(pointsEarned)
        }
        
        // Create achievement if applicable
        checkForAchievements()
    }
    
    /// Add time spent studying
    func addTimeSpent(_ duration: TimeInterval) {
        timeSpent += duration
        lastAccessed = Date()
        lastModified = Date()
        
        // Update session data
        sessionsCount += 1
        if duration > longestSession {
            longestSession = duration
        }
        
        // Update average session length
        averageSessionDuration = timeSpent / Double(sessionsCount)
    }
    
    /// Pause progress
    func pause() {
        isPaused = true
        pausedAt = Date()
        lastModified = Date()
    }
    
    /// Resume progress
    func resume() {
        isPaused = false
        
        // Add to total pause time if was paused
        if let pausedDate = pausedAt {
            totalPauseTime += Date().timeIntervalSince(pausedDate)
        }
        
        pausedAt = nil
        lastAccessed = Date()
        lastModified = Date()
    }
    
    /// Reset progress
    func reset() {
        isCompleted = false
        completionPercentage = 0.0
        timeSpent = 0
        score = 0
        attemptsCount = 0
        streakCount = 0
        sessionsCount = 0
        totalPauseTime = 0
        averageSessionDuration = 0
        longestSession = 0
        isPaused = false
        
        completedAt = nil
        pausedAt = nil
        lastMilestoneAt = nil
        
        lastAccessed = Date()
        lastModified = Date()
    }
    
    // MARK: - Milestone Tracking
    
    private func updateMilestones(from previousPercentage: Double, to newPercentage: Double) {
        let milestones = [25.0, 50.0, 75.0, 100.0]
        
        for milestone in milestones {
            if previousPercentage < milestone && newPercentage >= milestone {
                recordMilestone(percentage: milestone)
            }
        }
    }
    
    private func recordMilestone(percentage: Double) {
        lastMilestoneAt = Date()
        
        // Store milestone data
        var milestones = getMilestones()
        milestones.append(ProgressMilestone(
            percentage: percentage,
            achievedAt: Date(),
            timeSpent: timeSpent
        ))
        setMilestones(milestones)
    }
    
    private func getMilestones() -> [ProgressMilestone] {
        guard let data = milestonesData else { return [] }
        return (try? JSONDecoder().decode([ProgressMilestone].self, from: data)) ?? []
    }
    
    private func setMilestones(_ milestones: [ProgressMilestone]) {
        milestonesData = try? JSONEncoder().encode(milestones)
    }
    
    // MARK: - Streak Management
    
    private func updateStreak() {
        guard let lastAccessed = lastAccessed else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastAccessDay = calendar.startOfDay(for: lastAccessed)
        
        let daysDifference = calendar.dateComponents([.day], 
                                                   from: lastAccessDay, 
                                                   to: today).day ?? 0
        
        if daysDifference == 0 {
            // Same day - maintain streak
            return
        } else if daysDifference == 1 {
            // Next day - extend streak
            streakCount += 1
        } else {
            // Gap - reset streak
            streakCount = 1
        }
    }
    
    // MARK: - Achievement Checking
    
    private func checkForAchievements() {
        guard let user = user else { return }
        
        // Check for completion-based achievements
        if isCompleted {
            checkCompletionAchievements(for: user)
        }
        
        // Check for score-based achievements
        if score >= 95 {
            checkScoreAchievements(for: user)
        }
        
        // Check for time-based achievements
        checkTimeAchievements(for: user)
        
        // Check for streak-based achievements
        if streakCount >= 7 {
            checkStreakAchievements(for: user)
        }
    }
    
    private func checkCompletionAchievements(for user: User) {
        // Implementation would check and award completion-based achievements
        // This is a placeholder for the achievement system
    }
    
    private func checkScoreAchievements(for user: User) {
        // Implementation would check and award score-based achievements
        // This is a placeholder for the achievement system
    }
    
    private func checkTimeAchievements(for user: User) {
        // Implementation would check and award time-based achievements
        // This is a placeholder for the achievement system
    }
    
    private func checkStreakAchievements(for user: User) {
        // Implementation would check and award streak-based achievements
        // This is a placeholder for the achievement system
    }
    
    // MARK: - Analytics & Insights
    
    /// Get study pattern analysis
    func getStudyPatternAnalysis() -> StudyPatternAnalysis {
        let efficiency = timeSpent > 0 ? completionPercentage / (timeSpent / 60.0) : 0
        let consistency = calculateConsistency()
        let engagement = calculateEngagement()
        
        return StudyPatternAnalysis(
            efficiency: efficiency,
            consistency: consistency,
            engagement: engagement,
            preferredStudyTimes: getPreferredStudyTimes(),
            averageSessionLength: averageSessionDuration,
            totalSessions: Int(sessionsCount)
        )
    }
    
    private func calculateConsistency() -> Double {
        // Implementation would analyze access patterns
        // This is a simplified calculation
        guard sessionsCount > 0 else { return 0 }
        
        let expectedSessions = max(1, Int(timeSpent / 1800)) // 30-minute sessions
        return min(1.0, Double(sessionsCount) / Double(expectedSessions))
    }
    
    private func calculateEngagement() -> Double {
        // Implementation would analyze engagement metrics
        // This is a simplified calculation
        let timeEfficiency = timeSpent > 0 ? completionPercentage / (timeSpent / 60.0) : 0
        let sessionConsistency = averageSessionDuration > 300 ? 1.0 : averageSessionDuration / 300.0
        
        return (timeEfficiency + sessionConsistency) / 2.0
    }
    
    private func getPreferredStudyTimes() -> [Int] {
        // Implementation would analyze when user typically studies
        // This is a placeholder returning common study hours
        return [9, 14, 19, 21] // 9 AM, 2 PM, 7 PM, 9 PM
    }
    
    // MARK: - Data Validation
    
    func validateProgressData() throws {
        guard completionPercentage >= 0 && completionPercentage <= 100 else {
            throw ProgressValidationError.invalidCompletionPercentage
        }
        
        guard timeSpent >= 0 else {
            throw ProgressValidationError.invalidTimeSpent
        }
        
        guard score >= 0 && score <= 100 else {
            throw ProgressValidationError.invalidScore
        }
        
        guard attemptsCount >= 0 else {
            throw ProgressValidationError.invalidAttemptsCount
        }
        
        if isCompleted && completionPercentage < 100 {
            throw ProgressValidationError.inconsistentCompletionState
        }
    }
    
    // MARK: - Lifecycle Methods
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        id = UUID()
        createdAt = Date()
        lastModified = Date()
        enrolledAt = Date()
        
        // Initialize default values
        completionPercentage = 0.0
        timeSpent = 0
        score = 0
        attemptsCount = 0
        streakCount = 0
        sessionsCount = 0
        totalPauseTime = 0
        averageSessionDuration = 0
        longestSession = 0
        
        isCompleted = false
        isPaused = false
        studyMode = StudyMode.casual.rawValue
    }
    
    public override func willSave() {
        super.willSave()
        
        if hasChanges && !isInserted {
            lastModified = Date()
        }
        
        do {
            try validateProgressData()
        } catch {
            print("Progress validation failed: \(error)")
        }
    }
}

// MARK: - Supporting Data Structures

struct ProgressMilestone: Codable {
    let percentage: Double
    let achievedAt: Date
    let timeSpent: TimeInterval
}

struct StudyPatternAnalysis {
    let efficiency: Double
    let consistency: Double
    let engagement: Double
    let preferredStudyTimes: [Int]
    let averageSessionLength: TimeInterval
    let totalSessions: Int
}

// MARK: - Custom Errors

enum ProgressValidationError: Error, LocalizedError {
    case invalidCompletionPercentage
    case invalidTimeSpent
    case invalidScore
    case invalidAttemptsCount
    case inconsistentCompletionState
    
    var errorDescription: String? {
        switch self {
        case .invalidCompletionPercentage:
            return "Completion percentage must be between 0 and 100."
        case .invalidTimeSpent:
            return "Time spent cannot be negative."
        case .invalidScore:
            return "Score must be between 0 and 100."
        case .invalidAttemptsCount:
            return "Attempts count cannot be negative."
        case .inconsistentCompletionState:
            return "Completed progress must have 100% completion."
        }
    }
}

// MARK: - Core Data Generated Properties

extension Progress {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Progress> {
        return NSFetchRequest<Progress>(entityName: "Progress")
    }
    
    // Basic Properties
    @NSManaged public var id: UUID?
    @NSManaged public var completionPercentage: Double
    @NSManaged public var timeSpent: TimeInterval
    @NSManaged public var score: Double
    @NSManaged public var attemptsCount: Int32
    @NSManaged public var studyMode: String?
    
    // Status
    @NSManaged public var isCompleted: Bool
    @NSManaged public var isPaused: Bool
    
    // Timestamps
    @NSManaged public var createdAt: Date?
    @NSManaged public var lastModified: Date?
    @NSManaged public var enrolledAt: Date?
    @NSManaged public var lastAccessed: Date?
    @NSManaged public var completedAt: Date?
    @NSManaged public var pausedAt: Date?
    @NSManaged public var lastMilestoneAt: Date?
    
    // Analytics
    @NSManaged public var streakCount: Int32
    @NSManaged public var sessionsCount: Int32
    @NSManaged public var totalPauseTime: TimeInterval
    @NSManaged public var averageSessionDuration: TimeInterval
    @NSManaged public var longestSession: TimeInterval
    
    // Data Storage
    @NSManaged public var milestonesData: Data?
    @NSManaged public var notesData: Data?
    
    // CloudKit
    @NSManaged public var cloudKitRecordData: Data?
    @NSManaged public var cloudKitRecordID: String?
    @NSManaged public var cloudKitSyncDate: Date?
    
    // Relationships
    @NSManaged public var user: User?
    @NSManaged public var course: Course?
    @NSManaged public var lesson: Lesson?
}

// MARK: - Identifiable Conformance

extension Progress: Identifiable {
    // Uses the inherited id property from NSManagedObject
}
