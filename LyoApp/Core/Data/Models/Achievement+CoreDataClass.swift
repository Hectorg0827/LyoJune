//
//  Achievement+CoreDataClass.swift
//  LyoApp
//
//  Created by LyoApp Development Team on 12/25/24.
//  Copyright © 2024 LyoApp. All rights reserved.
//

import Foundation
import CoreData
import CloudKit
import SwiftUI

@objc(Achievement)
public class Achievement: NSManagedObject {
    
    // MARK: - Enums
    
    enum AchievementCategory: String, CaseIterable, Codable {
        case learning = "learning"
        case progress = "progress"
        case streak = "streak"
        case social = "social"
        case milestone = "milestone"
        case special = "special"
        case seasonal = "seasonal"
        case expert = "expert"
        
        var displayName: String {
            switch self {
            case .learning: return "Learning"
            case .progress: return "Progress"
            case .streak: return "Streak"
            case .social: return "Social"
            case .milestone: return "Milestone"
            case .special: return "Special"
            case .seasonal: return "Seasonal"
            case .expert: return "Expert"
            }
        }
        
        var color: Color {
            switch self {
            case .learning: return .blue
            case .progress: return .green
            case .streak: return .orange
            case .social: return .purple
            case .milestone: return .yellow
            case .special: return .pink
            case .seasonal: return .mint
            case .expert: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .learning: return "brain.head.profile"
            case .progress: return "chart.line.uptrend.xyaxis"
            case .streak: return "flame"
            case .social: return "person.2"
            case .milestone: return "flag.checkered"
            case .special: return "star"
            case .seasonal: return "calendar"
            case .expert: return "crown"
            }
        }
    }
    
    enum AchievementTier: String, CaseIterable, Codable {
        case bronze = "bronze"
        case silver = "silver"
        case gold = "gold"
        case platinum = "platinum"
        case diamond = "diamond"
        
        var displayName: String {
            rawValue.capitalized
        }
        
        var color: Color {
            switch self {
            case .bronze: return .brown
            case .silver: return .gray
            case .gold: return .yellow
            case .platinum: return .blue
            case .diamond: return .purple
            }
        }
        
        var pointsMultiplier: Double {
            switch self {
            case .bronze: return 1.0
            case .silver: return 1.5
            case .gold: return 2.0
            case .platinum: return 3.0
            case .diamond: return 5.0
            }
        }
    }
    
    enum AchievementRarity: String, CaseIterable, Codable {
        case common = "common"
        case uncommon = "uncommon"
        case rare = "rare"
        case epic = "epic"
        case legendary = "legendary"
        
        var displayName: String {
            rawValue.capitalized
        }
        
        var color: Color {
            switch self {
            case .common: return .gray
            case .uncommon: return .green
            case .rare: return .blue
            case .epic: return .purple
            case .legendary: return .orange
            }
        }
        
        var dropRate: Double {
            switch self {
            case .common: return 0.50
            case .uncommon: return 0.30
            case .rare: return 0.15
            case .epic: return 0.04
            case .legendary: return 0.01
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Achievement category as enum
    var categoryEnum: AchievementCategory {
        get { AchievementCategory(rawValue: category ?? "") ?? .learning }
        set { category = newValue.rawValue }
    }
    
    /// Achievement tier as enum
    var tierEnum: AchievementTier {
        get { AchievementTier(rawValue: tier ?? "") ?? .bronze }
        set { tier = newValue.rawValue }
    }
    
    /// Achievement rarity as enum
    var rarityEnum: AchievementRarity {
        get { AchievementRarity(rawValue: rarity ?? "") ?? .common }
        set { rarity = newValue.rawValue }
    }
    
    /// Check if achievement is unlocked
    var isUnlocked: Bool {
        return unlockedAt != nil
    }
    
    /// Check if achievement is hidden (should not be shown until unlocked)
    var isHidden: Bool {
        return isSecret && !isUnlocked
    }
    
    /// Time since achievement was unlocked
    var timeSinceUnlocked: TimeInterval? {
        guard let unlockedDate = unlockedAt else { return nil }
        return Date().timeIntervalSince(unlockedDate)
    }
    
    /// Achievement icon with tier overlay
    var tieredIcon: String {
        if isUnlocked {
            return iconName ?? categoryEnum.icon
        } else {
            return "lock"
        }
    }
    
    /// Total points value including tier multiplier
    var totalPoints: Int {
        return Int(Double(basePoints) * tierEnum.pointsMultiplier)
    }
    
    /// Progress towards achievement (0.0 to 1.0)
    var progressPercentage: Double {
        guard requiredValue > 0 else { return isUnlocked ? 1.0 : 0.0 }
        return min(1.0, Double(currentValue) / Double(requiredValue))
    }
    
    /// Formatted progress string
    var progressString: String {
        if isUnlocked {
            return "Completed"
        } else if requiredValue > 0 {
            return "\(currentValue)/\(requiredValue)"
        } else {
            return "0%"
        }
    }
    
    /// Check if achievement is close to completion (within 10%)
    var isNearCompletion: Bool {
        return !isUnlocked && progressPercentage >= 0.9
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
    
    // MARK: - Achievement Management
    
    /// Update progress towards achievement
    func updateProgress(_ newValue: Int32) {
        let oldValue = currentValue
        currentValue = newValue
        lastModified = Date()
        
        // Check if achievement should be unlocked
        if !isUnlocked && currentValue >= requiredValue {
            unlock()
        }
        
        // Trigger progress notification if significantly advanced
        if newValue > oldValue && Double(newValue - oldValue) / Double(requiredValue) >= 0.1 {
            notifyProgressUpdate()
        }
    }
    
    /// Increment achievement progress
    func incrementProgress(by amount: Int32 = 1) {
        updateProgress(currentValue + amount)
    }
    
    /// Unlock achievement
    func unlock() {
        guard !isUnlocked else { return }
        
        unlockedAt = Date()
        currentValue = requiredValue
        lastModified = Date()
        
        // Award points to user
        if let user = user {
            user.totalPointsEarned += Int32(totalPoints)
        }
        
        // Send unlock notification
        notifyUnlock()
        
        // Check for chain achievements
        checkChainedAchievements()
    }
    
    /// Force unlock achievement (for testing or special events)
    func forceUnlock() {
        unlockedAt = Date()
        currentValue = requiredValue
        lastModified = Date()
        
        if let user = user {
            user.totalPointsEarned += Int32(totalPoints)
        }
        
        notifyUnlock()
    }
    
    /// Reset achievement progress
    func reset() {
        currentValue = 0
        unlockedAt = nil
        lastModified = Date()
    }
    
    // MARK: - Notifications
    
    private func notifyProgressUpdate() {
        guard let user = user else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Achievement Progress!"
        content.body = "You're making progress on '\(title ?? "Unknown Achievement")' - \(progressString)"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "achievement_progress_\(id?.uuidString ?? "")",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func notifyUnlock() {
        guard let user = user else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🏆 Achievement Unlocked!"
        content.body = "\(title ?? "New Achievement") - \(achievementDescription ?? "")"
        content.sound = .default
        content.categoryIdentifier = "ACHIEVEMENT"
        
        // Add rich content if available
        if let iconName = iconName {
            // Implementation would add icon attachment
        }
        
        let request = UNNotificationRequest(
            identifier: "achievement_unlock_\(id?.uuidString ?? "")",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Achievement Chains
    
    private func checkChainedAchievements() {
        // Implementation would check for achievements that unlock after this one
        // This is a placeholder for the chain system
        
        guard let user = user else { return }
        
        // Example: Check if this unlocks other achievements
        if categoryEnum == .learning && tierEnum == .gold {
            // Unlock "Learning Master" achievement
        }
        
        if rarityEnum == .legendary {
            // Unlock "Legend" achievement
        }
    }
    
    // MARK: - Static Achievement Definitions
    
    /// Create predefined learning achievements
    static func createLearningAchievements(in context: NSManagedObjectContext) -> [Achievement] {
        var achievements: [Achievement] = []
        
        // First Lesson
        let firstLesson = Achievement(context: context)
        firstLesson.setupBasics(
            title: "First Steps",
            description: "Complete your first lesson",
            category: .learning,
            tier: .bronze,
            rarity: .common,
            requiredValue: 1,
            points: 10
        )
        achievements.append(firstLesson)
        
        // Course Completion
        let courseComplete = Achievement(context: context)
        courseComplete.setupBasics(
            title: "Course Conqueror",
            description: "Complete your first course",
            category: .milestone,
            tier: .silver,
            rarity: .uncommon,
            requiredValue: 1,
            points: 100
        )
        achievements.append(courseComplete)
        
        // Perfect Score
        let perfectScore = Achievement(context: context)
        perfectScore.setupBasics(
            title: "Perfectionist",
            description: "Score 100% on a quiz",
            category: .learning,
            tier: .gold,
            rarity: .rare,
            requiredValue: 1,
            points: 50
        )
        achievements.append(perfectScore)
        
        return achievements
    }
    
    /// Create predefined streak achievements
    static func createStreakAchievements(in context: NSManagedObjectContext) -> [Achievement] {
        var achievements: [Achievement] = []
        
        let streakData = [
            (days: 3, title: "Getting Started", tier: AchievementTier.bronze, rarity: AchievementRarity.common, points: 20),
            (days: 7, title: "Week Warrior", tier: AchievementTier.silver, rarity: AchievementRarity.uncommon, points: 50),
            (days: 30, title: "Monthly Master", tier: AchievementTier.gold, rarity: AchievementRarity.rare, points: 200),
            (days: 100, title: "Century Scholar", tier: AchievementTier.platinum, rarity: AchievementRarity.epic, points: 500),
            (days: 365, title: "Yearly Yogi", tier: AchievementTier.diamond, rarity: AchievementRarity.legendary, points: 1000)
        ]
        
        for (days, title, tier, rarity, points) in streakData {
            let achievement = Achievement(context: context)
            achievement.setupBasics(
                title: title,
                description: "Maintain a \(days)-day learning streak",
                category: .streak,
                tier: tier,
                rarity: rarity,
                requiredValue: Int32(days),
                points: Int32(points)
            )
            achievements.append(achievement)
        }
        
        return achievements
    }
    
    // MARK: - Helper Methods
    
    private func setupBasics(title: String,
                           description: String,
                           category: AchievementCategory,
                           tier: AchievementTier,
                           rarity: AchievementRarity,
                           requiredValue: Int32,
                           points: Int32) {
        self.id = UUID()
        self.title = title
        self.achievementDescription = description
        self.categoryEnum = category
        self.tierEnum = tier
        self.rarityEnum = rarity
        self.requiredValue = requiredValue
        self.basePoints = points
        self.currentValue = 0
        self.isSecret = false
        self.createdAt = Date()
        self.lastModified = Date()
    }
    
    // MARK: - Data Validation
    
    func validateAchievementData() throws {
        guard let title = title, !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AchievementValidationError.emptyTitle
        }
        
        guard requiredValue > 0 else {
            throw AchievementValidationError.invalidRequiredValue
        }
        
        guard basePoints >= 0 else {
            throw AchievementValidationError.invalidPoints
        }
        
        guard currentValue >= 0 else {
            throw AchievementValidationError.invalidCurrentValue
        }
        
        if isUnlocked && currentValue < requiredValue {
            throw AchievementValidationError.inconsistentUnlockState
        }
    }
    
    // MARK: - Lifecycle Methods
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        id = UUID()
        createdAt = Date()
        lastModified = Date()
        category = AchievementCategory.learning.rawValue
        tier = AchievementTier.bronze.rawValue
        rarity = AchievementRarity.common.rawValue
        currentValue = 0
        requiredValue = 1
        basePoints = 10
        isSecret = false
    }
    
    public override func willSave() {
        super.willSave()
        
        if hasChanges && !isInserted {
            lastModified = Date()
        }
        
        do {
            try validateAchievementData()
        } catch {
            print("Achievement validation failed: \(error)")
        }
    }
}

// MARK: - Custom Errors

enum AchievementValidationError: Error, LocalizedError {
    case emptyTitle
    case invalidRequiredValue
    case invalidPoints
    case invalidCurrentValue
    case inconsistentUnlockState
    
    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "Achievement title cannot be empty."
        case .invalidRequiredValue:
            return "Required value must be greater than 0."
        case .invalidPoints:
            return "Points cannot be negative."
        case .invalidCurrentValue:
            return "Current value cannot be negative."
        case .inconsistentUnlockState:
            return "Unlocked achievements must have reached required value."
        }
    }
}

// MARK: - Core Data Generated Properties

extension Achievement {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Achievement> {
        return NSFetchRequest<Achievement>(entityName: "Achievement")
    }
    
    // Basic Properties
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var achievementDescription: String?
    @NSManaged public var category: String?
    @NSManaged public var tier: String?
    @NSManaged public var rarity: String?
    @NSManaged public var iconName: String?
    @NSManaged public var imageName: String?
    
    // Progress
    @NSManaged public var currentValue: Int32
    @NSManaged public var requiredValue: Int32
    @NSManaged public var basePoints: Int32
    
    // Status
    @NSManaged public var isSecret: Bool
    @NSManaged public var unlockedAt: Date?
    
    // Timestamps
    @NSManaged public var createdAt: Date?
    @NSManaged public var lastModified: Date?
    
    // CloudKit
    @NSManaged public var cloudKitRecordData: Data?
    @NSManaged public var cloudKitRecordID: String?
    @NSManaged public var cloudKitSyncDate: Date?
    
    // Relationships
    @NSManaged public var user: User?
    @NSManaged public var course: Course?
}

// MARK: - Identifiable Conformance

extension Achievement: Identifiable {
    // Uses the inherited id property from NSManagedObject
}
