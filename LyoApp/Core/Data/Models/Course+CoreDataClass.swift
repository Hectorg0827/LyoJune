//
//  CDCourse+CoreDataClass.swift
//  LyoApp
//
//  Created by LyoApp Development Team on 12/25/24.
//  Copyright © 2024 LyoApp. All rights reserved.
//

import Foundation
import CoreData
import CloudKit
import SwiftUI

@objc(CDCourse)
public class CDCourse: NSManagedObject {
    
    // MARK: - Enums
    
    enum Category: String, CaseIterable, Codable {
        case technology = "technology"
        case business = "business"
        case language = "language"
        case science = "science"
        case arts = "arts"
        case health = "health"
        case personal = "personal"
        case academic = "academic"
        
        var displayName: String {
            switch self {
            case .technology: return "Technology"
            case .business: return "Business"
            case .language: return "Language"
            case .science: return "Science"
            case .arts: return "Arts & Creative"
            case .health: return "Health & Wellness"
            case .personal: return "Personal Development"
            case .academic: return "Academic"
            }
        }
        
        var icon: String {
            switch self {
            case .technology: return "laptopcomputer"
            case .business: return "briefcase"
            case .language: return "globe"
            case .science: return "atom"
            case .arts: return "paintbrush"
            case .health: return "heart"
            case .personal: return "person.crop.circle"
            case .academic: return "graduationcap"
            }
        }
        
        var color: Color {
            switch self {
            case .technology: return .blue
            case .business: return .green
            case .language: return .orange
            case .science: return .purple
            case .arts: return .pink
            case .health: return .red
            case .personal: return .mint
            case .academic: return .indigo
            }
        }
    }
    
    enum DifficultyLevel: String, CaseIterable, Codable {
        case beginner = "beginner"
        case intermediate = "intermediate"
        case advanced = "advanced"
        case expert = "expert"
        
        var displayName: String {
            rawValue.capitalized
        }
        
        var color: Color {
            switch self {
            case .beginner: return .green
            case .intermediate: return .yellow
            case .advanced: return .orange
            case .expert: return .red
            }
        }
        
        var points: Int {
            switch self {
            case .beginner: return 10
            case .intermediate: return 20
            case .advanced: return 30
            case .expert: return 50
            }
        }
    }
    
    enum Status: String, CaseIterable, Codable {
        case draft = "draft"
        case published = "published"
        case archived = "archived"
        case featured = "featured"
        
        var displayName: String {
            rawValue.capitalized
        }
    }
    
    // MARK: - Computed Properties
    
    /// CDCourse category as enum
    var categoryEnum: Category {
        get { Category(rawValue: category ?? "") ?? .technology }
        set { category = newValue.rawValue }
    }
    
    /// Difficulty level as enum
    var difficultyEnum: DifficultyLevel {
        get { DifficultyLevel(rawValue: difficulty ?? "") ?? .beginner }
        set { difficulty = newValue.rawValue }
    }
    
    /// CDCourse status as enum
    var statusEnum: Status {
        get { Status(rawValue: status ?? "") ?? .draft }
        set { status = newValue.rawValue }
    }
    
    /// Total number of lessons in course
    var totalLessons: Int {
        return lessons?.count ?? 0
    }
    
    /// Total estimated duration for entire course
    var totalDuration: TimeInterval {
        guard let lessonSet = lessons as? Set<Lesson> else { return estimatedDuration }
        return lessonSet.reduce(0) { $0 + $1.duration }
    }
    
    /// CDCourse completion rate (0.0 to 1.0)
    var averageCompletionRate: Double {
        guard let enrollments = enrolledUsers as? Set<User>,
              !enrollments.isEmpty else { return 0.0 }
        
        let totalProgress = enrollments.compactMap { user in
            user.progress(for: self)?.completionPercentage
        }.reduce(0, +)
        
        return totalProgress / Double(enrollments.count)
    }
    
    /// Number of students enrolled
    var enrollmentCount: Int {
        return enrolledUsers?.count ?? 0
    }
    
    /// Average rating for the course
    var averageRating: Double {
        guard let reviews = courseReviews, !reviews.isEmpty else { return 0.0 }
        
        let totalRating = reviews.compactMap { ($0 as? CDCDCourseReview)?.rating }
            .reduce(0.0, +)
        
        return totalRating / Double(reviews.count)
    }
    
    /// Number of reviews
    var reviewCount: Int {
        return courseReviews?.count ?? 0
    }
    
    /// Check if course is published and available
    var isAvailable: Bool {
        return statusEnum == .published && 
               publishedAt != nil && 
               publishedAt! <= Date()
    }
    
    /// Check if course is featured
    var isFeatured: Bool {
        return statusEnum == .featured
    }
    
    /// CDCourse thumbnail URL
    var thumbnailURL: URL? {
        guard let urlString = imageURL else { return nil }
        return URL(string: urlString)
    }
    
    /// Formatted price string
    var formattedPrice: String {
        if price <= 0 {
            return "Free"
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = currency ?? "USD"
            return formatter.string(from: NSNumber(value: price)) ?? "$\(price)"
        }
    }
    
    /// Check if course is free
    var isFree: Bool {
        return price <= 0
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
    
    // MARK: - Content Management
    
    /// Get lessons sorted by order
    var sortedLessons: [Lesson] {
        guard let lessonSet = lessons as? Set<Lesson> else { return [] }
        return lessonSet.sorted { $0.order < $1.order }
    }
    
    /// Get lesson at specific index
    func lesson(at index: Int) -> Lesson? {
        let sorted = sortedLessons
        guard index >= 0 && index < sorted.count else { return nil }
        return sorted[index]
    }
    
    /// Add lesson to course
    func addLesson(_ lesson: Lesson) {
        lesson.course = self
        lesson.order = Int32(totalLessons)
        addToLessons(lesson)
        updateModificationDate()
    }
    
    /// Remove lesson from course
    func removeLesson(_ lesson: Lesson) {
        removeFromLessons(lesson)
        reorderLessons()
        updateModificationDate()
    }
    
    /// Reorder lessons after deletion
    private func reorderLessons() {
        let sorted = sortedLessons
        for (index, lesson) in sorted.enumerated() {
            lesson.order = Int32(index)
        }
    }
    
    // MARK: - Prerequisites Management
    
    /// Check if user meets prerequisites
    func userMeetsPrerequisites(_ user: User) -> Bool {
        guard let prerequisiteSet = prerequisites as? Set<CDCourse> else { return true }
        
        for prerequisite in prerequisiteSet {
            guard let progress = user.progress(for: prerequisite),
                  progress.isCompleted else {
                return false
            }
        }
        return true
    }
    
    /// Get list of unmet prerequisites for user
    func unmetPrerequisites(for user: User) -> [CDCourse] {
        guard let prerequisiteSet = prerequisites as? Set<CDCourse> else { return [] }
        
        return prerequisiteSet.filter { prerequisite in
            guard let progress = user.progress(for: prerequisite) else { return true }
            return !progress.isCompleted
        }
    }
    
    // MARK: - Enrollment Management
    
    /// Enroll user in course
    func enrollUser(_ user: User) -> Bool {
        guard userMeetsPrerequisites(user) else { return false }
        
        addToEnrolledUsers(user)
        user.addToEnrolledCDCourses(self)
        
        // Create initial progress record
        if user.progress(for: self) == nil {
            createInitialProgress(for: user)
        }
        
        updateModificationDate()
        return true
    }
    
    /// Unenroll user from course
    func unenrollUser(_ user: User) {
        removeFromEnrolledUsers(user)
        user.removeFromEnrolledCDCourses(self)
        updateModificationDate()
    }
    
    /// Check if user is enrolled
    func isUserEnrolled(_ user: User) -> Bool {
        guard let enrolledSet = enrolledUsers as? Set<User> else { return false }
        return enrolledSet.contains(user)
    }
    
    /// Create initial progress for enrolled user
    private func createInitialProgress(for user: User) {
        guard let context = managedObjectContext else { return }
        
        let progress = Progress(context: context)
        progress.id = UUID()
        progress.user = user
        progress.course = self
        progress.enrolledAt = Date()
        progress.completionPercentage = 0.0
        progress.timeSpent = 0
        progress.isCompleted = false
        progress.lastAccessed = Date()
    }
    
    // MARK: - Analytics & Tracking
    
    /// Track course view
    func trackView(by user: User) {
        viewCount += 1
        lastViewedAt = Date()
        
        // Update user's last accessed date
        if let progress = user.progress(for: self) {
            progress.lastAccessed = Date()
        }
        
        updateModificationDate()
    }
    
    /// Update completion statistics
    func updateCompletionStats() {
        guard let enrolledSet = enrolledUsers as? Set<User> else { return }
        
        let completedCount = enrolledSet.filter { user in
            user.progress(for: self)?.isCompleted == true
        }.count
        
        completionRate = enrolledSet.isEmpty ? 0.0 : Double(completedCount) / Double(enrolledSet.count)
        updateModificationDate()
    }
    
    // MARK: - Search & Discovery
    
    /// Generate searchable keywords
    var searchableKeywords: [String] {
        var keywords: [String] = []
        
        // Add title words
        if let title = title {
            keywords.append(contentsOf: title.components(separatedBy: .whitespaces))
        }
        
        // Add subtitle words
        if let subtitle = subtitle {
            keywords.append(contentsOf: subtitle.components(separatedBy: .whitespaces))
        }
        
        // Add category and difficulty
        keywords.append(categoryEnum.displayName)
        keywords.append(difficultyEnum.displayName)
        
        // Add tags
        if let tags = tags {
            keywords.append(contentsOf: tags.components(separatedBy: ","))
        }
        
        // Add instructor name
        if let instructor = instructor?.fullName {
            keywords.append(contentsOf: instructor.components(separatedBy: .whitespaces))
        }
        
        return keywords.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    /// Check if course matches search query
    func matches(searchQuery: String) -> Bool {
        let query = searchQuery.lowercased()
        let keywords = searchableKeywords
        
        return keywords.contains { $0.contains(query) } ||
               title?.lowercased().contains(query) == true ||
               courseDescription?.lowercased().contains(query) == true
    }
    
    // MARK: - Data Validation
    
    func validateCDCourseData() throws {
        guard let title = title, !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw CDCourseValidationError.emptyTitle
        }
        
        guard title.count <= 100 else {
            throw CDCourseValidationError.titleTooLong
        }
        
        guard let description = courseDescription, !description.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw CDCourseValidationError.emptyDescription
        }
        
        guard estimatedDuration > 0 else {
            throw CDCourseValidationError.invalidDuration
        }
        
        guard price >= 0 else {
            throw CDCourseValidationError.invalidPrice
        }
    }
    
    // MARK: - Lifecycle Methods
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        id = UUID()
        createdAt = Date()
        lastModified = Date()
        status = Status.draft.rawValue
        category = Category.technology.rawValue
        difficulty = DifficultyLevel.beginner.rawValue
        isPublished = false
        price = 0.0
        currency = "USD"
        viewCount = 0
        completionRate = 0.0
        averageRating = 0.0
        estimatedDuration = 0
    }
    
    public override func willSave() {
        super.willSave()
        
        if hasChanges && !isInserted {
            lastModified = Date()
        }
        
        do {
            try validateCDCourseData()
        } catch {
            print("CDCourse validation failed: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateModificationDate() {
        lastModified = Date()
    }
}

// MARK: - Custom Errors

enum CDCourseValidationError: Error, LocalizedError {
    case emptyTitle
    case titleTooLong
    case emptyDescription
    case invalidDuration
    case invalidPrice
    
    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "CDCourse title cannot be empty."
        case .titleTooLong:
            return "CDCourse title cannot exceed 100 characters."
        case .emptyDescription:
            return "CDCourse description cannot be empty."
        case .invalidDuration:
            return "CDCourse duration must be greater than 0."
        case .invalidPrice:
            return "CDCourse price cannot be negative."
        }
    }
}

// MARK: - Core Data Generated Properties

extension CDCourse {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDCourse> {
        return NSFetchRequest<CDCourse>(entityName: "CDCourse")
    }
    
    // Basic Properties
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var subtitle: String?
    @NSManaged public var courseDescription: String?
    @NSManaged public var category: String?
    @NSManaged public var difficulty: String?
    @NSManaged public var status: String?
    @NSManaged public var tags: String?
    
    // Media
    @NSManaged public var imageURL: String?
    @NSManaged public var thumbnailURL: String?
    @NSManaged public var videoPreviewURL: String?
    
    // Pricing
    @NSManaged public var price: Double
    @NSManaged public var currency: String?
    @NSManaged public var isOnSale: Bool
    @NSManaged public var salePrice: Double
    @NSManaged public var saleEndDate: Date?
    
    // Timing
    @NSManaged public var estimatedDuration: TimeInterval
    @NSManaged public var createdAt: Date?
    @NSManaged public var lastModified: Date?
    @NSManaged public var publishedAt: Date?
    @NSManaged public var lastViewedAt: Date?
    
    // Status
    @NSManaged public var isPublished: Bool
    @NSManaged public var isFeatured: Bool
    @NSManaged public var isArchived: Bool
    
    // Statistics
    @NSManaged public var viewCount: Int32
    @NSManaged public var completionRate: Double
    @NSManaged public var averageRating: Double
    
    // CloudKit
    @NSManaged public var cloudKitRecordData: Data?
    @NSManaged public var cloudKitRecordID: String?
    @NSManaged public var cloudKitSyncDate: Date?
    
    // Relationships
    @NSManaged public var instructor: CDUser?
    @NSManaged public var lessons: NSSet?
    @NSManaged public var enrolledUsers: NSSet?
    @NSManaged public var prerequisites: NSSet?
    @NSManaged public var courseReviews: NSSet?
    @NSManaged public var progress: NSSet?
    @NSManaged public var achievements: NSSet?
}

// MARK: - Relationship Helpers

extension CDCourse {
    @objc(addLessonsObject:)
    @NSManaged public func addToLessons(_ value: CDLesson)
    
    @objc(removeLessonsObject:)
    @NSManaged public func removeFromLessons(_ value: CDLesson)
    
    @objc(addLessons:)
    @NSManaged public func addToLessons(_ values: NSSet)
    
    @objc(removeLessons:)
    @NSManaged public func removeFromLessons(_ values: NSSet)
    
    @objc(addEnrolledUsersObject:)
    @NSManaged public func addToEnrolledUsers(_ value: CDUser)
    
    @objc(removeEnrolledUsersObject:)
    @NSManaged public func removeFromEnrolledUsers(_ value: CDUser)
    
    @objc(addEnrolledUsers:)
    @NSManaged public func addToEnrolledUsers(_ values: NSSet)
    
    @objc(removeEnrolledUsers:)
    @NSManaged public func removeFromEnrolledUsers(_ values: NSSet)
    
    @objc(addPrerequisitesObject:)
    @NSManaged public func addToPrerequisites(_ value: CDCourse)
    
    @objc(removePrerequisitesObject:)
    @NSManaged public func removeFromPrerequisites(_ value: CDCourse)
    
    @objc(addPrerequisites:)
    @NSManaged public func addToPrerequisites(_ values: NSSet)
    
    @objc(removePrerequisites:)
    @NSManaged public func removeFromPrerequisites(_ values: NSSet)
}

// MARK: - CDCDCourseReview Supporting Class

@objc(CDCourseReview)
public class CDCourseReview: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var rating: Double
    @NSManaged public var comment: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var isVerified: Bool
    @NSManaged public var course: CDCourse?
    @NSManaged public var reviewer: CDUser?
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        createdAt = Date()
        isVerified = false
    }
}
