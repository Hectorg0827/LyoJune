//
//  CDUserRepository.swift
//  LyoApp
//
//  Created by LyoApp Development Team on 12/25/24.
//  Copyright © 2024 LyoApp. All rights reserved.
//

import Foundation
import CoreData
import Combine
import OSLog

/// Repository for managing CDUser entity operations with Core Data
@MainActor
public class CDUserRepository: ObservableObject {
    
    // MARK: - Properties
    
    private let coreDataStack: CoreDataStack
    private let logger = Logger(subsystem: "com.lyoapp.repositories", category: "CDUserRepository")
    
    @Published public private(set) var currentCDUser: CDUser?
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
        loadCurrentCDUser()
    }
    
    // MARK: - CDUser Management
    
    /// Create a new user
    public func createCDUser(
        username: String,
        email: String,
        firstName: String? = nil,
        lastName: String? = nil
    ) async throws -> CDUser {
        logger.info("Creating new user: \(username)")
        
        return try await coreDataStack.performBackgroundTask { context in
            // Check if user already exists
            let existingCDUser = try self.findCDUser(byCDUsername: username, in: context)
            if existingCDUser != nil {
                throw CDUserRepositoryError.userAlreadyExists
            }
            
            let emailCDUser = try self.findCDUser(byEmail: email, in: context)
            if emailCDUser != nil {
                throw CDUserRepositoryError.emailAlreadyExists
            }
            
            // Create new user
            let user = CDUser(context: context)
            user.username = username
            user.email = email
            user.firstName = firstName
            user.lastName = lastName
            
            // Set default values are handled in awakeFromInsert
            
            try self.coreDataStack.save(context: context)
            
            DispatchQueue.main.async {
                self.currentCDUser = user
                self.logger.info("Successfully created user: \(username)")
            }
            
            return user
        }
    }
    
    /// Find user by ID
    public func findCDUser(byID id: UUID) async throws -> CDUser? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDUser> = CDUser.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            return try context.fetch(request).first
        }
    }
    
    /// Find user by username
    public func findCDUser(byCDUsername username: String, in context: NSManagedObjectContext? = nil) throws -> CDUser? {
        let contextToUse = context ?? coreDataStack.viewContext
        
        let request: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        request.predicate = NSPredicate(format: "username == %@", username)
        request.fetchLimit = 1
        
        return try contextToUse.fetch(request).first
    }
    
    /// Find user by email
    public func findCDUser(byEmail email: String, in context: NSManagedObjectContext? = nil) throws -> CDUser? {
        let contextToUse = context ?? coreDataStack.viewContext
        
        let request: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        request.predicate = NSPredicate(format: "email == %@", email)
        request.fetchLimit = 1
        
        return try contextToUse.fetch(request).first
    }
    
    /// Update user profile
    public func updateCDUser(
        _ user: CDUser,
        firstName: String? = nil,
        lastName: String? = nil,
        bio: String? = nil,
        profileImageData: Data? = nil
    ) async throws {
        logger.info("Updating user profile: \(user.username ?? "unknown")")
        
        try await coreDataStack.performBackgroundTask { context in
            let userInContext = context.object(with: user.objectID) as! CDUser
            
            if let firstName = firstName {
                userInContext.firstName = firstName
            }
            
            if let lastName = lastName {
                userInContext.lastName = lastName
            }
            
            if let bio = bio {
                userInContext.bio = bio
            }
            
            if let profileImageData = profileImageData {
                userInContext.profileImageData = profileImageData
            }
            
            try self.coreDataStack.save(context: context)
            
            DispatchQueue.main.async {
                self.logger.info("Successfully updated user profile")
            }
        }
    }
    
    /// Update user preferences
    public func updateCDUserPreferences(
        _ user: CDUser,
        learningPreferences: LearningPreferences? = nil,
        notificationPreferences: NotificationPreferences? = nil
    ) async throws {
        logger.info("Updating user preferences")
        
        try await coreDataStack.performBackgroundTask { context in
            let userInContext = context.object(with: user.objectID) as! CDUser
            
            if let learningPrefs = learningPreferences {
                userInContext.updateLearningPreferences(learningPrefs)
            }
            
            if let notificationPrefs = notificationPreferences {
                userInContext.updateNotificationPreferences(notificationPrefs)
            }
            
            try self.coreDataStack.save(context: context)
            
            DispatchQueue.main.async {
                self.logger.info("Successfully updated user preferences")
            }
        }
    }
    
    /// Delete user
    public func deleteCDUser(_ user: CDUser) async throws {
        logger.warning("Deleting user: \(user.username ?? "unknown")")
        
        try await coreDataStack.performBackgroundTask { context in
            let userInContext = context.object(with: user.objectID) as! CDUser
            context.delete(userInContext)
            
            try self.coreDataStack.save(context: context)
            
            DispatchQueue.main.async {
                if self.currentCDUser?.objectID == user.objectID {
                    self.currentCDUser = nil
                }
                self.logger.info("Successfully deleted user")
            }
        }
    }
    
    // MARK: - CDUser Authentication
    
    /// Set current user (for login)
    public func setCurrentCDUser(_ user: CDUser) {
        currentCDUser = user
        user.lastLoginAt = Date()
        user.lastActiveAt = Date()
        
        do {
            try coreDataStack.save()
            logger.info("Set current user: \(user.username ?? "unknown")")
        } catch {
            logger.error("Failed to save current user login: \(error.localizedDescription)")
        }
    }
    
    /// Clear current user (for logout)
    public func clearCurrentCDUser() {
        currentCDUser = nil
        logger.info("Cleared current user")
    }
    
    /// Load current user from persistent storage
    private func loadCurrentCDUser() {
        // This would typically load from CDUserDefaults or Keychain
        // For now, we'll load the most recently active user
        
        let request: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDUser.lastActiveAt, ascending: false)]
        request.fetchLimit = 1
        
        do {
            let users = try coreDataStack.viewContext.fetch(request)
            currentCDUser = users.first
            
            if let user = currentCDUser {
                logger.info("Loaded current user: \(user.username ?? "unknown")")
            }
        } catch {
            logger.error("Failed to load current user: \(error.localizedDescription)")
        }
    }
    
    // MARK: - CDUser CDProgress & Statistics
    
    /// Get user learning statistics
    public func getCDUserStatistics(_ user: CDUser) async throws -> CDUserStatistics {
        return try await coreDataStack.performBackgroundTask { context in
            let userInContext = context.object(with: user.objectID) as! CDUser
            
            let totalTime = userInContext.totalLearningTime
            let totalAchievements = userInContext.totalAchievements
            let currentStreak = userInContext.currentStreak
            let totalPoints = userInContext.totalPointsEarned
            let level = userInContext.userLevel
            
            // Get course statistics
            let enrolledCoursesCount = userInContext.enrolledCourses?.count ?? 0
            let completedCoursesCount = userInContext.completedLessonsCount()
            
            // Get recent activity
            let recentActivity = try self.getRecentActivity(for: userInContext, in: context)
            
            return CDUserStatistics(
                totalLearningTime: totalTime,
                totalAchievements: totalAchievements,
                currentStreak: currentStreak,
                totalPoints: Int(totalPoints),
                userLevel: level,
                enrolledCoursesCount: enrolledCoursesCount,
                completedCoursesCount: completedCoursesCount,
                recentActivity: recentActivity
            )
        }
    }
    
    /// Get user's recent learning activity
    private func getRecentActivity(for user: CDUser, in context: NSManagedObjectContext) throws -> [ActivityItem] {
        let request: NSFetchRequest<CDProgress> = CDProgress.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@", user)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDProgress.lastAccessed, ascending: false)]
        request.fetchLimit = 10
        
        let recentCDProgress = try context.fetch(request)
        
        return recentCDProgress.compactMap { progress in
            guard let lastAccessed = progress.lastAccessed else { return nil }
            
            let title: String
            let type: ActivityType
            
            if let lesson = progress.lesson {
                title = lesson.title ?? "Unknown Lesson"
                type = .lessonCompleted
            } else if let course = progress.course {
                title = course.title ?? "Unknown Course"
                type = .courseStarted
            } else {
                return nil
            }
            
            return ActivityItem(
                title: title,
                type: type,
                date: lastAccessed,
                progress: progress.completionPercentage
            )
        }
    }
    
    /// Update user activity
    public func updateCDUserActivity(_ user: CDUser) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let userInContext = context.object(with: user.objectID) as! CDUser
            userInContext.lastActiveAt = Date()
            
            try self.coreDataStack.save(context: context)
        }
    }
    
    // MARK: - CDUser Search & Filtering
    
    /// Search users by query
    public func searchCDUsers(
        query: String,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> [CDUser] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDUser> = CDUser.fetchRequest()
            
            // Create search predicate
            let searchTerms = query.components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
            
            var predicates: [NSPredicate] = []
            
            for term in searchTerms {
                let termPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                    NSPredicate(format: "username CONTAINS[cd] %@", term),
                    NSPredicate(format: "firstName CONTAINS[cd] %@", term),
                    NSPredicate(format: "lastName CONTAINS[cd] %@", term),
                    NSPredicate(format: "email CONTAINS[cd] %@", term)
                ])
                predicates.append(termPredicate)
            }
            
            if !predicates.isEmpty {
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            }
            
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \CDUser.lastActiveAt, ascending: false)
            ]
            request.fetchLimit = limit
            request.fetchOffset = offset
            
            return try context.fetch(request)
        }
    }
    
    /// Get users by activity status
    public func getCDUsersByActivity(
        activeWithinDays days: Int = 7,
        limit: Int = 50
    ) async throws -> [CDUser] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDUser> = CDUser.fetchRequest()
            
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            request.predicate = NSPredicate(format: "lastActiveAt >= %@", cutoffDate as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CDUser.lastActiveAt, ascending: false)]
            request.fetchLimit = limit
            
            return try context.fetch(request)
        }
    }
    
    /// Get top users by points
    public func getTopCDUsersByPoints(limit: Int = 10) async throws -> [CDUser] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDUser> = CDUser.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CDUser.totalPointsEarned, ascending: false)]
            request.fetchLimit = limit
            
            return try context.fetch(request)
        }
    }
    
    // MARK: - CDUser Validation
    
    /// Validate username availability
    public func isCDUsernameAvailable(_ username: String) async throws -> Bool {
        return try await coreDataStack.performBackgroundTask { context in
            let user = try self.findCDUser(byCDUsername: username, in: context)
            return user == nil
        }
    }
    
    /// Validate email availability
    public func isEmailAvailable(_ email: String) async throws -> Bool {
        return try await coreDataStack.performBackgroundTask { context in
            let user = try self.findCDUser(byEmail: email, in: context)
            return user == nil
        }
    }
    
    /// Validate user data
    public func validateCDUserData(
        username: String,
        email: String,
        excludingCDUser: CDUser? = nil
    ) async throws {
        try await coreDataStack.performBackgroundTask { context in
            // Check username
            if let existingCDUser = try self.findCDUser(byCDUsername: username, in: context),
               existingCDUser.objectID != excludingCDUser?.objectID {
                throw CDUserRepositoryError.userAlreadyExists
            }
            
            // Check email
            if let existingCDUser = try self.findCDUser(byEmail: email, in: context),
               existingCDUser.objectID != excludingCDUser?.objectID {
                throw CDUserRepositoryError.emailAlreadyExists
            }
        }
    }
    
    // MARK: - Batch Operations
    
    /// Batch update users
    public func batchUpdateCDUsers(
        predicate: NSPredicate,
        propertyValues: [String: Any]
    ) async throws {
        try await coreDataStack.performBackgroundTask { context in
            try self.coreDataStack.batchUpdate(
                entityType: CDUser.self,
                predicate: predicate,
                propertyValues: propertyValues
            )
        }
    }
    
    /// Clean up inactive users
    public func cleanupInactiveCDUsers(olderThanDays days: Int = 365) async throws -> Int {
        logger.info("Cleaning up inactive users older than \(days) days")
        
        return try await coreDataStack.performBackgroundTask { context in
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            
            let request: NSFetchRequest<CDUser> = CDUser.fetchRequest()
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "lastActiveAt < %@", cutoffDate as CVarArg),
                NSPredicate(format: "isActive == NO")
            ])
            
            let inactiveCDUsers = try context.fetch(request)
            let count = inactiveCDUsers.count
            
            for user in inactiveCDUsers {
                context.delete(user)
            }
            
            try self.coreDataStack.save(context: context)
            
            self.logger.info("Cleaned up \(count) inactive users")
            return count
        }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        DispatchQueue.main.async {
            self.error = error
            self.isLoading = false
        }
        logger.error("CDUserRepository error: \(error.localizedDescription)")
    }
}

// MARK: - Supporting Types

public struct CDUserStatistics {
    public let totalLearningTime: TimeInterval
    public let totalAchievements: Int
    public let currentStreak: Int
    public let totalPoints: Int
    public let userLevel: Int
    public let enrolledCoursesCount: Int
    public let completedCoursesCount: Int
    public let recentActivity: [ActivityItem]
}

public struct ActivityItem {
    public let title: String
    public let type: ActivityType
    public let date: Date
    public let progress: Double
}

public enum ActivityType {
    case lessonCompleted
    case courseStarted
    case courseCompleted
    case achievementUnlocked
    case streakMilestone
}

public enum CDUserRepositoryError: Error, LocalizedError {
    case userAlreadyExists
    case emailAlreadyExists
    case userNotFound
    case invalidCDUserData
    
    public var errorDescription: String? {
        switch self {
        case .userAlreadyExists:
            return "A user with this username already exists."
        case .emailAlreadyExists:
            return "A user with this email already exists."
        case .userNotFound:
            return "CDUser not found."
        case .invalidCDUserData:
            return "Invalid user data provided."
        }
    }
}
