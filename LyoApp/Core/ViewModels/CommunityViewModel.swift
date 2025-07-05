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
    @Published var currentCDUserRank: LeaderboardUser?
    @Published var selectedTimeframe = "week"
    @Published var isOffline = false
    @Published var lastSyncTime: Date?
    @Published var syncProgress: Double = 0.0
    
    private var cancellables = Set<AnyCancellable>()
    private let apiService: EnhancedNetworkManager
    private let coreDataManager: DataManager
    private let webSocketManager: WebSocketManager
    private let analyticsManager = AnalyticsAPIService.shared
    
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
        NotificationCenter.default.publisher(for: Constants.NotificationNames.networkStatusChanged)
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
        // Load cached community data from CoreData
        loadCachedEvents()
        loadCachedStudyGroups()
        loadCachedLeaderboard()
        self.lastSyncTime = Date()
        
        // Load learning locations from CoreData
        learningLocations = [] // TODO: Implement fetchCachedLearningLocations in DataManager
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
            // Sync community data with backend
            try await apiService.syncCommunityData()
            
            DispatchQueue.main.async {
                self.lastSyncTime = Date()
            }
            
            print("Community data synced successfully")
            NotificationCenter.default.post(name: .dataSynced, object: "community")
            
        } catch {
            print("Failed to sync community data: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Sync failed: \(error.localizedDescription)"
            }
        }
    }
    
    func joinEvent(_ event: CommunityEvent) async {
        do {
            try await apiService.joinCommunityEvent(eventId: event.id)
            
            // Update event attendance locally
            DispatchQueue.main.async {
                if let index = self.localEvents.firstIndex(where: { $0.id == event.id }) {
                    self.localEvents[index].attendees += 1
                    self.localEvents[index].isUserAttending = true
                }
            }
            
            // Track analytics
            Task { 
                await analyticsManager.trackEvent("event_joined", parameters: [
                    "event_id": event.id.uuidString,
                    "event_title": event.title,
                    "event_category": event.category.rawValue
                ])
            }
            
            // Cache updated data
            coreDataManager.cacheCommunityEvents(localEvents)
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to join event: \(error.localizedDescription)"
            }
            print("Error joining event: \(error)")
        }
    }
    
    func leaveEvent(_ event: CommunityEvent) async {
        do {
            try await apiService.leaveCommunityEvent(eventId: event.id)
            
            // Update event attendance locally
            DispatchQueue.main.async {
                if let index = self.localEvents.firstIndex(where: { $0.id == event.id }) {
                    self.localEvents[index].attendees -= 1
                    self.localEvents[index].isUserAttending = false
                }
            }
            
            // Track analytics
            Task { 
                await analyticsManager.trackEvent("event_left", parameters: [
                    "event_id": event.id.uuidString,
                    "event_title": event.title
                ])
            }
            
            // Cache updated data
            coreDataManager.cacheCommunityEvents(localEvents)
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to leave event: \(error.localizedDescription)"
            }
            print("Error leaving event: \(error)")
        }
    }
    
    func joinStudyGroup(_ group: StudyGroup) async {
        do {
            try await apiService.joinStudyGroup(groupId: group.id)
            
            // Update group membership locally
            DispatchQueue.main.async {
                if let index = self.studyGroups.firstIndex(where: { $0.id == group.id }) {
                    self.studyGroups[index].memberCount += 1
                    self.studyGroups[index].isUserMember = true
                }
            }
            
            // Track analytics
            Task { 
                await analyticsManager.trackEvent("study_group_joined", parameters: [
                    "group_id": group.id.uuidString,
                    "group_name": group.name,
                    "group_category": group.category.rawValue
                ])
            }
            
            // Cache updated data
            coreDataManager.cacheStudyGroups(studyGroups)
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to join study group: \(error.localizedDescription)"
            }
            print("Error joining study group: \(error)")
        }
    }
    
    func leaveStudyGroup(_ group: StudyGroup) async {
        do {
            try await apiService.leaveStudyGroup(groupId: group.id)
            
            // Update group membership locally
            DispatchQueue.main.async {
                if let index = self.studyGroups.firstIndex(where: { $0.id == group.id }) {
                    self.studyGroups[index].memberCount -= 1
                    self.studyGroups[index].isUserMember = false
                }
            }
            
            // Track analytics
            Task { 
                await analyticsManager.trackEvent("study_group_left", parameters: [
                    "group_id": group.id.uuidString,
                    "group_name": group.name
                ])
            }
            
            // Cache updated data
            coreDataManager.cacheStudyGroups(studyGroups)
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to leave study group: \(error.localizedDescription)"
            }
            print("Error leaving study group: \(error)")
        }
    }
    
    func createStudyGroup(name: String, description: String, isPrivate: Bool, category: CourseCategory) async {
        do {
            let newGroup = try await apiService.createStudyGroup(
                name: name,
                description: description,
                isPrivate: isPrivate,
                category: category,
                maxMembers: 20
            )
            
            // Add to beginning of list
            DispatchQueue.main.async {
                self.studyGroups.insert(newGroup, at: 0)
            }
            
            // Track analytics
            Task { 
                await analyticsManager.trackEvent("study_group_created", parameters: [
                    "name": name,
                    "category": category.rawValue,
                    "is_private": isPrivate ? "true" : "false"
                ])
            }
            
            // Cache updated data
            coreDataManager.cacheStudyGroups(studyGroups)
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to create study group: \(error.localizedDescription)"
            }
            print("Error creating study group: \(error)")
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
            let newEvent = try await apiService.createCommunityEvent(
                title: title,
                description: description,
                date: date,
                location: location,
                isOnline: isOnline,
                maxAttendees: maxAttendees,
                category: category
            )
            
            // Add to beginning of list
            DispatchQueue.main.async {
                self.localEvents.insert(newEvent, at: 0)
            }
            
            // Track analytics
            Task { 
                await analyticsManager.trackEvent("community_event_created", parameters: [
                    "title": title,
                    "category": category.rawValue,
                    "is_online": isOnline ? "true" : "false",
                    "max_attendees": "\(maxAttendees)"
                ])
            }
            
            // Cache updated data
            coreDataManager.cacheCommunityEvents(localEvents)
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to create event: \(error.localizedDescription)"
            }
            print("Error creating event: \(error)")
        }
    }
    
    func updateLeaderboardTimeframe(_ timeframe: String) async {
        selectedTimeframe = timeframe
        await loadLeaderboard()
    }
    
    // MARK: - Private Methods
    private func loadEvents() async {
        do {
            let events = try await apiService.getCommunityEvents()
            DispatchQueue.main.async {
                self.localEvents = events
            }
            
            // Cache the events
            coreDataManager.cacheCommunityEvents(events)
            print("Loaded \(events.count) community events")
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load events: \(error.localizedDescription)"
            }
            print("Error loading events: \(error)")
            
            // Fall back to cached data
            loadCachedEvents()
        }
    }
    
    private func loadStudyGroups() async {
        do {
            let groups = try await apiService.getStudyGroups()
            DispatchQueue.main.async {
                self.studyGroups = groups
            }
            
            // Cache the study groups
            coreDataManager.cacheStudyGroups(groups)
            print("Loaded \(groups.count) study groups")
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load study groups: \(error.localizedDescription)"
            }
            print("Error loading study groups: \(error)")
            
            // Fall back to cached data
            loadCachedStudyGroups()
        }
    }
    
    private func loadLeaderboard() async {
        do {
            let leaderboardData = try await apiService.getLeaderboard(timeframe: selectedTimeframe)
            DispatchQueue.main.async {
                self.leaderboard = leaderboardData
            }
            
            // Cache the leaderboard
            coreDataManager.cacheLeaderboard(leaderboardData)
            print("Loaded leaderboard with \(leaderboardData.count) entries")
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load leaderboard: \(error.localizedDescription)"
            }
            print("Error loading leaderboard: \(error)")
            
            // Fall back to cached data
            loadCachedLeaderboard()
        }
    }
    
    private func loadUserStats() async {
        do {
            let stats = try await apiService.getUserStats()
            DispatchQueue.main.async {
                self.userStats = stats
            }
            
            // Cache the user stats
            coreDataManager.cacheUserStats(stats)
            print("Loaded user stats")
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load user stats: \(error.localizedDescription)"
            }
            print("Error loading user stats: \(error)")
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