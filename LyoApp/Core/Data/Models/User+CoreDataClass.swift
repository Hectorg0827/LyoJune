//
//  User+CoreDataClass.swift
//  LyoApp
//
//  Created by LyoApp Development Team on 12/25/24.
//  Copyright © 2024 LyoApp. All rights reserved.
//

import Foundation
import CoreData
import CloudKit
import CryptoKit

@objc(User)
public class User: NSManagedObject {
    
    // MARK: - Constants
    private enum Keys {
        static let encryptionKey = "UserDataEncryption"
        static let profilePrefix = "profile_"
    }
    
    // MARK: - Computed Properties
    
    /// Full display name combining first and last name
    var fullName: String {
        let components = [firstName, lastName].compactMap { $0?.trimmingCharacters(in: .whitespaces) }
        return components.isEmpty ? username ?? "Unknown User" : components.joined(separator: " ")
    }
    
    /// User's display initials for profile pictures
    var initials: String {
        let components = fullName.components(separatedBy: .whitespaces)
        let initials = components.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }
    
    /// Check if user profile is complete
    var isProfileComplete: Bool {
        return firstName != nil && 
               lastName != nil && 
               email != nil &&
               !email!.isEmpty &&
               profileImageData != nil
    }
    
    /// User's total learning time across all courses
    var totalLearningTime: TimeInterval {
        guard let progressSet = progress as? Set<Progress> else { return 0 }
        return progressSet.reduce(0) { $0 + $1.timeSpent }
    }
    
    /// User's total achievements count
    var totalAchievements: Int {
        return achievements?.count ?? 0
    }
    
    /// User's current learning streak
    var currentStreak: Int {
        guard let progressArray = progress?.allObjects as? [Progress] else { return 0 }
        
        let sortedProgress = progressArray
            .filter { $0.lastAccessed != nil }
            .sorted { $0.lastAccessed! > $1.lastAccessed! }
        
        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: Date())
        
        for progress in sortedProgress {
            let progressDate = Calendar.current.startOfDay(for: progress.lastAccessed!)
            let daysDifference = Calendar.current.dateComponents([.day], from: progressDate, to: currentDate).day ?? 0
            
            if daysDifference == 0 || daysDifference == 1 {
                if daysDifference == 1 {
                    streak += 1
                }
                currentDate = progressDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    // MARK: - CloudKit Integration
    
    /// CloudKit record representation
    var cloudKitRecord: CKRecord? {
        get {
            guard let recordData = cloudKitRecordData else { return nil }
            return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKRecord.self, from: recordData)
        }
        set {
            cloudKitRecordData = newValue.flatMap { try? NSKeyedArchiver.archivedData(withRootObject: $0, requiringSecureCoding: true) }
            cloudKitRecordID = newValue?.recordID.recordName
        }
    }
    
    /// Check if record needs CloudKit sync
    var needsCloudKitSync: Bool {
        return cloudKitSyncDate == nil || 
               (lastModified != nil && lastModified! > cloudKitSyncDate!)
    }
    
    // MARK: - Security & Privacy
    
    /// Encrypt sensitive user data before storage
    func encryptSensitiveData() {
        if let email = email {
            encryptedEmail = encrypt(data: email)
            self.email = nil // Clear plain text
        }
        
        if let phone = phoneNumber {
            encryptedPhoneNumber = encrypt(data: phone)
            phoneNumber = nil // Clear plain text
        }
    }
    
    /// Decrypt sensitive user data for use
    func decryptSensitiveData() {
        if let encryptedEmail = encryptedEmail,
           let decryptedEmail = decrypt(data: encryptedEmail) {
            email = decryptedEmail
        }
        
        if let encryptedPhone = encryptedPhoneNumber,
           let decryptedPhone = decrypt(data: encryptedPhone) {
            phoneNumber = decryptedPhone
        }
    }
    
    // MARK: - User Preferences Management
    
    /// Update user learning preferences
    func updateLearningPreferences(_ preferences: LearningPreferences) {
        do {
            let data = try JSONEncoder().encode(preferences)
            learningPreferencesData = data
            lastModified = Date()
        } catch {
            print("Failed to encode learning preferences: \(error)")
        }
    }
    
    /// Get user learning preferences
    func getLearningPreferences() -> LearningPreferences? {
        guard let data = learningPreferencesData else { return nil }
        return try? JSONDecoder().decode(LearningPreferences.self, from: data)
    }
    
    /// Update notification preferences
    func updateNotificationPreferences(_ preferences: NotificationPreferences) {
        do {
            let data = try JSONEncoder().encode(preferences)
            notificationPreferencesData = data
            lastModified = Date()
        } catch {
            print("Failed to encode notification preferences: \(error)")
        }
    }
    
    /// Get notification preferences
    func getNotificationPreferences() -> NotificationPreferences? {
        guard let data = notificationPreferencesData else { return nil }
        return try? JSONDecoder().decode(NotificationPreferences.self, from: data)
    }
    
    // MARK: - Progress & Analytics
    
    /// Get progress for specific course
    func progress(for course: Course) -> Progress? {
        guard let progressSet = progress as? Set<Progress> else { return nil }
        return progressSet.first { $0.course == course }
    }
    
    /// Get completed lessons count
    func completedLessonsCount(for course: Course? = nil) -> Int {
        guard let progressSet = progress as? Set<Progress> else { return 0 }
        
        if let course = course {
            return progressSet.filter { $0.course == course && $0.isCompleted }.count
        } else {
            return progressSet.filter { $0.isCompleted }.count
        }
    }
    
    /// Get user's level based on total points
    var userLevel: Int {
        let totalPoints = totalPointsEarned
        return Int(sqrt(Double(totalPoints) / 100)) + 1
    }
    
    /// Points needed for next level
    var pointsToNextLevel: Int {
        let currentLevel = userLevel
        let pointsForNextLevel = (currentLevel * currentLevel) * 100
        return pointsForNextLevel - Int(totalPointsEarned)
    }
    
    // MARK: - Data Validation
    
    /// Validate user data before saving
    func validateUserData() throws {
        if let email = email, !isValidEmail(email) {
            throw UserValidationError.invalidEmail
        }
        
        if let username = username, username.count < 3 {
            throw UserValidationError.usernameTooShort
        }
        
        if let phone = phoneNumber, !isValidPhoneNumber(phone) {
            throw UserValidationError.invalidPhoneNumber
        }
    }
    
    // MARK: - Lifecycle Methods
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        // Set default values
        id = UUID()
        createdAt = Date()
        lastModified = Date()
        isActive = true
        totalPointsEarned = 0
        preferredLanguage = Locale.current.languageCode ?? "en"
        
        // Initialize default preferences
        let defaultLearningPrefs = LearningPreferences()
        updateLearningPreferences(defaultLearningPrefs)
        
        let defaultNotificationPrefs = NotificationPreferences()
        updateNotificationPreferences(defaultNotificationPrefs)
    }
    
    public override func willSave() {
        super.willSave()
        
        // Update modification date on changes
        if hasChanges && !isInserted {
            lastModified = Date()
        }
        
        // Validate data before saving
        do {
            try validateUserData()
        } catch {
            print("User validation failed: \(error)")
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func encrypt(data: String) -> Data? {
        guard let keyData = Keys.encryptionKey.data(using: .utf8),
              let plainData = data.data(using: .utf8) else { return nil }
        
        let key = SymmetricKey(data: SHA256.hash(data: keyData))
        
        do {
            let sealedBox = try AES.GCM.seal(plainData, using: key)
            return sealedBox.combined
        } catch {
            print("Encryption failed: \(error)")
            return nil
        }
    }
    
    private func decrypt(data: Data) -> String? {
        guard let keyData = Keys.encryptionKey.data(using: .utf8) else { return nil }
        
        let key = SymmetricKey(data: SHA256.hash(data: keyData))
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            print("Decryption failed: \(error)")
            return nil
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func isValidPhoneNumber(_ phone: String) -> Bool {
        let phoneRegex = #"^\+?[1-9]\d{1,14}$"#
        return NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: phone)
    }
}

// MARK: - Supporting Data Structures

struct LearningPreferences: Codable {
    var dailyGoalMinutes: Int = 30
    var preferredDifficulty: String = "intermediate"
    var enableReminders: Bool = true
    var reminderTime: String = "19:00"
    var preferredTopics: [String] = []
    var autoplayNextLesson: Bool = true
    var enableOfflineDownloads: Bool = true
    var dataUsageMode: String = "wifi_only" // "wifi_only", "cellular", "ask"
}

struct NotificationPreferences: Codable {
    var enablePushNotifications: Bool = true
    var enableEmailNotifications: Bool = true
    var enableSMSNotifications: Bool = false
    var studyReminders: Bool = true
    var achievementNotifications: Bool = true
    var socialNotifications: Bool = true
    var marketingNotifications: Bool = false
    var quietHoursEnabled: Bool = false
    var quietHoursStart: String = "22:00"
    var quietHoursEnd: String = "08:00"
}

// MARK: - Custom Errors

enum UserValidationError: Error, LocalizedError {
    case invalidEmail
    case usernameTooShort
    case invalidPhoneNumber
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .usernameTooShort:
            return "Username must be at least 3 characters long."
        case .invalidPhoneNumber:
            return "Please enter a valid phone number."
        }
    }
}

// MARK: - Core Data Generated Properties Extension

extension User {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }
    
    // Basic Properties
    @NSManaged public var id: UUID?
    @NSManaged public var username: String?
    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
    @NSManaged public var email: String?
    @NSManaged public var phoneNumber: String?
    @NSManaged public var profileImageData: Data?
    @NSManaged public var profileImageURL: String?
    @NSManaged public var bio: String?
    @NSManaged public var preferredLanguage: String?
    
    // Encrypted Data
    @NSManaged public var encryptedEmail: Data?
    @NSManaged public var encryptedPhoneNumber: Data?
    
    // Preferences
    @NSManaged public var learningPreferencesData: Data?
    @NSManaged public var notificationPreferencesData: Data?
    
    // Timestamps
    @NSManaged public var createdAt: Date?
    @NSManaged public var lastModified: Date?
    @NSManaged public var lastLoginAt: Date?
    @NSManaged public var lastActiveAt: Date?
    
    // Status
    @NSManaged public var isActive: Bool
    @NSManaged public var isVerified: Bool
    @NSManaged public var isPremium: Bool
    
    // Points & Gamification
    @NSManaged public var totalPointsEarned: Int32
    @NSManaged public var currentStreak: Int32
    @NSManaged public var longestStreak: Int32
    
    // CloudKit
    @NSManaged public var cloudKitRecordData: Data?
    @NSManaged public var cloudKitRecordID: String?
    @NSManaged public var cloudKitSyncDate: Date?
    
    // Relationships
    @NSManaged public var progress: NSSet?
    @NSManaged public var achievements: NSSet?
    @NSManaged public var enrolledCourses: NSSet?
    @NSManaged public var createdCourses: NSSet?
    @NSManaged public var socialConnections: NSSet?
    @NSManaged public var notifications: NSSet?
}

// MARK: - Relationship Helpers

extension User {
    @objc(addProgressObject:)
    @NSManaged public func addToProgress(_ value: Progress)
    
    @objc(removeProgressObject:)
    @NSManaged public func removeFromProgress(_ value: Progress)
    
    @objc(addProgress:)
    @NSManaged public func addToProgress(_ values: NSSet)
    
    @objc(removeProgress:)
    @NSManaged public func removeFromProgress(_ values: NSSet)
    
    @objc(addAchievementsObject:)
    @NSManaged public func addToAchievements(_ value: Achievement)
    
    @objc(removeAchievementsObject:)
    @NSManaged public func removeFromAchievements(_ value: Achievement)
    
    @objc(addAchievements:)
    @NSManaged public func addToAchievements(_ values: NSSet)
    
    @objc(removeAchievements:)
    @NSManaged public func removeFromAchievements(_ values: NSSet)
    
    @objc(addEnrolledCoursesObject:)
    @NSManaged public func addToEnrolledCourses(_ value: Course)
    
    @objc(removeEnrolledCoursesObject:)
    @NSManaged public func removeFromEnrolledCourses(_ value: Course)
    
    @objc(addEnrolledCourses:)
    @NSManaged public func addToEnrolledCourses(_ values: NSSet)
    
    @objc(removeEnrolledCourses:)
    @NSManaged public func removeFromEnrolledCourses(_ values: NSSet)
}
