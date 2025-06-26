import SwiftUI
import Combine

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
    private let apiService: EnhancedAPIService
    private let coreDataManager: CoreDataManager
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
        webSocketManager.messagesPublisher
            .compactMap { [weak self] message in
                self?.handleWebSocketMessage(message)
            }
            .sink { _ in }
            .store(in: &cancellables)
    }
    
    private func handleWebSocketMessage(_ message: WebSocketMessage) {
        switch message.type {
        case "community_update":
            Task { await loadData() }
        case "leaderboard_update":
            Task { await loadLeaderboard() }
        case "study_group_update":
            Task { await loadStudyGroups() }
        default:
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
    }
    
    private func loadCachedData() {
        // Load cached community data
        if let cachedEvents = coreDataManager.fetchCachedCommunityEvents() {
            self.localEvents = cachedEvents
        }
        
        if let cachedGroups = coreDataManager.fetchCachedStudyGroups() {
            self.studyGroups = cachedGroups
        }
        
        if let cachedLeaderboard = coreDataManager.fetchCachedLeaderboard() {
            self.leaderboard = cachedLeaderboard
        }
        
        self.lastSyncTime = coreDataManager.getLastSyncTime(for: "community")
        
        // Load mock learning locations for now
        learningLocations = LearningLocation.mockLocations()
    }
    
    // MARK: - Public Methods
    func loadData() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        syncProgress = 0.0
        
        do {
            async let eventsTask = loadEvents()
            async let groupsTask = loadStudyGroups()
            async let leaderboardTask = loadLeaderboard()
            async let statsTask = loadUserStats()
            
            await eventsTask
            await groupsTask
            await leaderboardTask
            await statsTask
            
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
            // Sync community data
            let syncResult = try await coreDataManager.syncCommunityData()
            lastSyncTime = Date()
            
            // Update UI with synced data
            if !syncResult.events.isEmpty {
                localEvents = syncResult.events
            }
            if !syncResult.studyGroups.isEmpty {
                studyGroups = syncResult.studyGroups
            }
            if !syncResult.leaderboard.isEmpty {
                leaderboard = syncResult.leaderboard
            }
            
            NotificationCenter.default.post(name: .dataSynced, object: "community")
            
        } catch {
            print("Sync failed: \(error)")
        }
    }
    
    func joinEvent(_ event: CommunityEvent) async {
        do {
            try await apiService.joinCommunityEvent(eventId: event.id)
            
            // Update event attendance locally
            if let index = localEvents.firstIndex(where: { $0.id == event.id }) {
                localEvents[index].attendees += 1
                localEvents[index].isUserAttending = true
            }
            
            // Track analytics
            try await apiService.trackAnalytics(event: "event_joined", properties: [
                "event_id": event.id,
                "event_title": event.title,
                "event_category": event.category.rawValue
            ])
            
            // Cache updated data
            coreDataManager.cacheCommunityEvents(localEvents)
            
        } catch {
            errorMessage = "Failed to join event: \(error.localizedDescription)"
        }
    }
    
    func leaveEvent(_ event: CommunityEvent) async {
        // Implementation would depend on API - for now, optimistic update
        if let index = localEvents.firstIndex(where: { $0.id == event.id }) {
            localEvents[index].attendees -= 1
            localEvents[index].isUserAttending = false
        }
    }
    
    func joinStudyGroup(_ group: StudyGroup) async {
        do {
            try await apiService.joinStudyGroup(groupId: group.id)
            
            // Update group membership locally
            if let index = studyGroups.firstIndex(where: { $0.id == group.id }) {
                studyGroups[index].memberCount += 1
                studyGroups[index].isUserMember = true
            }
            
            // Track analytics
            try await apiService.trackAnalytics(event: "study_group_joined", properties: [
                "group_id": group.id,
                "group_name": group.name,
                "group_category": group.category
            ])
            
            // Cache updated data
            coreDataManager.cacheStudyGroups(studyGroups)
            
        } catch {
            errorMessage = "Failed to join study group: \(error.localizedDescription)"
        }
    }
    
    func leaveStudyGroup(_ group: StudyGroup) async {
        do {
            try await apiService.leaveStudyGroup(groupId: group.id)
            
            // Update group membership locally
            if let index = studyGroups.firstIndex(where: { $0.id == group.id }) {
                studyGroups[index].memberCount -= 1
                studyGroups[index].isUserMember = false
            }
            
            // Cache updated data
            coreDataManager.cacheStudyGroups(studyGroups)
            
        } catch {
            errorMessage = "Failed to leave study group: \(error.localizedDescription)"
        }
    }
    
    func createStudyGroup(name: String, description: String, isPrivate: Bool, category: String) async {
        do {
            let newGroup = try await apiService.createStudyGroup(
                name: name,
                description: description,
                isPrivate: isPrivate,
                category: category
            )
            
            // Add to beginning of list
            studyGroups.insert(newGroup, at: 0)
            
            // Track analytics
            try await apiService.trackAnalytics(event: "study_group_created", properties: [
                "group_name": name,
                "is_private": isPrivate,
                "category": category
            ])
            
            // Cache updated data
            coreDataManager.cacheStudyGroups(studyGroups)
            
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
            localEvents.insert(newEvent, at: 0)
            
            // Track analytics
            try await apiService.trackAnalytics(event: "community_event_created", properties: [
                "event_title": title,
                "is_online": isOnline,
                "category": category.rawValue
            ])
            
            // Cache updated data
            coreDataManager.cacheCommunityEvents(localEvents)
            
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
            let events = try await apiService.getCommunityEvents()
            localEvents = events
            coreDataManager.cacheCommunityEvents(events)
        } catch {
            errorMessage = "Failed to load events: \(error.localizedDescription)"
            loadCachedEvents()
        }
    }
    
    private func loadStudyGroups() async {
        do {
            let groups = try await apiService.getStudyGroups()
            studyGroups = groups
            coreDataManager.cacheStudyGroups(groups)
        } catch {
            errorMessage = "Failed to load study groups: \(error.localizedDescription)"
            loadCachedStudyGroups()
        }
    }
    
    private func loadLeaderboard() async {
        do {
            let leaderboardData = try await apiService.getLeaderboard(timeframe: selectedTimeframe)
            leaderboard = leaderboardData
            coreDataManager.cacheLeaderboard(leaderboardData)
        } catch {
            errorMessage = "Failed to load leaderboard: \(error.localizedDescription)"
            loadCachedLeaderboard()
        }
    }
    
    private func loadUserStats() async {
        do {
            let stats = try await apiService.getUserStats()
            userStats = stats
            
            // Update current user rank
            currentUserRank = leaderboard.first { $0.id == stats.userId }
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
struct UserStats: Codable {
    let totalStudyTime: Double
    let coursesCompleted: Int
    let eventsAttended: Int
    let groupsJoined: Int
    let postsCreated: Int
    let currentStreak: Int
    let longestStreak: Int
    let totalPoints: Int
    let level: Int
    let rank: Int
    let achievementsCount: Int
}