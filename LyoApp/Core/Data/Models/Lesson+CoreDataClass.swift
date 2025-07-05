//
//  CDLesson+CoreDataClass.swift
//  LyoApp
//
//  Created by LyoApp Development Team on 12/25/24.
//  Copyright © 2024 LyoApp. All rights reserved.
//

import Foundation
import CoreData
import CloudKit
import SwiftUI

@objc(CDLesson)
public class CDLesson: NSManagedObject {
    
    // MARK: - Enums
    
    enum CDLessonType: String, CaseIterable, Codable {
        case video = "video"
        case text = "text"
        case audio = "audio"
        case interactive = "interactive"
        case quiz = "quiz"
        case assignment = "assignment"
        case live = "live"
        case practice = "practice"
        
        var displayName: String {
            switch self {
            case .video: return "Video"
            case .text: return "Reading"
            case .audio: return "Audio"
            case .interactive: return "Interactive"
            case .quiz: return "Quiz"
            case .assignment: return "Assignment"
            case .live: return "Live Session"
            case .practice: return "Practice"
            }
        }
        
        var icon: String {
            switch self {
            case .video: return "play.circle"
            case .text: return "doc.text"
            case .audio: return "speaker.wave.2"
            case .interactive: return "hand.tap"
            case .quiz: return "questionmark.circle"
            case .assignment: return "doc.badge.plus"
            case .live: return "video.circle"
            case .practice: return "hammer"
            }
        }
        
        var color: Color {
            switch self {
            case .video: return .blue
            case .text: return .primary
            case .audio: return .green
            case .interactive: return .purple
            case .quiz: return .orange
            case .assignment: return .red
            case .live: return .pink
            case .practice: return .mint
            }
        }
    }
    
    enum ContentFormat: String, CaseIterable, Codable {
        case markdown = "markdown"
        case html = "html"
        case json = "json"
        case xml = "xml"
        case plainText = "plain_text"
        
        var displayName: String {
            switch self {
            case .markdown: return "Markdown"
            case .html: return "HTML"
            case .json: return "JSON"
            case .xml: return "XML"
            case .plainText: return "Plain Text"
            }
        }
    }
    
    enum DifficultyLevel: String, CaseIterable, Codable {
        case beginner = "beginner"
        case intermediate = "intermediate"
        case advanced = "advanced"
        
        var displayName: String {
            rawValue.capitalized
        }
        
        var color: Color {
            switch self {
            case .beginner: return .green
            case .intermediate: return .yellow
            case .advanced: return .orange
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// CDLesson type as enum
    var typeEnum: CDLessonType {
        get { CDLessonType(rawValue: type ?? "") ?? .text }
        set { type = newValue.rawValue }
    }
    
    /// Content format as enum
    var contentFormatEnum: ContentFormat {
        get { ContentFormat(rawValue: contentFormat ?? "") ?? .markdown }
        set { contentFormat = newValue.rawValue }
    }
    
    /// Difficulty level as enum
    var difficultyEnum: DifficultyLevel {
        get { DifficultyLevel(rawValue: difficulty ?? "") ?? .beginner }
        set { difficulty = newValue.rawValue }
    }
    
    /// Check if lesson is available for viewing
    var isAvailable: Bool {
        guard let course = course else { return false }
        
        // Check if course is published
        guard course.isAvailable else { return false }
        
        // Check if lesson is published
        guard isPublished else { return false }
        
        // Check publish date
        if let publishDate = publishedAt {
            return publishDate <= Date()
        }
        
        return true
    }
    
    /// Check if lesson is completed by user
    func isCompleted(by user: User) -> Bool {
        guard let progressSet = progress as? Set<Progress> else { return false }
        return progressSet.first { $0.user == user }?.isCompleted == true
    }
    
    /// Get progress for specific user
    func progress(for user: User) -> Progress? {
        guard let progressSet = progress as? Set<Progress> else { return nil }
        return progressSet.first { $0.user == user }
    }
    
    /// Formatted duration string
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    /// Check if lesson has video content
    var hasVideo: Bool {
        return typeEnum == .video && videoURL != nil
    }
    
    /// Check if lesson has audio content
    var hasAudio: Bool {
        return typeEnum == .audio || audioURL != nil
    }
    
    /// Check if lesson requires internet connection
    var requiresInternet: Bool {
        return typeEnum == .live || 
               (hasVideo && !isVideoDownloaded) ||
               (hasAudio && !isAudioDownloaded) ||
               hasExternalLinks
    }
    
    /// Check if lesson content is downloaded for offline viewing
    var isAvailableOffline: Bool {
        return !requiresInternet || 
               (isVideoDownloaded && isAudioDownloaded)
    }
    
    /// Estimated points for completing this lesson
    var pointsReward: Int {
        let basePoints = difficultyEnum == .beginner ? 10 : 
                        difficultyEnum == .intermediate ? 20 : 30
        
        let typeMultiplier = typeEnum == .quiz ? 2 : 
                           typeEnum == .assignment ? 3 : 1
        
        return basePoints * typeMultiplier
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
    
    /// Get parsed lesson content
    func getParsedContent() -> CDLessonContent? {
        guard let contentData = contentData else { return nil }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(CDLessonContent.self, from: contentData)
        } catch {
            print("Failed to decode lesson content: \(error)")
            return nil
        }
    }
    
    /// Set lesson content
    func setContent(_ content: CDLessonContent) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            contentData = try encoder.encode(content)
            lastModified = Date()
        } catch {
            print("Failed to encode lesson content: \(error)")
        }
    }
    
    /// Update lesson content
    func updateContent(title: String? = nil, 
                      body: String? = nil,
                      mediaURL: String? = nil,
                      resources: [CDLessonResource]? = nil) {
        var content = getParsedContent() ?? CDLessonContent()
        
        if let title = title { content.title = title }
        if let body = body { content.body = body }
        if let mediaURL = mediaURL { content.mediaURL = mediaURL }
        if let resources = resources { content.resources = resources }
        
        setContent(content)
    }
    
    // MARK: - Progress Tracking
    
    /// Mark lesson as completed for user
    func markCompleted(for user: User, score: Double? = nil) {
        guard let context = managedObjectContext else { return }
        
        let progress = self.progress(for: user) ?? {
            let newProgress = Progress(context: context)
            newProgress.id = UUID()
            newProgress.user = user
            newProgress.lesson = self
            newProgress.course = course
            return newProgress
        }()
        
        progress.isCompleted = true
        progress.completionPercentage = 100.0
        progress.completedAt = Date()
        progress.lastAccessed = Date()
        
        if let score = score {
            progress.score = score
        }
        
        // Award points to user
        user.totalPointsEarned += Int32(pointsReward)
        
        // Update course progress
        updateCourseProgress(for: user)
        
        addToProgress(progress)
        lastModified = Date()
    }
    
    /// Update lesson progress for user
    func updateProgress(for user: User, 
                       percentage: Double, 
                       timeSpent: TimeInterval = 0) {
        guard let context = managedObjectContext else { return }
        
        let progress = self.progress(for: user) ?? {
            let newProgress = Progress(context: context)
            newProgress.id = UUID()
            newProgress.user = user
            newProgress.lesson = self
            newProgress.course = course
            return newProgress
        }()
        
        progress.completionPercentage = min(100.0, max(0.0, percentage))
        progress.timeSpent += timeSpent
        progress.lastAccessed = Date()
        
        if progress.completionPercentage >= 100.0 && !progress.isCompleted {
            markCompleted(for: user)
        }
        
        addToProgress(progress)
        lastModified = Date()
    }
    
    /// Update course progress based on lesson completion
    private func updateCourseProgress(for user: User) {
        guard let course = course else { return }
        
        let courseProgress = user.progress(for: course)
        let totalCDLessons = course.totalCDLessons
        let completedCDLessons = user.completedCDLessonsCount(for: course)
        
        let completionPercentage = totalCDLessons > 0 ? 
            Double(completedCDLessons) / Double(totalCDLessons) * 100.0 : 0.0
        
        courseProgress?.completionPercentage = completionPercentage
        courseProgress?.isCompleted = completionPercentage >= 100.0
        
        if completionPercentage >= 100.0 {
            courseProgress?.completedAt = Date()
        }
    }
    
    // MARK: - Media Management
    
    /// Download video for offline viewing
    func downloadVideo() async -> Bool {
        guard let videoURL = videoURL, !videoURL.isEmpty else { return false }
        
        // Implementation would go here for actual download
        // This is a placeholder for the download logic
        
        isVideoDownloaded = true
        videoDownloadedAt = Date()
        lastModified = Date()
        
        return true
    }
    
    /// Download audio for offline listening
    func downloadAudio() async -> Bool {
        guard let audioURL = audioURL, !audioURL.isEmpty else { return false }
        
        // Implementation would go here for actual download
        // This is a placeholder for the download logic
        
        isAudioDownloaded = true
        audioDownloadedAt = Date()
        lastModified = Date()
        
        return true
    }
    
    /// Remove downloaded media files
    func removeDownloadedMedia() {
        // Remove video file
        if isVideoDownloaded {
            // Implementation for file removal would go here
            isVideoDownloaded = false
            videoDownloadedAt = nil
        }
        
        // Remove audio file
        if isAudioDownloaded {
            // Implementation for file removal would go here
            isAudioDownloaded = false
            audioDownloadedAt = nil
        }
        
        lastModified = Date()
    }
    
    /// Get local media file path
    func localMediaPath(for mediaType: MediaType) -> URL? {
        guard let id = id else { return nil }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                   in: .userDomainMask).first!
        let mediaPath = documentsPath.appendingPathComponent("media/lessons/\(id.uuidString)")
        
        switch mediaType {
        case .video:
            return mediaPath.appendingPathComponent("video.mp4")
        case .audio:
            return mediaPath.appendingPathComponent("audio.mp3")
        case .thumbnail:
            return mediaPath.appendingPathComponent("thumbnail.jpg")
        }
    }
    
    // MARK: - Search & Analytics
    
    /// Generate searchable content
    var searchableContent: String {
        var content = [String]()
        
        if let title = title { content.append(title) }
        if let summary = summary { content.append(summary) }
        if let tags = tags { content.append(tags) }
        if let lessonContent = getParsedContent() {
            content.append(lessonContent.title)
            content.append(lessonContent.body)
        }
        
        return content.joined(separator: " ")
    }
    
    /// Track lesson view
    func trackView(by user: User) {
        viewCount += 1
        lastViewedAt = Date()
        
        // Update user progress
        updateProgress(for: user, percentage: 0, timeSpent: 0)
        
        lastModified = Date()
    }
    
    // MARK: - Data Validation
    
    func validateCDLessonData() throws {
        guard let title = title, !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw CDLessonValidationError.emptyTitle
        }
        
        guard title.count <= 200 else {
            throw CDLessonValidationError.titleTooLong
        }
        
        guard duration >= 0 else {
            throw CDLessonValidationError.invalidDuration
        }
        
        guard order >= 0 else {
            throw CDLessonValidationError.invalidOrder
        }
        
        if typeEnum == .video && (videoURL?.isEmpty != false) {
            throw CDLessonValidationError.missingVideoURL
        }
        
        if typeEnum == .audio && (audioURL?.isEmpty != false) {
            throw CDLessonValidationError.missingAudioURL
        }
    }
    
    // MARK: - Lifecycle Methods
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        id = UUID()
        createdAt = Date()
        lastModified = Date()
        type = CDLessonType.text.rawValue
        contentFormat = ContentFormat.markdown.rawValue
        difficulty = DifficultyLevel.beginner.rawValue
        isPublished = false
        isRequired = true
        duration = 0
        order = 0
        viewCount = 0
        isVideoDownloaded = false
        isAudioDownloaded = false
        hasExternalLinks = false
    }
    
    public override func willSave() {
        super.willSave()
        
        if hasChanges && !isInserted {
            lastModified = Date()
        }
        
        do {
            try validateCDLessonData()
        } catch {
            print("CDLesson validation failed: \(error)")
        }
    }
}

// MARK: - Supporting Data Structures

struct CDLessonContent: Codable {
    var title: String = ""
    var body: String = ""
    var mediaURL: String? = nil
    var resources: [CDLessonResource] = []
    var quiz: Quiz? = nil
    var assignment: Assignment? = nil
    var interactiveElements: [InteractiveElement] = []
}

struct CDLessonResource: Codable, Identifiable {
    let id = UUID()
    var title: String
    var type: String // "pdf", "link", "video", "audio", "image"
    var url: String
    var description: String?
    var isDownloadable: Bool = false
}

struct Quiz: Codable {
    var questions: [QuizQuestion] = []
    var passingScore: Double = 70.0
    var timeLimit: TimeInterval? = nil
    var allowRetakes: Bool = true
    var maxAttempts: Int = 3
}

// Removed duplicate QuizQuestion - use the canonical one from AppModels.swift

struct Assignment: Codable {
    var title: String
    var description: String
    var instructions: String
    var dueDate: Date?
    var submissionType: String // "text", "file", "url"
    var maxPoints: Int = 100
    var rubric: String?
}

struct InteractiveElement: Codable, Identifiable {
    let id = UUID()
    var type: String // "code_editor", "drag_drop", "simulation"
    var content: String
    var configuration: [String: String] = [:]
}

// Removed duplicate MediaType - use the canonical one from AppModels.swift

// MARK: - Custom Errors

enum CDLessonValidationError: Error, LocalizedError {
    case emptyTitle
    case titleTooLong
    case invalidDuration
    case invalidOrder
    case missingVideoURL
    case missingAudioURL
    
    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "CDLesson title cannot be empty."
        case .titleTooLong:
            return "CDLesson title cannot exceed 200 characters."
        case .invalidDuration:
            return "CDLesson duration cannot be negative."
        case .invalidOrder:
            return "CDLesson order cannot be negative."
        case .missingVideoURL:
            return "Video lessons must have a video URL."
        case .missingAudioURL:
            return "Audio lessons must have an audio URL."
        }
    }
}

// MARK: - Core Data Generated Properties

extension CDLesson {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDLesson> {
        return NSFetchRequest<CDLesson>(entityName: "CDLesson")
    }
    
    // Basic Properties
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var summary: String?
    @NSManaged public var type: String?
    @NSManaged public var contentFormat: String?
    @NSManaged public var difficulty: String?
    @NSManaged public var tags: String?
    
    // Content
    @NSManaged public var contentData: Data?
    @NSManaged public var videoURL: String?
    @NSManaged public var audioURL: String?
    @NSManaged public var thumbnailURL: String?
    
    // Structure
    @NSManaged public var order: Int32
    @NSManaged public var duration: TimeInterval
    @NSManaged public var isRequired: Bool
    @NSManaged public var hasExternalLinks: Bool
    
    // Status
    @NSManaged public var isPublished: Bool
    @NSManaged public var publishedAt: Date?
    
    // Timestamps
    @NSManaged public var createdAt: Date?
    @NSManaged public var lastModified: Date?
    @NSManaged public var lastViewedAt: Date?
    
    // Analytics
    @NSManaged public var viewCount: Int32
    
    // Offline Content
    @NSManaged public var isVideoDownloaded: Bool
    @NSManaged public var isAudioDownloaded: Bool
    @NSManaged public var videoDownloadedAt: Date?
    @NSManaged public var audioDownloadedAt: Date?
    
    // CloudKit
    @NSManaged public var cloudKitRecordData: Data?
    @NSManaged public var cloudKitRecordID: String?
    @NSManaged public var cloudKitSyncDate: Date?
    
    // Relationships
    @NSManaged public var course: CDCourse?
    @NSManaged public var progress: NSSet?
    @NSManaged public var prerequisites: NSSet?
}

// MARK: - Relationship Helpers

extension CDLesson {
    @objc(addProgressObject:)
    @NSManaged public func addToProgress(_ value: CDProgress)
    
    @objc(removeProgressObject:)
    @NSManaged public func removeFromProgress(_ value: CDProgress)
    
    @objc(addProgress:)
    @NSManaged public func addToProgress(_ values: NSSet)
    
    @objc(removeProgress:)
    @NSManaged public func removeFromProgress(_ values: NSSet)
    
    @objc(addPrerequisitesObject:)
    @NSManaged public func addToPrerequisites(_ value: CDLesson)
    
    @objc(removePrerequisitesObject:)
    @NSManaged public func removeFromPrerequisites(_ value: CDLesson)
    
    @objc(addPrerequisites:)
    @NSManaged public func addToPrerequisites(_ values: NSSet)
    
    @objc(removePrerequisites:)
    @NSManaged public func removeFromPrerequisites(_ values: NSSet)
}
