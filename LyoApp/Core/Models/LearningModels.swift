import SwiftUI
import MapKit

// MARK: - Course Models

struct Course: Identifiable, Codable {
    var id = UUID()
    let title: String
    let description: String
    let instructor: String
    let duration: String
    let rating: Double
    let category: VideoCategory
    let difficulty: EducationalVideo.DifficultyLevel
    let lessons: [Lesson]
    let estimatedHours: Double
    let thumbnailURL: String?
    let enrollmentCount: Int
    let price: Double?
    let isEnrolled: Bool
    let progress: Double
    let createdAt: Date
    let updatedAt: Date
    
    static func mockCourses() -> [Course] {
        let categories = VideoCategory.allCases
        let difficulties = EducationalVideo.DifficultyLevel.allCases
        let instructors = ["Dr. Sarah Chen", "Prof. Alex Johnson", "Maria Garcia", "David Kim", "Lisa Wang"]
        
        let courseTitles = [
            "Swift Programming Fundamentals",
            "SwiftUI Complete Guide", 
            "Machine Learning with Python",
            "Data Science Essentials",
            "iOS App Development",
            "Web Development Bootcamp",
            "Digital Marketing Mastery",
            "Photography Basics",
            "Graphic Design Principles",
            "Public Speaking Excellence"
        ]
        
        return (0..<10).map { index in
            Course(
                title: courseTitles[index % courseTitles.count],
                description: "Learn the fundamentals and advanced concepts of \(courseTitles[index % courseTitles.count])",
                instructor: instructors[index % instructors.count],
                duration: "\(Int.random(in: 4...16)) weeks",
                rating: Double.random(in: 4.0...5.0),
                category: categories[index % categories.count],
                difficulty: difficulties[index % difficulties.count],
                lessons: Lesson.mockLessons(),
                estimatedHours: Double.random(in: 20...100),
                thumbnailURL: nil,
                enrollmentCount: Int.random(in: 100...5000),
                price: Bool.random() ? Double.random(in: 29.99...199.99) : nil,
                isEnrolled: Bool.random(),
                progress: Double.random(in: 0...1),
                createdAt: Date().addingTimeInterval(-Double.random(in: 0...31536000)),
                updatedAt: Date()
            )
        }
    }
}

struct Lesson: Identifiable, Codable {
    var id = UUID()
    let title: String
    let description: String
    let duration: Int // in minutes
    let videoURL: String?
    let isCompleted: Bool
    let order: Int
    let quiz: Quiz?
    
    static func mockLessons() -> [Lesson] {
        return (1...8).map { index in
            Lesson(
                title: "Lesson \(index): Core Concepts",
                description: "Learn the essential concepts and practical applications",
                duration: Int.random(in: 15...45),
                videoURL: nil,
                isCompleted: Bool.random(),
                order: index,
                quiz: Bool.random() ? Quiz.mockQuiz() : nil
            )
        }
    }
}

struct Quiz: Identifiable, Codable {
    var id = UUID()
    let title: String
    let questions: [QuizQuestion]
    let timeLimit: Int? // in minutes
    let passingScore: Double
    
    static func mockQuiz() -> Quiz {
        Quiz(
            title: "Knowledge Check",
            questions: QuizQuestion.mockQuestions(),
            timeLimit: 15,
            passingScore: 0.8
        )
    }
}

struct QuizQuestion: Identifiable, Codable {
    var id = UUID()
    let question: String
    let options: [String]
    let correctAnswerIndex: Int
    let explanation: String?
    
    static func mockQuestions() -> [QuizQuestion] {
        return [
            QuizQuestion(
                question: "What is the primary purpose of this concept?",
                options: ["Option A", "Option B", "Option C", "Option D"],
                correctAnswerIndex: 1,
                explanation: "This is the correct answer because..."
            ),
            QuizQuestion(
                question: "Which approach is recommended?",
                options: ["Approach 1", "Approach 2", "Approach 3"],
                correctAnswerIndex: 0,
                explanation: "This approach is recommended due to..."
            )
        ]
    }
}

// MARK: - Learning Path Models

struct LearningPath: Identifiable, Codable {
    var id = UUID()
    let title: String
    let description: String
    let courses: [Course]
    let estimatedDuration: String
    let difficulty: EducationalVideo.DifficultyLevel
    let category: VideoCategory
    let totalCourses: Int
    let completedCourses: Int
    let progress: Double
    let createdAt: Date
    
    static func mockPaths() -> [LearningPath] {
        let categories = VideoCategory.allCases
        let difficulties = EducationalVideo.DifficultyLevel.allCases
        
        let pathTitles = [
            "iOS Developer Path",
            "Data Scientist Journey",
            "Web Development Track",
            "Digital Marketing Expert",
            "UI/UX Designer Path"
        ]
        
        return (0..<5).map { index in
            let totalCourses = Int.random(in: 3...8)
            let completedCourses = Int.random(in: 0...totalCourses)
            
            return LearningPath(
                title: pathTitles[index % pathTitles.count],
                description: "Complete learning path for \(pathTitles[index % pathTitles.count])",
                courses: Course.mockCourses().prefix(totalCourses).map { $0 },
                estimatedDuration: "\(totalCourses * 6) weeks",
                difficulty: difficulties[index % difficulties.count],
                category: categories[index % categories.count],
                totalCourses: totalCourses,
                completedCourses: completedCourses,
                progress: Double(completedCourses) / Double(totalCourses),
                createdAt: Date().addingTimeInterval(-Double.random(in: 0...31536000))
            )
        }
    }
}

// MARK: - Progress Models

struct UserProgress: Codable {
    let totalHours: Double
    let completedCourses: Int
    let averageScore: Double
    let currentStreak: Int
    let longestStreak: Int
    let recentAchievements: [Achievement]
    let learningGoals: [LearningGoal]
    let weeklyGoal: Int
    let weeklyProgress: Double
    
    static func mockProgress() -> UserProgress {
        UserProgress(
            totalHours: Double.random(in: 50...500),
            completedCourses: Int.random(in: 5...50),
            averageScore: Double.random(in: 70...95),
            currentStreak: Int.random(in: 1...30),
            longestStreak: Int.random(in: 5...100),
            recentAchievements: Achievement.mockAchievements(),
            learningGoals: LearningGoal.mockGoals(),
            weeklyGoal: Int.random(in: 3...10),
            weeklyProgress: Double.random(in: 0...1)
        )
    }
}

struct Achievement: Identifiable, Codable {
    var id = UUID()
    let title: String
    let description: String
    let icon: String
    let colorName: String
    let earnedAt: Date
    let rarity: Rarity
    
    var color: Color {
        switch colorName {
        case "yellow": return .yellow
        case "orange": return .orange
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue
        }
    }
    
    enum Rarity: String, Codable {
        case common = "Common"
        case rare = "Rare"
        case epic = "Epic"
        case legendary = "Legendary"
    }
    
    static func mockAchievements() -> [Achievement] {
        return [
            Achievement(
                title: "First Course",
                description: "Completed your first course",
                icon: "star.fill",
                colorName: "yellow",
                earnedAt: Date().addingTimeInterval(-86400),
                rarity: .common
            ),
            Achievement(
                title: "Week Warrior",
                description: "Studied for 7 days straight",
                icon: "flame.fill",
                colorName: "orange",
                earnedAt: Date().addingTimeInterval(-172800),
                rarity: .rare
            ),
            Achievement(
                title: "Knowledge Seeker",
                description: "Completed 10 courses",
                icon: "book.fill",
                colorName: "blue",
                earnedAt: Date().addingTimeInterval(-259200),
                rarity: .epic
            )
        ]
    }
}

struct LearningGoal: Identifiable, Codable {
    var id = UUID()
    let title: String
    let description: String
    let targetValue: Int
    let currentValue: Int
    let progress: Double
    let deadline: Date?
    let category: VideoCategory
    
    static func mockGoals() -> [LearningGoal] {
        let categories = VideoCategory.allCases
        
        return [
            LearningGoal(
                title: "Master Swift Programming",
                description: "Complete Swift fundamentals course",
                targetValue: 100,
                currentValue: 65,
                progress: 0.65,
                deadline: Date().addingTimeInterval(2592000),
                category: categories[0]
            ),
            LearningGoal(
                title: "Complete ML Course",
                description: "Finish machine learning basics",
                targetValue: 100,
                currentValue: 30,
                progress: 0.3,
                deadline: Date().addingTimeInterval(5184000),
                category: categories[1]
            ),
            LearningGoal(
                title: "Learn SwiftUI",
                description: "Build iOS apps with SwiftUI",
                targetValue: 100,
                currentValue: 80,
                progress: 0.8,
                deadline: Date().addingTimeInterval(1296000),
                category: categories[2]
            )
        ]
    }
}

// MARK: - Community Models

struct CommunityEvent: Identifiable, Codable {
    var id = UUID()
    let title: String
    let description: String
    let organizer: String
    let date: String
    let location: String
    let attendees: Int
    let maxAttendees: Int?
    let category: VideoCategory
    let isOnline: Bool
    let price: Double?
    
    static func mockEvents() -> [CommunityEvent] {
        let categories = VideoCategory.allCases
        let organizers = ["Tech Hub", "Learning Center", "Study Group", "Local Library", "Community College"]
        
        let eventTitles = [
            "iOS Development Workshop",
            "Machine Learning Study Group", 
            "Python Programming Bootcamp",
            "Design Thinking Session",
            "Data Science Meetup"
        ]
        
        return (0..<5).map { index in
            CommunityEvent(
                title: eventTitles[index % eventTitles.count],
                description: "Join us for an engaging learning session about \(eventTitles[index % eventTitles.count])",
                organizer: organizers[index % organizers.count],
                date: "Dec \(15 + index), 2024",
                location: Bool.random() ? "Online" : "Downtown Learning Center",
                attendees: Int.random(in: 5...50),
                maxAttendees: Int.random(in: 20...100),
                category: categories[index % categories.count],
                isOnline: Bool.random(),
                price: Bool.random() ? Double.random(in: 10...50) : nil
            )
        }
    }
}

struct StudyGroup: Identifiable, Codable {
    var id = UUID()
    let name: String
    let description: String
    let category: VideoCategory
    let members: Int
    let maxMembers: Int
    let meetingFrequency: String
    let isPrivate: Bool
    let isActive: Bool
    let rating: Double
    let tags: [String]
    let adminId: String
    
    static func mockGroups() -> [StudyGroup] {
        let categories = VideoCategory.allCases
        
        let groupNames = [
            "Swift Developers",
            "ML Enthusiasts",
            "Web Dev Community",
            "Design Thinkers",
            "Data Scientists"
        ]
        
        return (0..<5).map { index in
            StudyGroup(
                name: groupNames[index % groupNames.count],
                description: "A community for learning and sharing knowledge about \(groupNames[index % groupNames.count])",
                category: categories[index % categories.count],
                members: Int.random(in: 10...100),
                maxMembers: Int.random(in: 50...200),
                meetingFrequency: ["Weekly", "Bi-weekly", "Monthly"][index % 3],
                isPrivate: Bool.random(),
                isActive: Bool.random(),
                rating: Double.random(in: 3.5...5.0),
                tags: categories[index % categories.count].commonTags.prefix(3).map { String($0) },
                adminId: "admin_\(index)"
            )
        }
    }
}

struct LearningLocation: Identifiable {
    var id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let type: LocationType
    let description: String
    let rating: Double
    let amenities: [String]
    
    enum LocationType: String, CaseIterable {
        case library = "Library"
        case coworkingSpace = "Co-working Space"
        case cafe = "Cafe"
        case university = "University"
        case studyHall = "Study Hall"
        
        var icon: String {
            switch self {
            case .library: return "book"
            case .coworkingSpace: return "desktopcomputer"
            case .cafe: return "cup.and.saucer"
            case .university: return "graduationcap"
            case .studyHall: return "person.2.gobackward"
            }
        }
        
        var color: Color {
            switch self {
            case .library: return .blue
            case .coworkingSpace: return .purple
            case .cafe: return .brown
            case .university: return .green
            case .studyHall: return .orange
            }
        }
    }
    
    static func mockLocations() -> [LearningLocation] {
        let types = LocationType.allCases
        let baseCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        let locationNames = [
            "Central Library",
            "Tech Hub Co-working",
            "Study Cafe Downtown",
            "University Campus",
            "Community Study Hall"
        ]
        
        return (0..<5).map { index in
            LearningLocation(
                name: locationNames[index % locationNames.count],
                coordinate: CLLocationCoordinate2D(
                    latitude: baseCoordinate.latitude + Double.random(in: -0.05...0.05),
                    longitude: baseCoordinate.longitude + Double.random(in: -0.05...0.05)
                ),
                type: types[index % types.count],
                description: "Great place for studying and learning",
                rating: Double.random(in: 3.5...5.0),
                amenities: ["WiFi", "Power Outlets", "Quiet Environment"].shuffled().prefix(2).map { String($0) }
            )
        }
    }
}

// MARK: - Profile Models

struct RecentActivity: Identifiable, Codable {
    var id = UUID()
    let title: String
    let description: String
    let type: ActivityType
    let timeAgo: String
    let relatedId: String?
    
    enum ActivityType: String, Codable, CaseIterable {
        case courseCompleted = "Course Completed"
        case lessonFinished = "Lesson Finished"
        case achievementEarned = "Achievement Earned"
        case goalReached = "Goal Reached"
        case studySessionCompleted = "Study Session"
        
        var icon: String {
            switch self {
            case .courseCompleted: return "checkmark.circle.fill"
            case .lessonFinished: return "play.circle.fill"
            case .achievementEarned: return "star.fill"
            case .goalReached: return "target"
            case .studySessionCompleted: return "clock.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .courseCompleted: return .green
            case .lessonFinished: return .blue
            case .achievementEarned: return .yellow
            case .goalReached: return .purple
            case .studySessionCompleted: return .orange
            }
        }
    }
    
    static func mockActivities() -> [RecentActivity] {
        let types = ActivityType.allCases
        
        return (0..<5).map { index in
            let type = types[index % types.count]
            return RecentActivity(
                title: type.rawValue,
                description: "You recently completed this activity",
                type: type,
                timeAgo: ["\(index + 1)h", "\(index + 1)d", "1w"][min(index, 2)],
                relatedId: "item_\(index)"
            )
        }
    }
}