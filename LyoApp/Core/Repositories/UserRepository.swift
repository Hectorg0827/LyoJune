//
//  UserRepository.swift
//  LyoApp
//
//  Created by LyoApp Development Team on 12/25/24.
//  Copyright © 2024 LyoApp. All rights reserved.
//

import Foundation
import CoreData
import Combine
import OSLog

/// Repository for managing User entity operations with Core Data
@MainActor
public class UserRepository: ObservableObject {
    
    // MARK: - Properties
    
    private let coreDataStack: CoreDataStack
    private let logger = Logger(subsystem: "com.lyoapp.repositories", category: "UserRepository")
    
    @Published public private(set) var currentUser: User?
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
        loadCurrentUser()
    }
    
    // MARK: - User Management
    
    /// Create a new user
    public func createUser(
        username: String,
        email: String,
        firstName: String? = nil,
        lastName: String? = nil
    ) async throws -> User {
        logger.info("Creating new user: \(username)")
        
        return try await coreDataStack.performBackgroundTask { context in
            // Check if user already exists
            let existingUser = try self.findUser(byUsername: username, in: context)
            if existingUser != nil {
                throw UserRepositoryError.userAlreadyExists
            }
            
            let emailUser = try self.findUser(byEmail: email, in: context)
            if emailUser != nil {
                throw UserRepositoryError.emailAlreadyExists
            }
            
            // Create new user
            let user = User(context: context)
            user.username = username
            user.email = email
            user.firstName = firstName
            user.lastName = lastName
            
            // Set default values are handled in awakeFromInsert
            
            try self.coreDataStack.save(context: context)
            
            DispatchQueue.main.async {
                self.currentUser = user
                self.logger.info("Successfully created user: \(username)")
            }
            
            return user
        }
    }
    
    /// Find user by ID
    public func findUser(byID id: UUID) async throws -> User? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<User> = User.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            return try context.fetch(request).first
        }
    }
    
    /// Find user by username
    public func findUser(byUsername username: String, in context: NSManagedObjectContext? = nil) throws -> User? {
        let contextToUse = context ?? coreDataStack.viewContext
        
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "username == %@", username)
        request.fetchLimit = 1
        
        return try contextToUse.fetch(request).first
    }
    
    /// Find user by email
    public func findUser(byEmail email: String, in context: NSManagedObjectContext? = nil) throws -> User? {
        let contextToUse = context ?? coreDataStack.viewContext
        
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "email == %@", email)
        request.fetchLimit = 1
        
        return try contextToUse.fetch(request).first
    }
    
    /// Update user profile
    public func updateUser(
        _ user: User,
        firstName: String? = nil,
        lastName: String? = nil,
        bio: String? = nil,
        profileImageData: Data? = nil
    ) async throws {
        logger.info("Updating user profile: \(user.username ?? "unknown")")
        
        try await coreDataStack.performBackgroundTask { context in
            let userInContext = context.object(with: user.objectID) as! User
            
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
    public func updateUserPreferences(
        _ user: User,
        learningPreferences: LearningPreferences? = nil,
        notificationPreferences: NotificationPreferences? = nil
    ) async throws {
        logger.info("Updating user preferences")
        
        try await coreDataStack.performBackgroundTask { context in
            let userInContext = context.object(with: user.objectID) as! User
            
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
    public func deleteUser(_ user: User) async throws {
        logger.warning("Deleting user: \(user.username ?? "unknown")")
        
        try await coreDataStack.performBackgroundTask { context in
            let userInContext = context.object(with: user.objectID) as! User
            context.delete(userInContext)
            
            try self.coreDataStack.save(context: context)
            
            DispatchQueue.main.async {
                if self.currentUser?.objectID == user.objectID {
                    self.currentUser = nil
                }
                self.logger.info("Successfully deleted user")
            }
        }
    }
    
    // MARK: - User Authentication
    
    /// Set current user (for login)
    public func setCurrentUser(_ user: User) {
        currentUser = user
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
    public func clearCurrentUser() {
        currentUser = nil
        logger.info("Cleared current user")
    }
    
    /// Load current user from persistent storage
    private func loadCurrentUser() {
        // This would typically load from UserDefaults or Keychain
        // For now, we'll load the most recently active user
        
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \User.lastActiveAt, ascending: false)]
        request.fetchLimit = 1
        
        do {
            let users = try coreDataStack.viewContext.fetch(request)
            currentUser = users.first
            
            if let user = currentUser {
                logger.info("Loaded current user: \(user.username ?? "unknown")")
            }
        } catch {
            logger.error("Failed to load current user: \(error.localizedDescription)")
        }
    }
    
    // MARK: - User Progress & Statistics
    
    /// Get user learning statistics
    public func getUserStatistics(_ user: User) async throws -> UserStatistics {
        return try await coreDataStack.performBackgroundTask { context in
            let userInContext = context.object(with: user.objectID) as! User
            
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
            
            return UserStatistics(
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
    private func getRecentActivity(for user: User, in context: NSManagedObjectContext) throws -> [ActivityItem] {
        let request: NSFetchRequest<Progress> = Progress.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@", user)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Progress.lastAccessed, ascending: false)]
        request.fetchLimit = 10
        
        let recentProgress = try context.fetch(request)
        
        return recentProgress.compactMap { progress in
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
    public func updateUserActivity(_ user: User) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let userInContext = context.object(with: user.objectID) as! User
            userInContext.lastActiveAt = Date()
            
            try self.coreDataStack.save(context: context)
        }
    }
    
    // MARK: - User Search & Filtering
    
    /// Search users by query
    public func searchUsers(
        query: String,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> [User] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<User> = User.fetchRequest()
            
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
                NSSortDescriptor(keyPath: \User.lastActiveAt, ascending: false)
            ]
            request.fetchLimit = limit
            request.fetchOffset = offset
            
            return try context.fetch(request)
        }
    }
    
    /// Get users by activity status
    public func getUsersByActivity(
        activeWithinDays days: Int = 7,
        limit: Int = 50
    ) async throws -> [User] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<User> = User.fetchRequest()
            
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            request.predicate = NSPredicate(format: "lastActiveAt >= %@", cutoffDate as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \User.lastActiveAt, ascending: false)]
            request.fetchLimit = limit
            
            return try context.fetch(request)
        }
    }
    
    /// Get top users by points
    public func getTopUsersByPoints(limit: Int = 10) async throws -> [User] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<User> = User.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \User.totalPointsEarned, ascending: false)]
            request.fetchLimit = limit
            
            return try context.fetch(request)
        }
    }
    
    // MARK: - User Validation
    
    /// Validate username availability
    public func isUsernameAvailable(_ username: String) async throws -> Bool {
        return try await coreDataStack.performBackgroundTask { context in
            let user = try self.findUser(byUsername: username, in: context)
            return user == nil
        }
    }
    
    /// Validate email availability
    public func isEmailAvailable(_ email: String) async throws -> Bool {
        return try await coreDataStack.performBackgroundTask { context in
            let user = try self.findUser(byEmail: email, in: context)
            return user == nil
        }
    }
    
    /// Validate user data
    public func validateUserData(
        username: String,
        email: String,
        excludingUser: User? = nil
    ) async throws {
        try await coreDataStack.performBackgroundTask { context in
            // Check username
            if let existingUser = try self.findUser(byUsername: username, in: context),
               existingUser.objectID != excludingUser?.objectID {
                throw UserRepositoryError.userAlreadyExists
            }
            
            // Check email
            if let existingUser = try self.findUser(byEmail: email, in: context),
               existingUser.objectID != excludingUser?.objectID {
                throw UserRepositoryError.emailAlreadyExists
            }
        }
    }
    
    // MARK: - Batch Operations
    
    /// Batch update users
    public func batchUpdateUsers(
        predicate: NSPredicate,
        propertyValues: [String: Any]
    ) async throws {
        try await coreDataStack.performBackgroundTask { context in
            try self.coreDataStack.batchUpdate(
                entityType: User.self,
                predicate: predicate,
                propertyValues: propertyValues
            )
        }
    }
    
    /// Clean up inactive users
    public func cleanupInactiveUsers(olderThanDays days: Int = 365) async throws -> Int {
        logger.info("Cleaning up inactive users older than \(days) days")
        
        return try await coreDataStack.performBackgroundTask { context in
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            
            let request: NSFetchRequest<User> = User.fetchRequest()
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "lastActiveAt < %@", cutoffDate as CVarArg),
                NSPredicate(format: "isActive == NO")
            ])
            
            let inactiveUsers = try context.fetch(request)
            let count = inactiveUsers.count
            
            for user in inactiveUsers {
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
        logger.error("UserRepository error: \(error.localizedDescription)")
    }
}

// MARK: - Supporting Types

public struct UserStatistics {
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

public enum UserRepositoryError: Error, LocalizedError {
    case userAlreadyExists
    case emailAlreadyExists
    case userNotFound
    case invalidUserData
    
    public var errorDescription: String? {
        switch self {
        case .userAlreadyExists:
            return "A user with this username already exists."
        case .emailAlreadyExists:
            return "A user with this email already exists."
        case .userNotFound:
            return "User not found."
        case .invalidUserData:
            return "Invalid user data provided."
        }
    }
}
