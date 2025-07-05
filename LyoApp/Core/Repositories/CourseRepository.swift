//
//  CDCourseRepository.swift
//  LyoApp
//
//  Created by LyoApp Development Team on 12/25/24.
//  Copyright © 2024 LyoApp. All rights reserved.
//

import Foundation
import CoreData
import Combine
import OSLog

/// Repository for managing CDCourse entity operations with Core Data
@MainActor
public class CDCourseRepository: ObservableObject {
    
    // MARK: - Properties
    
    private let coreDataStack: CoreDataStack
    private let logger = Logger(subsystem: "com.lyoapp.repositories", category: "CDCourseRepository")
    
    @Published public private(set) var featuredCDCourses: [CDCourse] = []
    @Published public private(set) var recentCDCourses: [CDCourse] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
        loadFeaturedCDCourses()
        loadRecentCDCourses()
    }
    
    // MARK: - CDCourse Creation & Management
    
    /// Create a new course
    public func createCDCourse(
        title: String,
        subtitle: String? = nil,
        description: String,
        category: CDCourse.Category,
        difficulty: CDCourse.DifficultyLevel,
        instructor: CDUser,
        price: Double = 0.0,
        estimatedDuration: TimeInterval = 0
    ) async throws -> CDCourse {
        logger.info("Creating new course: \(title)")
        
        return try await coreDataStack.performBackgroundTask { context in
            let instructorInContext = context.object(with: instructor.objectID) as! CDUser
            
            let course = CDCourse(context: context)
            course.title = title
            course.subtitle = subtitle
            course.courseDescription = description
            course.categoryEnum = category
            course.difficultyEnum = difficulty
            course.instructor = instructorInContext
            course.price = price
            course.estimatedDuration = estimatedDuration
            
            try self.coreDataStack.save(context: context)
            
            DispatchQueue.main.async {
                self.logger.info("Successfully created course: \(title)")
            }
            
            return course
        }
    }
    
    /// Update course details
    public func updateCDCourse(
        _ course: CDCourse,
        title: String? = nil,
        subtitle: String? = nil,
        description: String? = nil,
        category: CDCourse.Category? = nil,
        difficulty: CDCourse.DifficultyLevel? = nil,
        price: Double? = nil,
        imageURL: String? = nil
    ) async throws {
        logger.info("Updating course: \(course.title ?? "unknown")")
        
        try await coreDataStack.performBackgroundTask { context in
            let courseInContext = context.object(with: course.objectID) as! CDCourse
            
            if let title = title {
                courseInContext.title = title
            }
            
            if let subtitle = subtitle {
                courseInContext.subtitle = subtitle
            }
            
            if let description = description {
                courseInContext.courseDescription = description
            }
            
            if let category = category {
                courseInContext.categoryEnum = category
            }
            
            if let difficulty = difficulty {
                courseInContext.difficultyEnum = difficulty
            }
            
            if let price = price {
                courseInContext.price = price
            }
            
            if let imageURL = imageURL {
                courseInContext.imageURL = imageURL
            }
            
            try self.coreDataStack.save(context: context)
            
            DispatchQueue.main.async {
                self.logger.info("Successfully updated course")
            }
        }
    }
    
    /// Delete course
    public func deleteCDCourse(_ course: CDCourse) async throws {
        logger.warning("Deleting course: \(course.title ?? "unknown")")
        
        try await coreDataStack.performBackgroundTask { context in
            let courseInContext = context.object(with: course.objectID) as! CDCourse
            context.delete(courseInContext)
            
            try self.coreDataStack.save(context: context)
            
            DispatchQueue.main.async {
                self.logger.info("Successfully deleted course")
                self.refreshFeaturedCDCourses()
                self.refreshRecentCDCourses()
            }
        }
    }
    
    /// Publish course
    public func publishCDCourse(_ course: CDCourse) async throws {
        logger.info("Publishing course: \(course.title ?? "unknown")")
        
        try await coreDataStack.performBackgroundTask { context in
            let courseInContext = context.object(with: course.objectID) as! CDCourse
            
            courseInContext.statusEnum = .published
            courseInContext.isPublished = true
            courseInContext.publishedAt = Date()
            
            try self.coreDataStack.save(context: context)
            
            DispatchQueue.main.async {
                self.logger.info("Successfully published course")
                self.refreshFeaturedCDCourses()
            }
        }
    }
    
    /// Archive course
    public func archiveCDCourse(_ course: CDCourse) async throws {
        logger.info("Archiving course: \(course.title ?? "unknown")")
        
        try await coreDataStack.performBackgroundTask { context in
            let courseInContext = context.object(with: course.objectID) as! CDCourse
            
            courseInContext.statusEnum = .archived
            courseInContext.isArchived = true
            
            try self.coreDataStack.save(context: context)
            
            DispatchQueue.main.async {
                self.logger.info("Successfully archived course")
                self.refreshFeaturedCDCourses()
            }
        }
    }
    
    // MARK: - CDCourse Discovery
    
    /// Get featured courses
    public func getFeaturedCDCourses(limit: Int = 10) async throws -> [CDCourse] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDCourse> = CDCourse.fetchRequest()
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "status == %@", CDCourse.Status.featured.rawValue),
                NSPredicate(format: "isPublished == YES")
            ])
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \CDCourse.publishedAt, ascending: false)
            ]
            request.fetchLimit = limit
            
            return try context.fetch(request)
        }
    }
    
    /// Get courses by category
    public func getCDCourses(
        category: CDCourse.Category,
        difficulty: CDCourse.DifficultyLevel? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> [CDCourse] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDCourse> = CDCourse.fetchRequest()
            
            var predicates = [
                NSPredicate(format: "category == %@", category.rawValue),
                NSPredicate(format: "isPublished == YES")
            ]
            
            if let difficulty = difficulty {
                predicates.append(NSPredicate(format: "difficulty == %@", difficulty.rawValue))
            }
            
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \CDCourse.averageRating, ascending: false),
                NSSortDescriptor(keyPath: \CDCourse.publishedAt, ascending: false)
            ]
            request.fetchLimit = limit
            request.fetchOffset = offset
            
            return try context.fetch(request)
        }
    }
    
    /// Search courses
    public func searchCDCourses(
        query: String,
        category: CDCourse.Category? = nil,
        difficulty: CDCourse.DifficultyLevel? = nil,
        priceRange: ClosedRange<Double>? = nil,
        limit: Int = 20
    ) async throws -> [CDCourse] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDCourse> = CDCourse.fetchRequest()
            
            var predicates = [NSPredicate(format: "isPublished == YES")]
            
            // Search query
            if !query.isEmpty {
                let searchTerms = query.components(separatedBy: .whitespaces)
                    .filter { !$0.isEmpty }
                
                var searchPredicates: [NSPredicate] = []
                
                for term in searchTerms {
                    let termPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                        NSPredicate(format: "title CONTAINS[cd] %@", term),
                        NSPredicate(format: "subtitle CONTAINS[cd] %@", term),
                        NSPredicate(format: "courseDescription CONTAINS[cd] %@", term),
                        NSPredicate(format: "tags CONTAINS[cd] %@", term)
                    ])
                    searchPredicates.append(termPredicate)
                }
                
                if !searchPredicates.isEmpty {
                    predicates.append(NSCompoundPredicate(andPredicateWithSubpredicates: searchPredicates))
                }
            }
            
            // Category filter
            if let category = category {
                predicates.append(NSPredicate(format: "category == %@", category.rawValue))
            }
            
            // Difficulty filter
            if let difficulty = difficulty {
                predicates.append(NSPredicate(format: "difficulty == %@", difficulty.rawValue))
            }
            
            // Price range filter
            if let priceRange = priceRange {
                predicates.append(NSPredicate(format: "price >= %f AND price <= %f", 
                                            priceRange.lowerBound, priceRange.upperBound))
            }
            
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \CDCourse.averageRating, ascending: false),
                NSSortDescriptor(keyPath: \CDCourse.viewCount, ascending: false)
            ]
            request.fetchLimit = limit
            
            return try context.fetch(request)
        }
    }
    
    /// Get popular courses
    public func getPopularCDCourses(limit: Int = 10) async throws -> [CDCourse] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDCourse> = CDCourse.fetchRequest()
            request.predicate = NSPredicate(format: "isPublished == YES")
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \CDCourse.viewCount, ascending: false),
                NSSortDescriptor(keyPath: \CDCourse.averageRating, ascending: false)
            ]
            request.fetchLimit = limit
            
            return try context.fetch(request)
        }
    }
    
    /// Get recommended courses for user
    public func getRecommendedCDCourses(for user: CDUser, limit: Int = 10) async throws -> [CDCourse] {
        return try await coreDataStack.performBackgroundTask { context in
            let userInContext = context.object(with: user.objectID) as! CDUser
            
            // Get user's learning preferences
            let preferences = userInContext.getLearningPreferences()
            let preferredTopics = preferences?.preferredTopics ?? []
            let preferredDifficulty = preferences?.preferredDifficulty ?? "intermediate"
            
            let request: NSFetchRequest<CDCourse> = CDCourse.fetchRequest()
            
            var predicates = [NSPredicate(format: "isPublished == YES")]
            
            // Exclude already enrolled courses
            if let enrolledCDCourses = userInContext.enrolledCDCourses as? Set<CDCourse>,
               !enrolledCDCourses.isEmpty {
                let enrolledIDs = enrolledCDCourses.compactMap { $0.id }
                predicates.append(NSPredicate(format: "NOT (id IN %@)", enrolledIDs))
            }
            
            // Prefer courses matching user's preferred difficulty
            if !preferredDifficulty.isEmpty {
                predicates.append(NSPredicate(format: "difficulty == %@", preferredDifficulty))
            }
            
            // Prefer courses matching user's interests
            if !preferredTopics.isEmpty {
                let topicsPredicates = preferredTopics.map { topic in
                    NSPredicate(format: "tags CONTAINS[cd] %@ OR category == %@", topic, topic)
                }
                predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: topicsPredicates))
            }
            
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \CDCourse.averageRating, ascending: false),
                NSSortDescriptor(keyPath: \CDCourse.publishedAt, ascending: false)
            ]
            request.fetchLimit = limit
            
            return try context.fetch(request)
        }
    }
    
    // MARK: - CDCourse Enrollment
    
    /// Enroll user in course
    public func enrollCDUser(_ user: CDUser, in course: CDCourse) async throws {
        logger.info("Enrolling user \(user.username ?? "unknown") in course \(course.title ?? "unknown")")
        
        try await coreDataStack.performBackgroundTask { context in
            let userInContext = context.object(with: user.objectID) as! CDUser
            let courseInContext = context.object(with: course.objectID) as! CDCourse
            
            let success = courseInContext.enrollCDUser(userInContext)
            
            if !success {
                throw CDCourseRepositoryError.enrollmentFailed
            }
            
            try self.coreDataStack.save(context: context)
            
            DispatchQueue.main.async {
                self.logger.info("Successfully enrolled user in course")
            }
        }
    }
    
    /// Unenroll user from course
    public func unenrollCDUser(_ user: CDUser, from course: CDCourse) async throws {
        logger.info("Unenrolling user \(user.username ?? "unknown") from course \(course.title ?? "unknown")")
        
        try await coreDataStack.performBackgroundTask { context in
            let userInContext = context.object(with: user.objectID) as! CDUser
            let courseInContext = context.object(with: course.objectID) as! CDCourse
            
            courseInContext.unenrollCDUser(userInContext)
            
            try self.coreDataStack.save(context: context)
            
            DispatchQueue.main.async {
                self.logger.info("Successfully unenrolled user from course")
            }
        }
    }
    
    /// Get user's enrolled courses
    public func getEnrolledCDCourses(for user: CDUser) async throws -> [CDCourse] {
        return try await coreDataStack.performBackgroundTask { context in
            let userInContext = context.object(with: user.objectID) as! CDUser
            
            let request: NSFetchRequest<CDCourse> = CDCourse.fetchRequest()
            request.predicate = NSPredicate(format: "SELF IN %@", userInContext.enrolledCDCourses ?? NSSet())
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \CDCourse.lastViewedAt, ascending: false)
            ]
            
            return try context.fetch(request)
        }
    }
    
    // MARK: - CDCourse Analytics
    
    /// Track course view
    public func trackCDCourseView(_ course: CDCourse, by user: CDUser) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let courseInContext = context.object(with: course.objectID) as! CDCourse
            let userInContext = context.object(with: user.objectID) as! CDUser
            
            courseInContext.trackView(by: userInContext)
            
            try self.coreDataStack.save(context: context)
        }
    }
    
    /// Get course statistics
    public func getCDCourseStatistics(_ course: CDCourse) async throws -> CDCourseStatistics {
        return try await coreDataStack.performBackgroundTask { context in
            let courseInContext = context.object(with: course.objectID) as! CDCourse
            
            let enrollmentCount = courseInContext.enrollmentCount
            let completionRate = courseInContext.averageCompletionRate
            let averageRating = courseInContext.averageRating
            let reviewCount = courseInContext.reviewCount
            let viewCount = Int(courseInContext.viewCount)
            
            // Calculate revenue (for paid courses)
            let revenue = courseInContext.price * Double(enrollmentCount)
            
            return CDCourseStatistics(
                enrollmentCount: enrollmentCount,
                completionRate: completionRate,
                averageRating: averageRating,
                reviewCount: reviewCount,
                viewCount: viewCount,
                revenue: revenue
            )
        }
    }
    
    /// Update course completion statistics
    public func updateCDCourseCompletionStats(_ course: CDCourse) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let courseInContext = context.object(with: course.objectID) as! CDCourse
            courseInContext.updateCompletionStats()
            
            try self.coreDataStack.save(context: context)
        }
    }
    
    // MARK: - CDCourse Reviews
    
    /// Add course review
    public func addReview(
        to course: CDCourse,
        by user: CDUser,
        rating: Double,
        comment: String?
    ) async throws {
        logger.info("Adding review for course: \(course.title ?? "unknown")")
        
        try await coreDataStack.performBackgroundTask { context in
            let courseInContext = context.object(with: course.objectID) as! CDCourse
            let userInContext = context.object(with: user.objectID) as! CDUser
            
            let review = CDCDCourseReview(context: context)
            review.course = courseInContext
            review.reviewer = userInContext
            review.rating = rating
            review.comment = comment
            review.isVerified = courseInContext.isCDUserEnrolled(userInContext)
            
            try self.coreDataStack.save(context: context)
            
            DispatchQueue.main.async {
                self.logger.info("Successfully added course review")
            }
        }
    }
    
    /// Get course reviews
    public func getReviews(for course: CDCourse, limit: Int = 20) async throws -> [CDCDCourseReview] {
        return try await coreDataStack.performBackgroundTask { context in
            let courseInContext = context.object(with: course.objectID) as! CDCourse
            
            let request: NSFetchRequest<CDCDCourseReview> = CDCDCourseReview.fetchRequest()
            request.predicate = NSPredicate(format: "course == %@", courseInContext)
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \CDCDCourseReview.isVerified, ascending: false),
                NSSortDescriptor(keyPath: \CDCDCourseReview.createdAt, ascending: false)
            ]
            request.fetchLimit = limit
            
            return try context.fetch(request)
        }
    }
    
    // MARK: - CDCourse Filtering & Sorting
    
    /// Get courses with filters
    public func getCDCoursesWithFilters(_ filters: CDCourseFilters) async throws -> [CDCourse] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDCourse> = CDCourse.fetchRequest()
            
            var predicates = [NSPredicate(format: "isPublished == YES")]
            
            // Category filter
            if !filters.categories.isEmpty {
                let categoryValues = filters.categories.map { $0.rawValue }
                predicates.append(NSPredicate(format: "category IN %@", categoryValues))
            }
            
            // Difficulty filter
            if !filters.difficulties.isEmpty {
                let difficultyValues = filters.difficulties.map { $0.rawValue }
                predicates.append(NSPredicate(format: "difficulty IN %@", difficultyValues))
            }
            
            // Price filter
            if filters.freeOnly {
                predicates.append(NSPredicate(format: "price == 0"))
            } else if let priceRange = filters.priceRange {
                predicates.append(NSPredicate(format: "price >= %f AND price <= %f",
                                            priceRange.lowerBound, priceRange.upperBound))
            }
            
            // Duration filter
            if let durationRange = filters.durationRange {
                predicates.append(NSPredicate(format: "estimatedDuration >= %f AND estimatedDuration <= %f",
                                            durationRange.lowerBound, durationRange.upperBound))
            }
            
            // Rating filter
            if filters.minimumRating > 0 {
                predicates.append(NSPredicate(format: "averageRating >= %f", filters.minimumRating))
            }
            
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            
            // Sorting
            switch filters.sortBy {
            case .newest:
                request.sortDescriptors = [NSSortDescriptor(keyPath: \CDCourse.publishedAt, ascending: false)]
            case .oldest:
                request.sortDescriptors = [NSSortDescriptor(keyPath: \CDCourse.publishedAt, ascending: true)]
            case .rating:
                request.sortDescriptors = [NSSortDescriptor(keyPath: \CDCourse.averageRating, ascending: false)]
            case .popular:
                request.sortDescriptors = [NSSortDescriptor(keyPath: \CDCourse.viewCount, ascending: false)]
            case .priceLowToHigh:
                request.sortDescriptors = [NSSortDescriptor(keyPath: \CDCourse.price, ascending: true)]
            case .priceHighToLow:
                request.sortDescriptors = [NSSortDescriptor(keyPath: \CDCourse.price, ascending: false)]
            }
            
            request.fetchLimit = filters.limit
            request.fetchOffset = filters.offset
            
            return try context.fetch(request)
        }
    }
    
    // MARK: - Private Methods
    
    private func loadFeaturedCDCourses() {
        Task {
            do {
                let courses = try await getFeaturedCDCourses()
                DispatchQueue.main.async {
                    self.featuredCDCourses = courses
                }
            } catch {
                handleError(error)
            }
        }
    }
    
    private func loadRecentCDCourses() {
        Task {
            do {
                let courses = try await getPopularCDCourses()
                DispatchQueue.main.async {
                    self.recentCDCourses = courses
                }
            } catch {
                handleError(error)
            }
        }
    }
    
    private func refreshFeaturedCDCourses() {
        loadFeaturedCDCourses()
    }
    
    private func refreshRecentCDCourses() {
        loadRecentCDCourses()
    }
    
    private func handleError(_ error: Error) {
        DispatchQueue.main.async {
            self.error = error
            self.isLoading = false
        }
        logger.error("CDCourseRepository error: \(error.localizedDescription)")
    }
}

// MARK: - Supporting Types

public struct CDCourseStatistics {
    public let enrollmentCount: Int
    public let completionRate: Double
    public let averageRating: Double
    public let reviewCount: Int
    public let viewCount: Int
    public let revenue: Double
}

public struct CDCourseFilters {
    public var categories: [CDCourse.Category] = []
    public var difficulties: [CDCourse.DifficultyLevel] = []
    public var priceRange: ClosedRange<Double>?
    public var durationRange: ClosedRange<TimeInterval>?
    public var minimumRating: Double = 0
    public var freeOnly: Bool = false
    public var sortBy: CDCourseSortOption = .newest
    public var limit: Int = 20
    public var offset: Int = 0
    
    public init() {}
}

public enum CDCourseSortOption {
    case newest
    case oldest
    case rating
    case popular
    case priceLowToHigh
    case priceHighToLow
}

public enum CDCourseRepositoryError: Error, LocalizedError {
    case courseNotFound
    case enrollmentFailed
    case alreadyEnrolled
    case prerequisitesNotMet
    case invalidCDCourseData
    
    public var errorDescription: String? {
        switch self {
        case .courseNotFound:
            return "CDCourse not found."
        case .enrollmentFailed:
            return "Failed to enroll in course."
        case .alreadyEnrolled:
            return "CDUser is already enrolled in this course."
        case .prerequisitesNotMet:
            return "Prerequisites for this course are not met."
        case .invalidCDCourseData:
            return "Invalid course data provided."
        }
    }
}

// MARK: - Core Data Extensions

extension CDCDCourseReview {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDCDCourseReview> {
        return NSFetchRequest<CDCDCourseReview>(entityName: "CDCDCourseReview")
    }
}
