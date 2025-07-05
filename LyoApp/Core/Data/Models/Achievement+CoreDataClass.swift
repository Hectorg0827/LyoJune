//
//  CDAchievement+CoreDataClass.swift
//  LyoApp
//
//  Created by LyoApp Development Team on 12/25/24.
//  Copyright © 2024 LyoApp. All rights reserved.
//

import Foundation
import CoreData
import CloudKit
import SwiftUI

@objc(CDAchievement)
public class CDAchievement: NSManagedObject {
    
    // MARK: - Enums
    
    enum CDAchievementCategory: String, CaseIterable, Codable {
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
    
    enum CDAchievementTier: String, CaseIterable, Codable {
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
    
    enum CDAchievementRarity: String, CaseIterable, Codable {
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
    
    /// CDAchievement category as enum
    var categoryEnum: CDAchievementCategory {
        get { CDAchievementCategory(rawValue: category ?? "") ?? .learning }
        set { category = newValue.rawValue }
    }
    
    /// CDAchievement tier as enum
    var tierEnum: CDAchievementTier {
        get { CDAchievementTier(rawValue: tier ?? "") ?? .bronze }
        set { tier = newValue.rawValue }
    }
    
    /// CDAchievement rarity as enum
    var rarityEnum: CDAchievementRarity {
        get { CDAchievementRarity(rawValue: rarity ?? "") ?? .common }
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
    
    /// CDAchievement icon with tier overlay
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
    
    // MARK: - CDAchievement Management
    
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
        checkChainedCDAchievements()
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
        content.title = "CDAchievement Progress!"
        content.body = "You're making progress on '\(title ?? "Unknown CDAchievement")' - \(progressString)"
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
        content.title = "🏆 CDAchievement Unlocked!"
        content.body = "\(title ?? "New CDAchievement") - \(achievementDescription ?? "")"
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
    
    // MARK: - CDAchievement Chains
    
    private func checkChainedCDAchievements() {
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
    
    // MARK: - Static CDAchievement Definitions
    
    /// Create predefined learning achievements
    static func createLearningCDAchievements(in context: NSManagedObjectContext) -> [CDAchievement] {
        var achievements: [CDAchievement] = []
        
        // First Lesson
        let firstLesson = CDAchievement(context: context)
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
        let courseComplete = CDAchievement(context: context)
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
        let perfectScore = CDAchievement(context: context)
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
    static func createStreakCDAchievements(in context: NSManagedObjectContext) -> [CDAchievement] {
        var achievements: [CDAchievement] = []
        
        let streakData = [
            (days: 3, title: "Getting Started", tier: CDAchievementTier.bronze, rarity: CDAchievementRarity.common, points: 20),
            (days: 7, title: "Week Warrior", tier: CDAchievementTier.silver, rarity: CDAchievementRarity.uncommon, points: 50),
            (days: 30, title: "Monthly Master", tier: CDAchievementTier.gold, rarity: CDAchievementRarity.rare, points: 200),
            (days: 100, title: "Century Scholar", tier: CDAchievementTier.platinum, rarity: CDAchievementRarity.epic, points: 500),
            (days: 365, title: "Yearly Yogi", tier: CDAchievementTier.diamond, rarity: CDAchievementRarity.legendary, points: 1000)
        ]
        
        for (days, title, tier, rarity, points) in streakData {
            let achievement = CDAchievement(context: context)
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
                           category: CDAchievementCategory,
                           tier: CDAchievementTier,
                           rarity: CDAchievementRarity,
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
    
    func validateCDAchievementData() throws {
        guard let title = title, !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw CDAchievementValidationError.emptyTitle
        }
        
        guard requiredValue > 0 else {
            throw CDAchievementValidationError.invalidRequiredValue
        }
        
        guard basePoints >= 0 else {
            throw CDAchievementValidationError.invalidPoints
        }
        
        guard currentValue >= 0 else {
            throw CDAchievementValidationError.invalidCurrentValue
        }
        
        if isUnlocked && currentValue < requiredValue {
            throw CDAchievementValidationError.inconsistentUnlockState
        }
    }
    
    // MARK: - Lifecycle Methods
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        id = UUID()
        createdAt = Date()
        lastModified = Date()
        category = CDAchievementCategory.learning.rawValue
        tier = CDAchievementTier.bronze.rawValue
        rarity = CDAchievementRarity.common.rawValue
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
            try validateCDAchievementData()
        } catch {
            print("CDAchievement validation failed: \(error)")
        }
    }
}

// MARK: - Custom Errors

enum CDAchievementValidationError: Error, LocalizedError {
    case emptyTitle
    case invalidRequiredValue
    case invalidPoints
    case invalidCurrentValue
    case inconsistentUnlockState
    
    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "CDAchievement title cannot be empty."
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

extension CDAchievement {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDAchievement> {
        return NSFetchRequest<CDAchievement>(entityName: "CDAchievement")
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
    @NSManaged public var user: CDUser?
    @NSManaged public var course: CDCourse?
}

// MARK: - Identifiable Conformance

extension CDAchievement: Identifiable {
    // Uses the inherited id property from NSManagedObject
}
