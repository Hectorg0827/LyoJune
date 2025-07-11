import SwiftUI

public struct EducationalVideo: Identifiable, Codable {
    public var id = UUID()
    let title: String
    let author: String
    let category: VideoCategory
    let duration: Int
    let likes: Int
    let comments: Int
    let shares: Int
    let views: Int
    let tags: [String]
    let difficulty: DifficultyLevel
    let videoURL: String?
    let thumbnailURL: String?
    let createdAt: Date
    let updatedAt: Date
    
    public enum DifficultyLevel: String, Codable, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case expert = "Expert"
        
        var color: Color {
            switch self {
            case .beginner: return .green
            case .intermediate: return .yellow
            case .advanced: return .orange
            case .expert: return .red
            }
        }
    }
    
    static func mockVideos(offset: Int = 0) -> [EducationalVideo] {
        let categories = VideoCategory.allCases
        let difficulties = DifficultyLevel.allCases
        let authors = ["Dr. Sarah Chen", "Prof. Alex Johnson", "Maria Garcia", "David Kim", "Lisa Wang", "John Smith", "Emma Brown", "Michael Wilson"]
        
        let videoTitles = [
            "Quick Math: Solving Quadratic Equations",
            "Science Explained: How Photosynthesis Works",
            "Learn Swift in 60 Seconds: Optional Binding",
            "History Minute: The Renaissance Era",
            "Language Tip: French Pronunciation Basics",
            "Physics Fun: Understanding Gravity",
            "Art Technique: Watercolor Blending",
            "Chemistry Quick: Periodic Table Tricks",
            "Biology Basics: Cell Division Process",
            "Coding Tutorial: SwiftUI Animations",
            "Math Magic: Calculus Made Simple",
            "English Grammar: Perfect Tenses",
            "Geography Facts: Mountain Formation",
            "Psychology Insight: Memory Techniques",
            "Music Theory: Understanding Chords",
            "Economics 101: Supply and Demand"
        ]
        
        return (0..<10).map { index in
            let globalIndex = offset + index
            let category = categories[globalIndex % categories.count]
            
            return EducationalVideo(
                title: videoTitles[globalIndex % videoTitles.count],
                author: authors[globalIndex % authors.count],
                category: category,
                duration: Int.random(in: 30...180),
                likes: Int.random(in: 100...2000),
                comments: Int.random(in: 10...500),
                shares: Int.random(in: 5...200),
                views: Int.random(in: 1000...50000),
                tags: category.commonTags.prefix(3).map { String($0) },
                difficulty: difficulties[globalIndex % difficulties.count],
                videoURL: nil,
                thumbnailURL: nil,
                createdAt: Date().addingTimeInterval(-Double.random(in: 0...2592000)),
                updatedAt: Date()
            )
        }
    }
}

public enum VideoCategory: String, Codable, CaseIterable {
    case mathematics = "Mathematics"
    case science = "Science"
    case programming = "Programming"
    case history = "History"
    case language = "Language"
    case physics = "Physics"
    case art = "Art"
    case chemistry = "Chemistry"
    case biology = "Biology"
    case geography = "Geography"
    case psychology = "Psychology"
    case music = "Music"
    case economics = "Economics"
    case literature = "Literature"
    case philosophy = "Philosophy"
    case study = "Study"
    
    var name: String {
        return rawValue
    }
    
    var color: Color {
        switch self {
        case .mathematics: return .blue
        case .science: return .green
        case .programming: return .purple
        case .history: return .brown
        case .language: return .orange
        case .physics: return .cyan
        case .art: return .pink
        case .chemistry: return .yellow
        case .biology: return .mint
        case .geography: return .teal
        case .psychology: return .indigo
        case .music: return .red
        case .economics: return .gray
        case .literature: return .secondary
        case .philosophy: return .primary
        case .study: return .accentColor
        }
    }
    
    var gradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [color, color.opacity(0.7)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var icon: String {
        switch self {
        case .mathematics: return "function"
        case .science: return "atom"
        case .programming: return "chevron.left.forwardslash.chevron.right"
        case .history: return "clock"
        case .language: return "textformat.abc"
        case .physics: return "waveform"
        case .art: return "paintbrush"
        case .chemistry: return "testtube.2"
        case .biology: return "leaf"
        case .geography: return "globe"
        case .psychology: return "brain.head.profile"
        case .music: return "music.note"
        case .economics: return "chart.line.uptrend.xyaxis"
        case .literature: return "book"
        case .philosophy: return "quote.bubble"
        case .study: return "book.closed"
        }
    }
    
    var commonTags: [String] {
        switch self {
        case .mathematics:
            return ["algebra", "calculus", "geometry", "statistics", "numbers"]
        case .science:
            return ["research", "experiment", "discovery", "theory", "facts"]
        case .programming:
            return ["coding", "swift", "ios", "development", "algorithm"]
        case .history:
            return ["ancient", "medieval", "modern", "war", "civilization"]
        case .language:
            return ["grammar", "vocabulary", "pronunciation", "conversation", "fluency"]
        case .physics:
            return ["mechanics", "electricity", "magnetism", "waves", "energy"]
        case .art:
            return ["painting", "drawing", "sculpture", "design", "creativity"]
        case .chemistry:
            return ["reactions", "elements", "molecules", "compounds", "lab"]
        case .biology:
            return ["cells", "genetics", "evolution", "ecosystem", "organisms"]
        case .geography:
            return ["continents", "countries", "climate", "terrain", "maps"]
        case .psychology:
            return ["behavior", "mind", "cognition", "emotion", "therapy"]
        case .music:
            return ["theory", "instruments", "composition", "rhythm", "melody"]
        case .economics:
            return ["market", "finance", "trade", "policy", "business"]
        case .literature:
            return ["poetry", "novels", "drama", "classics", "analysis"]
        case .philosophy:
            return ["ethics", "logic", "metaphysics", "epistemology", "wisdom"]
        case .study:
            return ["learning", "education", "academic", "knowledge", "skills"]
        }
    }
}

public struct Video: Identifiable, Codable {
    public let id: String
    public let title: String
    public let description: String?
    public let author: String
    public let category: VideoCategory
    public let duration: Int
    public let likes: Int
    public let comments: Int
    public let shares: Int
    public let views: Int
    public let tags: [String]
    public let difficulty: EducationalVideo.DifficultyLevel
    public let videoURL: String
    public let thumbnailURL: String?
    public let transcriptAvailable: Bool
    public let createdAt: Date
    public let updatedAt: Date
}

public struct VideoTranscript: Codable, Identifiable {
    public let id: String
    public let videoId: String
    public let language: String
    public var segments: [TranscriptSegment]
    
    public struct TranscriptSegment: Codable {
        public let startTime: Double
        public let endTime: Double
        public let text: String
    }
}

public struct VideoNote: Identifiable, Codable {
    public let id: String
    public let videoId: String
    public let content: String
    public let timestamp: Double
    public let createdAt: Date
    public let updatedAt: Date
}

public struct WatchProgressResponse: Codable {
    public let videoId: String
    public let userId: String
    public let progress: Double
    public let currentTime: Double
    public let watchedAt: Date
}

public struct UpdateWatchProgressRequest: Codable {
    public let videoId: String
    public let progress: Double
    public let currentTime: Double
    public let watchedAt: Date
}

public struct CreateVideoNoteRequest: Codable {
    public let content: String
    public let timestamp: Double
}