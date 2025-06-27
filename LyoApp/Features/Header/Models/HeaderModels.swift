import SwiftUI
import Foundation

// MARK: - Local Type Definitions

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
// Header-specific Story model with properties needed for the header UI

public struct Story: Identifiable, Codable {
    public let id: UUID
    public let username: String
    public let displayName: String
    public let initials: String
    public let avatarColors: [String]
    public let hasUnwatchedStory: Bool
    public let storyType: HeaderStoryType
    public let timestamp: Date
    public let previewImageURL: String?
    
    public init(id: UUID, username: String, displayName: String, initials: String, avatarColors: [String], hasUnwatchedStory: Bool, storyType: HeaderStoryType, timestamp: Date, previewImageURL: String?) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.initials = initials
        self.avatarColors = avatarColors
        self.hasUnwatchedStory = hasUnwatchedStory
        self.storyType = storyType
        self.timestamp = timestamp
        self.previewImageURL = previewImageURL
    }
}

public enum HeaderStoryType: String, Codable, CaseIterable {
    case educational = "educational"
    case achievement = "achievement"
    case social = "social"
    case announcement = "announcement"
    
    var icon: String {
        switch self {
        case .educational:
            return "book.fill"
        case .achievement:
            return "trophy.fill"
        case .social:
            return "person.2.fill"
        case .announcement:
            return "megaphone.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .educational:
            return .blue
        case .achievement:
            return .yellow
        case .social:
            return .green
        case .announcement:
            return .red
        }
    }
}

// MARK: - Sample Data
struct HeaderSampleData {
    static let sampleStories: [Story] = [
        Story(
            id: UUID(),
            username: "alice_learns",
            displayName: "Alice",
            initials: "AL",
            avatarColors: ["FF6B9D", "A855F7"],
            hasUnwatchedStory: true,
            storyType: .educational,
            timestamp: Date().addingTimeInterval(-3600),
            previewImageURL: nil
        ),
        Story(
            id: UUID(),
            username: "bob_codes",
            displayName: "Bob",
            initials: "BO",
            avatarColors: ["3B82F6", "06B6D4"],
            hasUnwatchedStory: true,
            storyType: .achievement,
            timestamp: Date().addingTimeInterval(-7200),
            previewImageURL: nil
        ),
        Story(
            id: UUID(),
            username: "charlie_math",
            displayName: "Charlie",
            initials: "CH",
            avatarColors: ["10B981", "6EE7B7"],
            hasUnwatchedStory: false,
            storyType: .educational,
            timestamp: Date().addingTimeInterval(-86400),
            previewImageURL: nil
        ),
        Story(
            id: UUID(),
            username: "diana_science",
            displayName: "Diana",
            initials: "DI",
            avatarColors: ["F59E0B", "FCD34D"],
            hasUnwatchedStory: true,
            storyType: .social,
            timestamp: Date().addingTimeInterval(-1800),
            previewImageURL: nil
        ),
        Story(
            id: UUID(),
            username: "evan_history",
            displayName: "Evan",
            initials: "EV",
            avatarColors: ["EF4444", "FB7185"],
            hasUnwatchedStory: false,
            storyType: .announcement,
            timestamp: Date().addingTimeInterval(-43200),
            previewImageURL: nil
        ),
        Story(
            id: UUID(),
            username: "fiona_art",
            displayName: "Fiona",
            initials: "FI",
            avatarColors: ["8B5CF6", "3B82F6"],
            hasUnwatchedStory: true,
            storyType: .achievement,
            timestamp: Date().addingTimeInterval(-900),
            previewImageURL: nil
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
    let courses: [UserCourse]
    
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
    
    struct UserStats: Codable {
        let coursesCompleted: Int
        let hoursLearned: Double
        let followersCount: Int
        let followingCount: Int
        let streakDays: Int
        let averageScore: Double
        let totalPoints: Int
    }
    
    struct UserCourse: Identifiable, Codable {
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
            coursesCompleted: 12,
            hoursLearned: 48.5,
            followersCount: 234,
            followingCount: 189,
            streakDays: 15,
            averageScore: 87.5,
            totalPoints: 12450
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
            UserCourse(
                id: UUID(),
                courseId: "swift-101",
                title: "Swift Programming Fundamentals",
                progress: 0.85,
                status: .inProgress,
                enrollmentDate: Date().addingTimeInterval(-1209600),
                lastAccessedDate: Date().addingTimeInterval(-3600),
                completionDate: nil
            ),
            UserCourse(
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

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}