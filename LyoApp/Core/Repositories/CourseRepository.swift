//
//  CourseRepository.swift
//  LyoApp
//
//  Created by LyoApp Development Team on 12/25/24.
//  Copyright © 2024 LyoApp. All rights reserved.
//

import Foundation
import CoreData
import Combine
import OSLog

/// Repository for managing Course entity operations with Core Data
@MainActor
public class CourseRepository: ObservableObject {
    
    // MARK: - Properties
    
    private let coreDataStack: CoreDataStack
    private let logger = Logger(subsystem: "com.lyoapp.repositories", category: "CourseRepository")
    
    @Published public private(set) var featuredCourses: [Course] = []
    @Published public private(set) var recentCourses: [Course] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
        loadFeaturedCourses()
        loadRecentCourses()
    }
    
    // MARK: - Course Creation & Management
    
    /// Create a new course
    public func createCourse(
        title: String,
        subtitle: String? = nil,
        description: String,
        category: Course.Category,
        difficulty: Course.DifficultyLevel,
        instructor: User,
        price: Double = 0.0,
        estimatedDuration: TimeInterval = 0
    ) async throws -> Course {
        logger.info("Creating new course: \(title)")
        
        return try await coreDataStack.performBackgroundTask { context in
            let instructorInContext = context.object(with: instructor.objectID) as! User
            
            let course = Course(context: context)
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
    public func updateCourse(
        _ course: Course,
        title: String? = nil,
        subtitle: String? = nil,
        description: String? = nil,
        category: Course.Category? = nil,
        difficulty: Course.DifficultyLevel? = nil,
        price: Double? = nil,
        imageURL: String? = nil
    ) async throws {
        logger.info("Updating course: \(course.title ?? "unknown")")
        
        try await coreDataStack.performBackgroundTask { context in
            let courseInContext = context.object(with: course.objectID) as! Course
            
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
    public func deleteCourse(_ course: Course) async throws {
        logger.warning("Deleting course: \(course.title ?? "unknown")")
        
        try await coreDataStack.performBackgroundTask { context in
            let courseInContext = context.object(with: course.objectID) as! Course
            context.delete(courseInContext)
            
            try self.coreDataStack.save(context: context)
            
            DispatchQueue.main.async {
                self.logger.info("Successfully deleted course")
                self.refreshFeaturedCourses()
                self.refreshRecentCourses()
            }
        }
    }
    
    /// Publish course
    public func publishCourse(_ course: Course) async throws {
        logger.info("Publishing course: \(course.title ?? "unknown")")
        
        try await coreDataStack.performBackgroundTask { context in
            let courseInContext = context.object(with: course.objectID) as! Course
            
            courseInContext.statusEnum = .published
            courseInContext.isPublished = true
            courseInContext.publishedAt = Date()
            
            try self.coreDataStack.save(context: context)
            
            DispatchQueue.main.async {
                self.logger.info("Successfully published course")
                self.refreshFeaturedCourses()
            }
        }
    }
    
    /// Archive course
    public func archiveCourse(_ course: Course) async throws {
        logger.info("Archiving course: \(course.title ?? "unknown")")
        
        try await coreDataStack.performBackgroundTask { context in
            let courseInContext = context.object(with: course.objectID) as! Course
            
            courseInContext.statusEnum = .archived
            courseInContext.isArchived = true
            
            try self.coreDataStack.save(context: context)
            
            DispatchQueue.main.async {
                self.logger.info("Successfully archived course")
                self.refreshFeaturedCourses()
            }
        }
    }
    
    // MARK: - Course Discovery
    
    /// Get featured courses
    public func getFeaturedCourses(limit: Int = 10) async throws -> [Course] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Course> = Course.fetchRequest()
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "status == %@", Course.Status.featured.rawValue),
                NSPredicate(format: "isPublished == YES")
            ])
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \Course.publishedAt, ascending: false)
            ]
            request.fetchLimit = limit
            
            return try context.fetch(request)
        }
    }
    
    /// Get courses by category
    public func getCourses(
        category: Course.Category,
        difficulty: Course.DifficultyLevel? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> [Course] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Course> = Course.fetchRequest()
            
            var predicates = [
                NSPredicate(format: "category == %@", category.rawValue),
                NSPredicate(format: "isPublished == YES")
            ]
            
            if let difficulty = difficulty {
                predicates.append(NSPredicate(format: "difficulty == %@", difficulty.rawValue))
            }
            
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \Course.averageRating, ascending: false),
                NSSortDescriptor(keyPath: \Course.publishedAt, ascending: false)
            ]
            request.fetchLimit = limit
            request.fetchOffset = offset
            
            return try context.fetch(request)
        }
    }
    
    /// Search courses
    public func searchCourses(
        query: String,
        category: Course.Category? = nil,
        difficulty: Course.DifficultyLevel? = nil,
        priceRange: ClosedRange<Double>? = nil,
        limit: Int = 20
    ) async throws -> [Course] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Course> = Course.fetchRequest()
            
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
                NSSortDescriptor(keyPath: \Course.averageRating, ascending: false),
                NSSortDescriptor(keyPath: \Course.viewCount, ascending: false)
            ]
            request.fetchLimit = limit
            
            return try context.fetch(request)
        }
    }
    
    /// Get popular courses
    public func getPopularCourses(limit: Int = 10) async throws -> [Course] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Course> = Course.fetchRequest()
            request.predicate = NSPredicate(format: "isPublished == YES")
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \Course.viewCount, ascending: false),
                NSSortDescriptor(keyPath: \Course.averageRating, ascending: false)
            ]
            request.fetchLimit = limit
            
            return try context.fetch(request)
        }
    }
    
    /// Get recommended courses for user
    public func getRecommendedCourses(for user: User, limit: Int = 10) async throws -> [Course] {
        return try await coreDataStack.performBackgroundTask { context in
            let userInContext = context.object(with: user.objectID) as! User
            
            // Get user's learning preferences
            let preferences = userInContext.getLearningPreferences()
            let preferredTopics = preferences?.preferredTopics ?? []
            let preferredDifficulty = preferences?.preferredDifficulty ?? "intermediate"
            
            let request: NSFetchRequest<Course> = Course.fetchRequest()
            
            var predicates = [NSPredicate(format: "isPublished == YES")]
            
            // Exclude already enrolled courses
            if let enrolledCourses = userInContext.enrolledCourses as? Set<Course>,
               !enrolledCourses.isEmpty {
                let enrolledIDs = enrolledCourses.compactMap { $0.id }
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
                NSSortDescriptor(keyPath: \Course.averageRating, ascending: false),
                NSSortDescriptor(keyPath: \Course.publishedAt, ascending: false)
            ]
            request.fetchLimit = limit
            
            return try context.fetch(request)
        }
    }
    
    // MARK: - Course Enrollment
    
    /// Enroll user in course
    public func enrollUser(_ user: User, in course: Course) async throws {
        logger.info("Enrolling user \(user.username ?? "unknown") in course \(course.title ?? "unknown")")
        
        try await coreDataStack.performBackgroundTask { context in
            let userInContext = context.object(with: user.objectID) as! User
            let courseInContext = context.object(with: course.objectID) as! Course
            
            let success = courseInContext.enrollUser(userInContext)
            
            if !success {
                throw CourseRepositoryError.enrollmentFailed
            }
            
            try self.coreDataStack.save(context: context)
            
            DispatchQueue.main.async {
                self.logger.info("Successfully enrolled user in course")
            }
        }
    }
    
    /// Unenroll user from course
    public func unenrollUser(_ user: User, from course: Course) async throws {
        logger.info("Unenrolling user \(user.username ?? "unknown") from course \(course.title ?? "unknown")")
        
        try await coreDataStack.performBackgroundTask { context in
            let userInContext = context.object(with: user.objectID) as! User
            let courseInContext = context.object(with: course.objectID) as! Course
            
            courseInContext.unenrollUser(userInContext)
            
            try self.coreDataStack.save(context: context)
            
            DispatchQueue.main.async {
                self.logger.info("Successfully unenrolled user from course")
            }
        }
    }
    
    /// Get user's enrolled courses
    public func getEnrolledCourses(for user: User) async throws -> [Course] {
        return try await coreDataStack.performBackgroundTask { context in
            let userInContext = context.object(with: user.objectID) as! User
            
            let request: NSFetchRequest<Course> = Course.fetchRequest()
            request.predicate = NSPredicate(format: "SELF IN %@", userInContext.enrolledCourses ?? NSSet())
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \Course.lastViewedAt, ascending: false)
            ]
            
            return try context.fetch(request)
        }
    }
    
    // MARK: - Course Analytics
    
    /// Track course view
    public func trackCourseView(_ course: Course, by user: User) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let courseInContext = context.object(with: course.objectID) as! Course
            let userInContext = context.object(with: user.objectID) as! User
            
            courseInContext.trackView(by: userInContext)
            
            try self.coreDataStack.save(context: context)
        }
    }
    
    /// Get course statistics
    public func getCourseStatistics(_ course: Course) async throws -> CourseStatistics {
        return try await coreDataStack.performBackgroundTask { context in
            let courseInContext = context.object(with: course.objectID) as! Course
            
            let enrollmentCount = courseInContext.enrollmentCount
            let completionRate = courseInContext.averageCompletionRate
            let averageRating = courseInContext.averageRating
            let reviewCount = courseInContext.reviewCount
            let viewCount = Int(courseInContext.viewCount)
            
            // Calculate revenue (for paid courses)
            let revenue = courseInContext.price * Double(enrollmentCount)
            
            return CourseStatistics(
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
    public func updateCourseCompletionStats(_ course: Course) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let courseInContext = context.object(with: course.objectID) as! Course
            courseInContext.updateCompletionStats()
            
            try self.coreDataStack.save(context: context)
        }
    }
    
    // MARK: - Course Reviews
    
    /// Add course review
    public func addReview(
        to course: Course,
        by user: User,
        rating: Double,
        comment: String?
    ) async throws {
        logger.info("Adding review for course: \(course.title ?? "unknown")")
        
        try await coreDataStack.performBackgroundTask { context in
            let courseInContext = context.object(with: course.objectID) as! Course
            let userInContext = context.object(with: user.objectID) as! User
            
            let review = CourseReview(context: context)
            review.course = courseInContext
            review.reviewer = userInContext
            review.rating = rating
            review.comment = comment
            review.isVerified = courseInContext.isUserEnrolled(userInContext)
            
            try self.coreDataStack.save(context: context)
            
            DispatchQueue.main.async {
                self.logger.info("Successfully added course review")
            }
        }
    }
    
    /// Get course reviews
    public func getReviews(for course: Course, limit: Int = 20) async throws -> [CourseReview] {
        return try await coreDataStack.performBackgroundTask { context in
            let courseInContext = context.object(with: course.objectID) as! Course
            
            let request: NSFetchRequest<CourseReview> = CourseReview.fetchRequest()
            request.predicate = NSPredicate(format: "course == %@", courseInContext)
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \CourseReview.isVerified, ascending: false),
                NSSortDescriptor(keyPath: \CourseReview.createdAt, ascending: false)
            ]
            request.fetchLimit = limit
            
            return try context.fetch(request)
        }
    }
    
    // MARK: - Course Filtering & Sorting
    
    /// Get courses with filters
    public func getCoursesWithFilters(_ filters: CourseFilters) async throws -> [Course] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Course> = Course.fetchRequest()
            
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
                request.sortDescriptors = [NSSortDescriptor(keyPath: \Course.publishedAt, ascending: false)]
            case .oldest:
                request.sortDescriptors = [NSSortDescriptor(keyPath: \Course.publishedAt, ascending: true)]
            case .rating:
                request.sortDescriptors = [NSSortDescriptor(keyPath: \Course.averageRating, ascending: false)]
            case .popular:
                request.sortDescriptors = [NSSortDescriptor(keyPath: \Course.viewCount, ascending: false)]
            case .priceLowToHigh:
                request.sortDescriptors = [NSSortDescriptor(keyPath: \Course.price, ascending: true)]
            case .priceHighToLow:
                request.sortDescriptors = [NSSortDescriptor(keyPath: \Course.price, ascending: false)]
            }
            
            request.fetchLimit = filters.limit
            request.fetchOffset = filters.offset
            
            return try context.fetch(request)
        }
    }
    
    // MARK: - Private Methods
    
    private func loadFeaturedCourses() {
        Task {
            do {
                let courses = try await getFeaturedCourses()
                DispatchQueue.main.async {
                    self.featuredCourses = courses
                }
            } catch {
                handleError(error)
            }
        }
    }
    
    private func loadRecentCourses() {
        Task {
            do {
                let courses = try await getPopularCourses()
                DispatchQueue.main.async {
                    self.recentCourses = courses
                }
            } catch {
                handleError(error)
            }
        }
    }
    
    private func refreshFeaturedCourses() {
        loadFeaturedCourses()
    }
    
    private func refreshRecentCourses() {
        loadRecentCourses()
    }
    
    private func handleError(_ error: Error) {
        DispatchQueue.main.async {
            self.error = error
            self.isLoading = false
        }
        logger.error("CourseRepository error: \(error.localizedDescription)")
    }
}

// MARK: - Supporting Types

public struct CourseStatistics {
    public let enrollmentCount: Int
    public let completionRate: Double
    public let averageRating: Double
    public let reviewCount: Int
    public let viewCount: Int
    public let revenue: Double
}

public struct CourseFilters {
    public var categories: [Course.Category] = []
    public var difficulties: [Course.DifficultyLevel] = []
    public var priceRange: ClosedRange<Double>?
    public var durationRange: ClosedRange<TimeInterval>?
    public var minimumRating: Double = 0
    public var freeOnly: Bool = false
    public var sortBy: CourseSortOption = .newest
    public var limit: Int = 20
    public var offset: Int = 0
    
    public init() {}
}

public enum CourseSortOption {
    case newest
    case oldest
    case rating
    case popular
    case priceLowToHigh
    case priceHighToLow
}

public enum CourseRepositoryError: Error, LocalizedError {
    case courseNotFound
    case enrollmentFailed
    case alreadyEnrolled
    case prerequisitesNotMet
    case invalidCourseData
    
    public var errorDescription: String? {
        switch self {
        case .courseNotFound:
            return "Course not found."
        case .enrollmentFailed:
            return "Failed to enroll in course."
        case .alreadyEnrolled:
            return "User is already enrolled in this course."
        case .prerequisitesNotMet:
            return "Prerequisites for this course are not met."
        case .invalidCourseData:
            return "Invalid course data provided."
        }
    }
}

// MARK: - Core Data Extensions

extension CourseReview {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CourseReview> {
        return NSFetchRequest<CourseReview>(entityName: "CourseReview")
    }
}
