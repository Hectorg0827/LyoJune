import SwiftUI
import Foundation

// MARK: - Local Type Definitions for Header UI
// Note: Using canonical types from AppModels.swift for data models

// MARK: - Header State Models

enum HeaderState {
    case minimized
    case expanded
    case storyDrawerOpen
    
    var height: CGFloat {
        switch self {
        case .minimized:
            return 40
        case .expanded, .storyDrawerOpen:
            return 80
        }
    }
    
    var iconScale: CGFloat {
        switch self {
        case .minimized:
            return 0.8
        case .expanded, .storyDrawerOpen:
            return 1.0
        }
    }
    
    var iconOpacity: Double {
        switch self {
        case .minimized:
            return 0.5
        case .expanded, .storyDrawerOpen:
            return 1.0
        }
    }
}

// MARK: - Story Models
// Use canonical Story from AppModels.swift

// Header-specific StoryType values are now part of the canonical StoryType enum

// MARK: - Sample Data
struct HeaderSampleData {
    static let sampleStories: [LearningStory] = [
        LearningStory(
            id: UUID(),
            userId: UUID(),
            username: "alice_learns",
            userAvatar: "https://example.com/avatar1.jpg",
            mediaURL: "https://example.com/story1.mp4",
            mediaType: MediaType.video,
            duration: 15,
            caption: "Learning Swift today!",
            createdAt: Date().addingTimeInterval(-3600),
            viewsCount: 42,
            isViewed: false
        ),
        LearningStory(
            id: UUID(),
            userId: UUID(),
            username: "bob_codes",
            userAvatar: "https://example.com/avatar2.jpg",
            mediaURL: "https://example.com/story2.mp4",
            mediaType: MediaType.video,
            duration: 20,
            caption: "Just completed my first iOS app!",
            createdAt: Date().addingTimeInterval(-7200),
            viewsCount: 68,
            isViewed: false
        ),
        LearningStory(
            id: UUID(),
            userId: UUID(),
            username: "charlie_math",
            userAvatar: "https://example.com/avatar3.jpg",
            mediaURL: "https://example.com/story3.jpg",
            mediaType: MediaType.image,
            duration: TimeInterval(0),
            caption: "Solving calculus problems",
            createdAt: Date().addingTimeInterval(-86400),
            viewsCount: 23,
            isViewed: true
        )
    ]
}

// MARK: - Message Models

struct HeaderConversation: Identifiable, Codable {
    let id: UUID
    let name: String
    let initials: String
    let avatarColors: [String]
    let lastMessage: String
    let timestamp: Date
    var hasUnreadMessages: Bool
    let messageCount: Int
    let conversationType: ConversationType
    let participants: [String]
    
    var colorGradient: [Color] {
        avatarColors.compactMap { hex in
            Color(hex: hex)
        }
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    public enum ConversationType: String, Codable {
        case individual = "individual"
        case group = "group"
        case studyGroup = "study_group"
        case tutoring = "tutoring"
        case announcement = "announcement"
        
        var icon: String {
            switch self {
            case .individual:
                return "person.fill"
            case .group, .studyGroup:
                return "person.2.fill"
            case .tutoring:
                return "graduationcap.fill"
            case .announcement:
                return "megaphone.fill"
            }
        }
    }
    
    static let sampleConversations: [HeaderConversation] = [
        HeaderConversation(
            id: UUID(),
            name: "Swift Study Group",
            initials: "SSG",
            avatarColors: ["3B82F6", "8B5CF6"],
            lastMessage: "Hey everyone! Don't forget about tomorrow's Swift exam review session. We'll be covering optionals and error handling.",
            timestamp: Date().addingTimeInterval(-120),
            hasUnreadMessages: true,
            messageCount: 47,
            conversationType: .studyGroup,
            participants: ["alice", "bob", "charlie", "diana"]
        ),
        HeaderConversation(
            id: UUID(),
            name: "Emma Wilson",
            initials: "EW",
            avatarColors: ["FF6B9D", "A855F7"],
            lastMessage: "Thanks for sharing those calculus notes! They were really helpful for understanding derivatives. Could you send the integration examples too?",
            timestamp: Date().addingTimeInterval(-3600),
            hasUnreadMessages: true,
            messageCount: 12,
            conversationType: .individual,
            participants: ["emma"]
        ),
        HeaderConversation(
            id: UUID(),
            name: "Prof. Johnson",
            initials: "PJ",
            avatarColors: ["10B981", "6EE7B7"],
            lastMessage: "Your machine learning assignment submission was excellent. The neural network implementation showed great understanding of the concepts. Well done!",
            timestamp: Date().addingTimeInterval(-10800),
            hasUnreadMessages: false,
            messageCount: 8,
            conversationType: .individual,
            participants: ["prof_johnson"]
        ),
        HeaderConversation(
            id: UUID(),
            name: "Math Tutoring - Advanced",
            initials: "MTA",
            avatarColors: ["F59E0B", "FCD34D"],
            lastMessage: "Let's schedule our next differential equations session for this weekend. I have some practice problems we can work through together.",
            timestamp: Date().addingTimeInterval(-86400),
            hasUnreadMessages: true,
            messageCount: 23,
            conversationType: .tutoring,
            participants: ["tutor_mike", "student_jane"]
        ),
        HeaderConversation(
            id: UUID(),
            name: "CS Department Updates",
            initials: "CSD",
            avatarColors: ["EF4444", "FB7185"],
            lastMessage: "🎉 New course announcement: Advanced AI and Machine Learning starts next semester. Early bird registration is now open!",
            timestamp: Date().addingTimeInterval(-172800),
            hasUnreadMessages: false,
            messageCount: 3,
            conversationType: .announcement,
            participants: ["cs_admin"]
        ),
        HeaderConversation(
            id: UUID(),
            name: "Physics Lab Partners",
            initials: "PLP",
            avatarColors: ["8B5CF6", "06B6D4"],
            lastMessage: "Great job on the quantum mechanics experiment today! Our results were spot on. Ready for the next lab session?",
            timestamp: Date().addingTimeInterval(-259200),
            hasUnreadMessages: false,
            messageCount: 31,
            conversationType: .group,
            participants: ["alex", "sarah", "mike"]
        )
    ]
}

// MARK: - Search Models

struct SearchSuggestion: Identifiable {
    let id = UUID()
    let query: String
    let category: SearchCategory
    let popularity: Int
    let isPersonalized: Bool
    
    enum SearchCategory: String, CaseIterable {
        case general = "general"
        case science = "science"
        case mathematics = "mathematics"
        case programming = "programming"
        case history = "history"
        case language = "language"
        case art = "art"
        
        var icon: String {
            switch self {
            case .general:
                return "magnifyingglass"
            case .science:
                return "atom"
            case .mathematics:
                return "function"
            case .programming:
                return "chevron.left.forwardslash.chevron.right"
            case .history:
                return "book.closed"
            case .language:
                return "globe"
            case .art:
                return "paintbrush"
            }
        }
        
        var color: Color {
            switch self {
            case .general:
                return .gray
            case .science:
                return .blue
            case .mathematics:
                return .purple
            case .programming:
                return .green
            case .history:
                return .brown
            case .language:
                return .orange
            case .art:
                return .pink
            }
        }
    }
    
    static let sampleSuggestions: [SearchSuggestion] = [
        SearchSuggestion(
            query: "Explain quantum physics fundamentals",
            category: .science,
            popularity: 95,
            isPersonalized: true
        ),
        SearchSuggestion(
            query: "Swift programming best practices",
            category: .programming,
            popularity: 88,
            isPersonalized: true
        ),
        SearchSuggestion(
            query: "Renaissance art history overview",
            category: .history,
            popularity: 76,
            isPersonalized: false
        ),
        SearchSuggestion(
            query: "Calculus integration techniques",
            category: .mathematics,
            popularity: 92,
            isPersonalized: true
        ),
        SearchSuggestion(
            query: "Spanish grammar conjugation rules",
            category: .language,
            popularity: 73,
            isPersonalized: false
        ),
        SearchSuggestion(
            query: "Machine learning algorithms explained",
            category: .programming,
            popularity: 89,
            isPersonalized: true
        )
    ]
}

// MARK: - User Profile Models

struct HeaderUserProfile: Identifiable, Codable {
    let id: UUID
    let username: String
    let displayName: String
    let email: String
    let role: UserRole
    let avatarColors: [String]
    let bio: String
    let joinDate: Date
    let stats: UserStats
    let preferences: UserPreferences
    let achievements: [Achievement]
    let courses: [CDUserCourse]
    
    var colorGradient: [Color] {
        avatarColors.compactMap { hex in
            Color(hex: hex)
        }
    }
    
    var initials: String {
        let components = displayName.components(separatedBy: " ")
        let firstInitial = components.first?.first?.uppercased() ?? ""
        let lastInitial = components.count > 1 ? components.last?.first?.uppercased() ?? "" : ""
        return firstInitial + lastInitial
    }
    
    enum UserRole: String, Codable, CaseIterable {
        case student = "student"
        case educator = "educator"
        case tutor = "tutor"
        case administrator = "administrator"
        
        var displayName: String {
            switch self {
            case .student:
                return "Student"
            case .educator:
                return "Educator"
            case .tutor:
                return "Tutor"
            case .administrator:
                return "Administrator"
            }
        }
        
        var icon: String {
            switch self {
            case .student:
                return "graduationcap"
            case .educator:
                return "person.fill.checkmark"
            case .tutor:
                return "person.fill.questionmark"
            case .administrator:
                return "shield.fill"
            }
        }
    }
    
    struct CDUserCourse: Identifiable, Codable {
        let id: UUID
        let courseId: String
        let title: String
        let progress: Double
        let status: CourseStatus
        let enrollmentDate: Date
        let lastAccessedDate: Date?
        let completionDate: Date?
        
        enum CourseStatus: String, Codable {
            case enrolled = "enrolled"
            case inProgress = "in_progress"
            case completed = "completed"
            case paused = "paused"
        }
    }
    
    static let sampleProfile = HeaderUserProfile(
        id: UUID(),
        username: "john_doe_student",
        displayName: "John Doe",
        email: "john.doe@example.com",
        role: .student,
        avatarColors: ["3B82F6", "8B5CF6"],
        bio: "Passionate learner exploring the intersection of technology and education. Always eager to discover new concepts and share knowledge with fellow students.",
        joinDate: Date().addingTimeInterval(-2592000), // 30 days ago
        stats: UserStats(
            totalStudyTime: 48.5,
            coursesCompleted: 12,
            eventsAttended: 5,
            groupsJoined: 3,
            postsCreated: 15,
            currentStreak: 15,
            longestStreak: 25,
            totalPoints: 12450,
            level: 8,
            rank: 234,
            achievementsCount: 8,
            userId: UUID()
        ),
        preferences: UserPreferences(
            notifications: true,
            darkMode: true,
            language: "en",
            biometricAuth: false,
            pushNotifications: true,
            emailNotifications: true
        ),
        achievements: [],
        courses: [
            CDUserCourse(
                id: UUID(),
                courseId: "swift-101",
                title: "Swift Programming Fundamentals",
                progress: 0.85,
                status: .inProgress,
                enrollmentDate: Date().addingTimeInterval(-1209600),
                lastAccessedDate: Date().addingTimeInterval(-3600),
                completionDate: nil
            ),
            CDUserCourse(
                id: UUID(),
                courseId: "math-calc",
                title: "Calculus I",
                progress: 1.0,
                status: .completed,
                enrollmentDate: Date().addingTimeInterval(-2592000),
                lastAccessedDate: Date().addingTimeInterval(-86400),
                completionDate: Date().addingTimeInterval(-604800)
            )
        ]
    )
}