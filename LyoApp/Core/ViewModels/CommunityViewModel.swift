import SwiftUI
import Combine
import CoreLocation
import Foundation

// MARK: - CoreLocation Extensions
extension CLLocationCoordinate2D: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
    static let dataSynced = Notification.Name("dataSynced")
    static let showError = Notification.Name("showError")
}

// MARK: - Community Type Definitions
public struct CommunityEvent: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let date: Date
    public let location: String
    public let organizer: String
    public let category: EventCategory
    public var attendees: Int
    public let maxAttendees: Int?
    public var isJoined: Bool
    public var isUserAttending: Bool
    
    public init(title: String, description: String, date: Date, location: String, organizer: String = "Community", category: EventCategory = .study, attendees: Int = 0, maxAttendees: Int? = nil, isJoined: Bool = false, isUserAttending: Bool = false) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.date = date
        self.location = location
        self.organizer = organizer
        self.category = category
        self.attendees = attendees
        self.maxAttendees = maxAttendees
        self.isJoined = isJoined
        self.isUserAttending = isUserAttending
    }
}

public enum EventCategory: String, CaseIterable, Codable {
    case study = "study"
    case social = "social"
    case workshop = "workshop"
    case exam = "exam"
    case project = "project"
}

struct LearningLocation: Identifiable, Codable {
    let id: UUID
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let type: LocationType
    let rating: Double
    let studySpots: Int
    let amenities: [String]
    
    init(name: String, address: String, coordinate: CLLocationCoordinate2D, type: LocationType, rating: Double = 4.0, studySpots: Int = 10, amenities: [String] = []) {
        self.id = UUID()
        self.name = name
        self.address = address
        self.coordinate = coordinate
        self.type = type
        self.rating = rating
        self.studySpots = studySpots
        self.amenities = amenities
    }
}

enum LocationType: String, CaseIterable, Codable {
    case library = "library"
    case cafe = "cafe"
    case campus = "campus"
    case coworking = "coworking"
    case park = "park"
    
    var color: Color {
        switch self {
        case .library:
            return .blue
        case .cafe:
            return .brown
        case .campus:
            return .green
        case .coworking:
            return .purple
        case .park:
            return .mint
        }
    }
    
    var icon: String {
        switch self {
        case .library:
            return "books.vertical"
        case .cafe:
            return "cup.and.saucer"
        case .campus:
            return "building.columns"
        case .coworking:
            return "person.2.square.stack"
        case .park:
            return "tree"
        }
    }
}

// MARK: - CommunityViewModel
@MainActor
class CommunityViewModel: ObservableObject {
    @Published var localEvents: [CommunityEvent] = []
    @Published var studyGroups: [StudyGroup] = []
    @Published var learningLocations: [LearningLocation] = []
    @Published var leaderboard: [LeaderboardUser] = []
    @Published var userStats: UserStats?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUserRank: LeaderboardUser?
    @Published var selectedTimeframe = "week"
    @Published var isOffline = false
    @Published var lastSyncTime: Date?
    @Published var syncProgress: Double = 0.0
    
    private var cancellables = Set<AnyCancellable>()
    private let apiService: EnhancedNetworkManager
    private let coreDataManager: BasicCoreDataManager
    private let webSocketManager: WebSocketManager
    
    // MARK: - Initialization
    init(serviceFactory: EnhancedServiceFactory = .shared) {
        self.apiService = serviceFactory.apiService
        self.coreDataManager = serviceFactory.coreDataManager
        self.webSocketManager = serviceFactory.webSocketManager
        
        setupNotifications()
        setupWebSocketListeners()
        loadCachedData()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Setup Methods
    private func setupWebSocketListeners() {
        webSocketManager.$lastMessage
            .compactMap { message in message }
            .sink { [weak self] message in
                self?.handleWebSocketMessage(message)
            }
            .store(in: &cancellables)
    }
    
    private func handleWebSocketMessage(_ message: WebSocketMessage) {
        switch message.type {
        case .liveUpdate:
            Task { await loadData() }
        case .userUpdate:
            Task { await loadLeaderboard() }
        case .notification:
            Task { await loadStudyGroups() }
        case .chat:
            break
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .networkStatusChanged)
            .sink { [weak self] notification in
                if let isConnected = notification.object as? Bool {
                    self?.isOffline = !isConnected
                    if isConnected {
                        Task { await self?.syncData() }
                    }
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .userDidLogin)
            .sink { [weak self] _ in
                Task {
                    await self?.loadData()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .dataSynced)
            .sink { [weak self] notification in
                if let syncType = notification.object as? String, syncType == "community" {
                    Task {
                        await self?.loadData()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadCachedData() {
        // Load cached community data - using empty data for now
        self.localEvents = []
        self.studyGroups = []
        self.leaderboard = []
        self.lastSyncTime = Date()
        
        // Load mock learning locations for now
        learningLocations = []
    }
    
    // MARK: - Public Methods
    func loadData() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        syncProgress = 0.0
        
        do {
            // Load data concurrently using Task.group
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadEvents() }
                group.addTask { await self.loadStudyGroups() }
                group.addTask { await self.loadLeaderboard() }
                group.addTask { await self.loadUserStats() }
                
                // Wait for all tasks to complete
                try await group.waitForAll()
            }
            
            await syncData()
            
        } catch {
            errorMessage = error.localizedDescription
            NotificationCenter.default.post(name: .showError, object: error)
        }
        
        isLoading = false
        syncProgress = 1.0
    }
    
    func refreshData() async {
        localEvents.removeAll()
        studyGroups.removeAll()
        leaderboard.removeAll()
        userStats = nil
        await loadData()
    }
    
    func syncData() async {
        guard !isOffline else { return }
        
        do {
            // Simulate sync for now
            lastSyncTime = Date()
            print("Community data synced")
            
            NotificationCenter.default.post(name: .dataSynced, object: "community")
        }
    }
    
    func joinEvent(_ event: CommunityEvent) async {
        // Simulate API call for now
        print("Joining event: \(event.title)")
        
        // Update event attendance locally
        if let index = localEvents.firstIndex(where: { $0.id == event.id }) {
            localEvents[index].attendees += 1
            localEvents[index].isUserAttending = true
        }
        
        // Track analytics - simplified for now
        print("Analytics: event_joined - \(event.title)")
        
        // Cache updated data - simplified for now
        print("Cached updated events")
    }
    
    func leaveEvent(_ event: CommunityEvent) async {
        // Implementation would depend on API - for now, optimistic update
        if let index = localEvents.firstIndex(where: { $0.id == event.id }) {
            localEvents[index].attendees -= 1
            localEvents[index].isUserAttending = false
        }
    }
    
    func joinStudyGroup(_ group: StudyGroup) async {
        // Simulate API call for now
        print("Joining study group: \(group.name)")
        
        // Update group membership locally
        if let index = studyGroups.firstIndex(where: { $0.id == group.id }) {
            studyGroups[index].memberCount += 1
            studyGroups[index].isUserMember = true
        }
        
        // Track analytics - simplified for now
        print("Analytics: study_group_joined - \(group.name)")
        
        // Cache updated data - simplified for now
        print("Cached updated study groups")
    }
    
    func leaveStudyGroup(_ group: StudyGroup) async {
        do {
            // Simulate API call for now
            print("Leaving study group: \(group.name)")
            
            // Update group membership locally
            if let index = studyGroups.firstIndex(where: { $0.id == group.id }) {
                studyGroups[index].memberCount -= 1
                studyGroups[index].isUserMember = false
            }
            
            // Cache updated data - simplified for now
            print("Cached updated study groups")
            
        } catch {
            errorMessage = "Failed to leave study group: \(error.localizedDescription)"
        }
    }
    
    func createStudyGroup(name: String, description: String, isPrivate: Bool, category: String) async {
        do {
            // Create mock study group for now
            var newGroup = StudyGroup(
                id: UUID(),
                name: name,
                description: description,
                category: category,
                memberCount: 1,
                maxMembers: 20,
                isPrivate: isPrivate,
                createdBy: UUID(),
                createdAt: Date(),
                imageURL: nil,
                tags: [],
                membershipStatus: .member
            )
            newGroup.isUserMember = true
            
            // Add to beginning of list
            studyGroups.insert(newGroup, at: 0)
            
            // Track analytics - simplified for now
            print("Analytics: study_group_created - \(name)")
            
            // Cache updated data - simplified for now
            print("Cached updated study groups")
            
        } catch {
            errorMessage = "Failed to create study group: \(error.localizedDescription)"
        }
    }
    
    func createEvent(
        title: String,
        description: String,
        date: Date,
        location: String,
        isOnline: Bool,
        maxAttendees: Int,
        category: EventCategory
    ) async {
        do {
            // Create mock event for now
            let newEvent = CommunityEvent(
                title: title,
                description: description,
                date: date,
                location: location,
                category: category,
                attendees: 1,
                maxAttendees: maxAttendees,
                isJoined: true,
                isUserAttending: true
            )
            
            // Add to beginning of list
            localEvents.insert(newEvent, at: 0)
            
            // Track analytics - simplified for now
            print("Analytics: community_event_created - \(title)")
            
            // Cache updated data - simplified for now
            print("Cached updated events")
            
        } catch {
            errorMessage = "Failed to create event: \(error.localizedDescription)"
        }
    }
    
    func updateLeaderboardTimeframe(_ timeframe: String) async {
        selectedTimeframe = timeframe
        await loadLeaderboard()
    }
    
    // MARK: - Private Methods
    private func loadEvents() async {
        do {
            // Mock events for now
            localEvents = []
            print("Loaded community events")
        } catch {
            errorMessage = "Failed to load events: \(error.localizedDescription)"
            loadCachedEvents()
        }
    }
    
    private func loadStudyGroups() async {
        do {
            // Mock study groups for now
            studyGroups = []
            print("Loaded study groups")
        } catch {
            errorMessage = "Failed to load study groups: \(error.localizedDescription)"
            loadCachedStudyGroups()
        }
    }
    
    private func loadLeaderboard() async {
        do {
            // Mock leaderboard for now
            leaderboard = []
            print("Loaded leaderboard")
        } catch {
            errorMessage = "Failed to load leaderboard: \(error.localizedDescription)"
            loadCachedLeaderboard()
        }
    }
    
    private func loadUserStats() async {
        do {
            // Mock user stats for now
            userStats = UserStats(
                totalStudyTime: 0,
                coursesCompleted: 0,
                eventsAttended: 0,
                groupsJoined: 0,
                postsCreated: 0,
                currentStreak: 0,
                longestStreak: 0,
                totalPoints: 0,
                level: 1,
                rank: 1,
                achievementsCount: 0
            )
            print("Loaded user stats")
        } catch {
            errorMessage = "Failed to load user stats: \(error.localizedDescription)"
            loadCachedUserStats()
        }
    }
    
    private func loadCachedEvents() {
        if let cached = coreDataManager.fetchCachedCommunityEvents() {
            localEvents = cached
        }
    }
    
    private func loadCachedStudyGroups() {
        if let cached = coreDataManager.fetchCachedStudyGroups() {
            studyGroups = cached
        }
    }
    
    private func loadCachedLeaderboard() {
        if let cached = coreDataManager.fetchCachedLeaderboard() {
            leaderboard = cached
        }
    }
    
    private func loadCachedUserStats() {
        if let cached = coreDataManager.fetchCachedUserStats() {
            userStats = cached
        }
    }
}

// MARK: - Helper Extensions
extension DateFormatter {
    static let eventDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - User Stats Model
public struct UserStats: Codable {
    public let totalStudyTime: Double
    public let coursesCompleted: Int
    public let eventsAttended: Int
    public let groupsJoined: Int
    public let postsCreated: Int
    public let currentStreak: Int
    public let longestStreak: Int
    public let totalPoints: Int
    public let level: Int
    public let rank: Int
    public let achievementsCount: Int
    public let userId: UUID = UUID()
}

// MARK: - Leaderboard Model
public struct LeaderboardUser: Codable, Identifiable {
    public let id: UUID
    public let username: String
    public let displayName: String
    public let avatarURL: String?
    public let totalPoints: Int
    public let level: Int
    public let rank: Int
    public let streak: Int
}