//
//  SpotlightManager.swift
//  LyoApp
//
//  Spotlight search integration for app content discovery
//

import Foundation
import CoreSpotlight
import MobileCoreServices
import UniformTypeIdentifiers

// MARK: - Searchable Content Types
enum SpotlightContentType: String, CaseIterable {
    case course = "course"
    case lesson = "lesson"
    case achievement = "achievement"
    case note = "note"
    case quiz = "quiz"
    case video = "video"
    case article = "article"
    case discussion = "discussion"
    
    var displayName: String {
        switch self {
        case .course: return "Course"
        case .lesson: return "Lesson"
        case .achievement: return "Achievement"
        case .note: return "Note"
        case .quiz: return "Quiz"
        case .video: return "Video"
        case .article: return "Article"
        case .discussion: return "Discussion"
        }
    }
    
    var domainIdentifier: String {
        return "com.lyoapp.content.\(rawValue)"
    }
    
    var typeIdentifier: String {
        switch self {
        case .course, .lesson: return UTType.data.identifier
        case .achievement: return UTType.image.identifier
        case .note, .article: return UTType.text.identifier
        case .quiz: return UTType.data.identifier
        case .video: return UTType.movie.identifier
        case .discussion: return UTType.text.identifier
        }
    }
    
    var systemImageName: String {
        switch self {
        case .course: return "book.fill"
        case .lesson: return "play.circle.fill"
        case .achievement: return "trophy.fill"
        case .note: return "note.text"
        case .quiz: return "questionmark.circle.fill"
        case .video: return "video.fill"
        case .article: return "doc.text.fill"
        case .discussion: return "bubble.left.and.bubble.right.fill"
        }
    }
}

// MARK: - Searchable Item Protocol
protocol SpotlightSearchable {
    var spotlightIdentifier: String { get }
    var contentType: SpotlightContentType { get }
    var title: String { get }
    var subtitle: String? { get }
    var contentDescription: String? { get }
    var keywords: [String] { get }
    var thumbnailURL: URL? { get }
    var contentURL: URL? { get }
    var userInfo: [String: Any] { get }
    var lastModified: Date { get }
    var isSearchable: Bool { get }
}

// MARK: - Searchable Content Models
struct SpotlightCourse: SpotlightSearchable {
    let id: String
    let title: String
    let subtitle: String?
    let contentDescription: String?
    let instructor: String
    let category: String
    let level: String
    let duration: TimeInterval
    let thumbnailURL: URL?
    let keywords: [String]
    let lastModified: Date
    let isPublished: Bool
    let progress: Double
    
    var spotlightIdentifier: String { return "course_\(id)" }
    var contentType: SpotlightContentType { return .course }
    var isSearchable: Bool { return isPublished }
    
    var contentURL: URL? {
        return URL(string: "lyoapp://course/\(id)")
    }
    
    var userInfo: [String: Any] {
        return [
            "content_type": contentType.rawValue,
            "course_id": id,
            "instructor": instructor,
            "category": category,
            "level": level,
            "duration": duration,
            "progress": progress
        ]
    }
}

struct SpotlightLesson: SpotlightSearchable {
    let id: String
    let courseId: String
    let title: String
    let subtitle: String?
    let contentDescription: String?
    let duration: TimeInterval
    let thumbnailURL: URL?
    let keywords: [String]
    let lastModified: Date
    let isCompleted: Bool
    let progress: Double
    
    var spotlightIdentifier: String { return "lesson_\(id)" }
    var contentType: SpotlightContentType { return .lesson }
    var isSearchable: Bool { return true }
    
    var contentURL: URL? {
        return URL(string: "lyoapp://lesson/\(id)?course=\(courseId)")
    }
    
    var userInfo: [String: Any] {
        return [
            "content_type": contentType.rawValue,
            "lesson_id": id,
            "course_id": courseId,
            "duration": duration,
            "is_completed": isCompleted,
            "progress": progress
        ]
    }
}

struct SpotlightAchievement: SpotlightSearchable {
    let id: String
    let title: String
    let subtitle: String?
    let contentDescription: String?
    let badgeImageURL: URL?
    let keywords: [String]
    let earnedDate: Date
    let category: String
    
    var spotlightIdentifier: String { return "achievement_\(id)" }
    var contentType: SpotlightContentType { return .achievement }
    var isSearchable: Bool { return true }
    var lastModified: Date { return earnedDate }
    var thumbnailURL: URL? { return badgeImageURL }
    
    var contentURL: URL? {
        return URL(string: "lyoapp://achievement/\(id)")
    }
    
    var userInfo: [String: Any] {
        return [
            "content_type": contentType.rawValue,
            "achievement_id": id,
            "category": category,
            "earned_date": earnedDate.timeIntervalSince1970
        ]
    }
}

// MARK: - SpotlightManager
@MainActor
class SpotlightManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var indexedItemsCount: Int = 0
    @Published var isIndexing: Bool = false
    @Published var lastIndexingDate: Date?
    
    // MARK: - Private Properties
    private let searchableIndex = CSSearchableIndex.default()
    private let batchSize = 100
    private let maxItemsToIndex = 10000
    
    // MARK: - User Defaults Keys
    private enum UserDefaultsKeys {
        static let lastIndexingDate = "spotlight_last_indexing_date"
        static let indexedItemsCount = "spotlight_indexed_items_count"
    }
    
    // MARK: - Initialization
    init() {
        loadConfiguration()
        setupSearchableIndex()
    }
    
    // MARK: - Setup
    
    private func loadConfiguration() {
        indexedItemsCount = UserDefaults.standard.integer(forKey: UserDefaultsKeys.indexedItemsCount)
        
        if let date = UserDefaults.standard.object(forKey: UserDefaultsKeys.lastIndexingDate) as? Date {
            lastIndexingDate = date
        }
    }
    
    private func setupSearchableIndex() {
        // Set up indexing delegate if needed
        searchableIndex.indexDelegate = self
    }
    
    // MARK: - Indexing
    
    /// Index all searchable content
    func indexAllContent() async {
        guard !isIndexing else {
            print("⚠️ Spotlight indexing already in progress")
            return
        }
        
        isIndexing = true
        
        do {
            // Delete all existing items first
            try await deleteAllItems()
            
            // Index different content types
            await indexCourses()
            await indexLessons()
            await indexAchievements()
            await indexNotes()
            
            // Update metadata
            lastIndexingDate = Date()
            UserDefaults.standard.set(lastIndexingDate, forKey: UserDefaultsKeys.lastIndexingDate)
            UserDefaults.standard.set(indexedItemsCount, forKey: UserDefaultsKeys.indexedItemsCount)
            
            print("✅ Spotlight indexing completed. Indexed \(indexedItemsCount) items")
            
        } catch {
            print("❌ Spotlight indexing failed: \(error)")
        }
        
        isIndexing = false
    }
    
    /// Index specific item
    func indexItem<T: SpotlightSearchable>(_ item: T) async {
        guard item.isSearchable else { return }
        
        let searchableItem = createSearchableItem(from: item)
        
        do {
            try await searchableIndex.indexSearchableItems([searchableItem])
            print("✅ Indexed item: \(item.title)")
        } catch {
            print("❌ Failed to index item \(item.title): \(error)")
        }
    }
    
    /// Index multiple items
    func indexItems<T: SpotlightSearchable>(_ items: [T]) async {
        let searchableItems = items
            .filter { $0.isSearchable }
            .map { createSearchableItem(from: $0) }
        
        // Process in batches
        for batch in searchableItems.chunked(into: batchSize) {
            do {
                try await searchableIndex.indexSearchableItems(batch)
                indexedItemsCount += batch.count
                print("✅ Indexed batch of \(batch.count) items")
            } catch {
                print("❌ Failed to index batch: \(error)")
            }
        }
    }
    
    // MARK: - Content-Specific Indexing
    
    private func indexCourses() async {
        // This would typically fetch from your data source
        // For now, creating sample data
        let sampleCourses = createSampleCourses()
        await indexItems(sampleCourses)
    }
    
    private func indexLessons() async {
        let sampleLessons = createSampleLessons()
        await indexItems(sampleLessons)
    }
    
    private func indexAchievements() async {
        let sampleAchievements = createSampleAchievements()
        await indexItems(sampleAchievements)
    }
    
    private func indexNotes() async {
        // Would implement note indexing here
        print("📝 Note indexing not implemented yet")
    }
    
    // MARK: - Deletion
    
    /// Delete all indexed items
    func deleteAllItems() async throws {
        try await searchableIndex.deleteAllSearchableItems()
        indexedItemsCount = 0
        print("🗑️ Deleted all Spotlight items")
    }
    
    /// Delete items by type
    func deleteItems(ofType contentType: SpotlightContentType) async throws {
        try await searchableIndex.deleteSearchableItems(withDomainIdentifiers: [contentType.domainIdentifier])
        print("🗑️ Deleted \(contentType.displayName) items from Spotlight")
    }
    
    /// Delete specific item
    func deleteItem(identifier: String) async throws {
        try await searchableIndex.deleteSearchableItems(withIdentifiers: [identifier])
        print("🗑️ Deleted item: \(identifier)")
    }
    
    // MARK: - Search
    
    /// Perform spotlight search
    func search(query: String, contentTypes: [SpotlightContentType] = SpotlightContentType.allCases) async -> [CSSearchableItem] {
        let queryString = contentTypes.map { "kMDItemContentType == '\($0.typeIdentifier)'" }.joined(separator: " || ")
        let searchQuery = CSSearchQuery(queryString: "(\(queryString)) && (\(query))*", attributes: [
            "title",
            "contentDescription",
            "keywords"
        ])
        
        return await withCheckedContinuation { continuation in
            var results: [CSSearchableItem] = []
            
            searchQuery.foundItemsHandler = { items in
                results.append(contentsOf: items)
            }
            
            searchQuery.completionHandler = { error in
                if let error = error {
                    print("❌ Spotlight search error: \(error)")
                }
                continuation.resume(returning: results)
            }
            
            searchQuery.start()
        }
    }
    
    // MARK: - Helper Methods
    
    private func createSearchableItem<T: SpotlightSearchable>(from item: T) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(contentType: UTType(item.contentType.typeIdentifier)!)
        
        // Basic attributes
        attributeSet.title = item.title
        attributeSet.contentDescription = item.contentDescription
        attributeSet.displayName = item.title
        
        // Additional attributes
        if let subtitle = item.subtitle {
            attributeSet.subtitle = subtitle
        }
        
        // Keywords for better search
        attributeSet.keywords = item.keywords
        
        // Thumbnail
        if let thumbnailURL = item.thumbnailURL {
            attributeSet.thumbnailURL = thumbnailURL
        }
        
        // Content URL for deep linking
        if let contentURL = item.contentURL {
            attributeSet.contentURL = contentURL
        }
        
        // Metadata
        attributeSet.lastModifiedDate = item.lastModified
        attributeSet.addedDate = Date()
        
        // Content type specific attributes
        switch item.contentType {
        case .course:
            attributeSet.subject = "Learning Course"
            if let duration = item.userInfo["duration"] as? TimeInterval {
                attributeSet.duration = NSNumber(value: duration)
            }
            
        case .lesson:
            attributeSet.subject = "Learning Lesson"
            if let duration = item.userInfo["duration"] as? TimeInterval {
                attributeSet.duration = NSNumber(value: duration)
            }
            
        case .achievement:
            attributeSet.subject = "Learning Achievement"
            
        default:
            break
        }
        
        // Create searchable item
        let searchableItem = CSSearchableItem(
            uniqueIdentifier: item.spotlightIdentifier,
            domainIdentifier: item.contentType.domainIdentifier,
            attributeSet: attributeSet
        )
        
        return searchableItem
    }
    
    // MARK: - Sample Data Creation (would be replaced with real data)
    
    private func createSampleCourses() -> [SpotlightCourse] {
        return [
            SpotlightCourse(
                id: "swift-basics",
                title: "Swift Programming Basics",
                subtitle: "Learn Swift from scratch",
                contentDescription: "A comprehensive introduction to Swift programming language covering variables, functions, classes, and more.",
                instructor: "John Doe",
                category: "Programming",
                level: "Beginner",
                duration: 3600,
                thumbnailURL: nil,
                keywords: ["swift", "programming", "ios", "basics", "beginner"],
                lastModified: Date(),
                isPublished: true,
                progress: 0.3
            ),
            SpotlightCourse(
                id: "ui-design",
                title: "Mobile UI Design",
                subtitle: "Design beautiful mobile interfaces",
                contentDescription: "Learn the principles of mobile UI design including layout, typography, color theory, and user experience.",
                instructor: "Jane Smith",
                category: "Design",
                level: "Intermediate",
                duration: 5400,
                thumbnailURL: nil,
                keywords: ["ui", "ux", "design", "mobile", "interface"],
                lastModified: Date(),
                isPublished: true,
                progress: 0.7
            )
        ]
    }
    
    private func createSampleLessons() -> [SpotlightLesson] {
        return [
            SpotlightLesson(
                id: "swift-variables",
                courseId: "swift-basics",
                title: "Variables and Constants",
                subtitle: "Understanding data storage in Swift",
                contentDescription: "Learn how to declare and use variables and constants in Swift programming.",
                duration: 600,
                thumbnailURL: nil,
                keywords: ["swift", "variables", "constants", "var", "let"],
                lastModified: Date(),
                isCompleted: true,
                progress: 1.0
            ),
            SpotlightLesson(
                id: "swift-functions",
                courseId: "swift-basics",
                title: "Functions and Parameters",
                subtitle: "Creating reusable code blocks",
                contentDescription: "Master the art of writing functions with parameters and return values in Swift.",
                duration: 900,
                thumbnailURL: nil,
                keywords: ["swift", "functions", "parameters", "return", "methods"],
                lastModified: Date(),
                isCompleted: false,
                progress: 0.4
            )
        ]
    }
    
    private func createSampleAchievements() -> [SpotlightAchievement] {
        return [
            SpotlightAchievement(
                id: "first-lesson",
                title: "First Lesson Complete",
                subtitle: "Completed your first lesson",
                contentDescription: "Congratulations on completing your very first lesson in LyoApp!",
                badgeImageURL: nil,
                keywords: ["achievement", "first", "lesson", "beginner"],
                earnedDate: Date().addingTimeInterval(-86400),
                category: "Milestone"
            ),
            SpotlightAchievement(
                id: "week-streak",
                title: "Week Warrior",
                subtitle: "7 day study streak",
                contentDescription: "You've maintained a consistent study habit for a full week. Keep it up!",
                badgeImageURL: nil,
                keywords: ["achievement", "streak", "week", "consistent"],
                earnedDate: Date().addingTimeInterval(-3600),
                category: "Streak"
            )
        ]
    }
}

// MARK: - CSSearchableIndexDelegate
extension SpotlightManager: CSSearchableIndexDelegate {
    
    func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexAllSearchableItemsWithAcknowledgementHandler acknowledgementHandler: @escaping () -> Void) {
        Task {
            await indexAllContent()
            acknowledgementHandler()
        }
    }
    
    func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexSearchableItemsWithIdentifiers identifiers: [String], acknowledgementHandler: @escaping () -> Void) {
        // Would implement selective reindexing here
        acknowledgementHandler()
    }
}

// MARK: - Array Extension for Chunking
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
