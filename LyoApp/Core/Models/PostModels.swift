import SwiftUI

// MARK: - Post Model
struct LocalPostModel: Identifiable, Codable {
    var id = UUID()
    let author: String
    let content: String
    let timeAgo: String
    var isLiked: Bool = false
    var likeCount: Int
    var commentCount: Int
    var shareCount: Int
    let hasMedia: Bool
    let mediaTypeString: String? // Changed to avoid conflict
    let category: VideoCategory
    let tags: [String]
    let createdAt: Date
    let updatedAt: Date
    
    // Convert from DiscoverPost
    init(from discoverPost: DiscoverPost) {
        self.id = discoverPost.id
        self.author = discoverPost.author
        self.content = discoverPost.content
        self.timeAgo = discoverPost.timeAgo
        self.likeCount = discoverPost.likes
        self.commentCount = discoverPost.comments
        self.shareCount = discoverPost.shares
        self.hasMedia = discoverPost.hasMedia
        self.mediaTypeString = discoverPost.mediaTypeString
        self.category = discoverPost.category
        self.tags = discoverPost.tags
        self.createdAt = discoverPost.createdAt
        self.updatedAt = discoverPost.updatedAt
    }
    
    static var samplePosts: [LocalPostModel] {
        return DiscoverPost.mockPosts().map { LocalPostModel(from: $0) }
    }
}

struct DiscoverPost: Identifiable, Codable {
    var id = UUID()
    let author: String
    let content: String
    let timeAgo: String
    var likes: Int
    let comments: Int
    var shares: Int
    let hasMedia: Bool
    let mediaTypeString: String? // Changed to string to avoid MediaType conflict
    let category: VideoCategory
    let tags: [String]
    let createdAt: Date
    let updatedAt: Date
    var isLiked: Bool = false
    var isBookmarked: Bool = false
    
    // Computed property for MediaType
    var mediaType: MediaType? {
        guard let mediaTypeString = mediaTypeString else { return nil }
        return MediaType(rawValue: mediaTypeString)
    }
    
    static func mockPosts(offset: Int = 0) -> [DiscoverPost] {
        let authors = [
            "Alex Johnson", "Sam Wilson", "Emma Martinez", "David Chen", "Sarah Kim",
            "Michael Brown", "Lisa Garcia", "James Wilson", "Maria Rodriguez", "John Smith",
            "Emily Davis", "Robert Taylor", "Jennifer Lee", "Christopher Moore", "Amanda Clark"
        ]
        
        let postContents = [
            "Just learned about neural networks today! They're amazing for pattern recognition and machine learning applications. The way they mimic human brain function is fascinating. #AI #MachineLearning #DeepLearning",
            
            "Check out my latest SwiftUI app! Building with declarative syntax is so intuitive and makes iOS development much more enjoyable. The preview system is a game-changer for rapid prototyping.",
            
            "Did you know quantum computers use qubits that can exist in multiple states simultaneously? This quantum superposition allows them to process information exponentially faster than classical computers for certain problems.",
            
            "Finally mastered async/await in Swift! Clean code for asynchronous operations makes concurrent programming so much more readable and maintainable. No more callback hell!",
            
            "Exploring data visualization with Python matplotlib. The possibilities are endless when it comes to creating insightful charts and graphs from complex datasets.",
            
            "The Renaissance period was a time of incredible artistic and scientific advancement. Leonardo da Vinci's notebooks show the intersection of art, science, and engineering that defined this era.",
            
            "Learning French pronunciation has been challenging but rewarding. The nasal sounds and liaison rules are starting to make sense after months of practice.",
            
            "Physics concept of the day: Einstein's theory of relativity shows that time and space are interconnected. Time actually moves slower in stronger gravitational fields!",
            
            "Watercolor techniques for beginners: Start with wet-on-wet for beautiful color blending effects. Control the water content to achieve different textures and transparency levels.",
            
            "Chemistry fun fact: The periodic table's organization reveals patterns in atomic structure. Elements in the same column share similar properties due to their electron configurations.",
            
            "Cell division is one of biology's most fundamental processes. Mitosis ensures genetic information is accurately passed to daughter cells during growth and repair.",
            
            "SwiftUI animations bring apps to life! Using implicit and explicit animations, you can create smooth, delightful user experiences that feel natural and responsive.",
            
            "Calculus made simple: Derivatives measure rates of change, while integrals calculate areas under curves. These concepts have countless real-world applications in science and engineering.",
            
            "English grammar tip: Perfect tenses indicate completed actions. Present perfect connects past actions to present relevance, while past perfect shows earlier completion.",
            
            "Mountain formation occurs through tectonic plate collisions. The Himalayas continue growing as the Indian plate pushes into the Eurasian plate at about 5cm per year."
        ]
        
        let categories = VideoCategory.allCases
        let mediaTypes = MediaType.allCases
        
        return (0..<10).map { index in
            let globalIndex = offset + index
            let category = categories[globalIndex % categories.count]
            let hasMedia = Bool.random()
            
            return DiscoverPost(
                author: authors[globalIndex % authors.count],
                content: postContents[globalIndex % postContents.count],
                timeAgo: timeAgoString(for: globalIndex),
                likes: Int.random(in: 15...500),
                comments: Int.random(in: 2...100),
                shares: Int.random(in: 1...50),
                hasMedia: hasMedia,
                mediaTypeString: hasMedia ? mediaTypes.randomElement()?.rawValue : nil,
                category: category,
                tags: Array(category.commonTags.shuffled().prefix(Int.random(in: 2...4))),
                createdAt: Date().addingTimeInterval(-Double(globalIndex * 3600 + Int.random(in: 0...3600))),
                updatedAt: Date()
            )
        }
    }
    
    private static func timeAgoString(for index: Int) -> String {
        let timeOptions = ["2m", "15m", "1h", "3h", "6h", "12h", "1d", "2d", "3d", "1w"]
        return timeOptions[index % timeOptions.count]
    }
}