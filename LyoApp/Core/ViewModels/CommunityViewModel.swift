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
    
    private var cancellables = Set<AnyCancellable>()
    private let communityService = CommunityAPIService.shared
    private let gamificationService = GamificationAPIService.shared
    private let dataManager = DataManager.shared
    private let analyticsService = AnalyticsAPIService.shared
    
    init() {
        setupNotifications()
        loadCachedData()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Public Methods
    func loadData() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        async let eventsTask = loadEvents()
        async let groupsTask = loadStudyGroups()
        async let leaderboardTask = loadLeaderboard()
        async let statsTask = loadUserStats()
        
        await eventsTask
        await groupsTask
        await leaderboardTask
        await statsTask
        
        isLoading = false
    }
    
    func refreshData() async {
        localEvents.removeAll()
        studyGroups.removeAll()
        leaderboard.removeAll()
        userStats = nil
        await loadData()
    }
    
    func joinEvent(_ event: CommunityEvent) async {
        do {
            try await communityService.joinEvent(event.id)
            
            // Update event attendance locally
            if let index = localEvents.firstIndex(where: { $0.id == event.id }) {
                localEvents[index].attendees += 1
                localEvents[index].isUserAttending = true
            }
            
            // Track analytics
            let analyticsEvent = AnalyticsEvent(
                eventName: Constants.AnalyticsEvents.eventJoined,
                properties: [
                    "event_id": event.id,
                    "event_title": event.title,
                    "event_category": event.category.rawValue
                ],
                timestamp: Date(),
                userId: nil
            )
            
            try await analyticsService.trackEvent(analyticsEvent)
            
            // Cache updated data
            dataManager.saveForOffline(localEvents, key: "community_events")
            
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
            try await communityService.joinStudyGroup(group.id)
            
            // Update group membership locally
            if let index = studyGroups.firstIndex(where: { $0.id == group.id }) {
                studyGroups[index].memberCount += 1
                studyGroups[index].isUserMember = true
            }
            
            // Track analytics
            let analyticsEvent = AnalyticsEvent(
                eventName: Constants.AnalyticsEvents.studyGroupJoined,
                properties: [
                    "group_id": group.id,
                    "group_name": group.name,
                    "group_category": group.category
                ],
                timestamp: Date(),
                userId: nil
            )
            
            try await analyticsService.trackEvent(analyticsEvent)
            
            // Cache updated data
            dataManager.saveForOffline(studyGroups, key: "study_groups")
            
        } catch {
            errorMessage = "Failed to join study group: \(error.localizedDescription)"
        }
    }
    
    func leaveStudyGroup(_ group: StudyGroup) async {
        do {
            let _: LeaveGroupResponse = try await communityService.leaveStudyGroup(groupId: group.id)
            
            // Update group membership locally
            if let index = studyGroups.firstIndex(where: { $0.id == group.id }) {
                studyGroups[index].memberCount -= 1
                studyGroups[index].isUserMember = false
            }
            
            // Cache updated data
            dataManager.saveForOffline(studyGroups, key: "study_groups")
            
        } catch {
            errorMessage = "Failed to leave study group: \(error.localizedDescription)"
        }
    }
    
    func createStudyGroup(name: String, description: String, isPrivate: Bool, category: String) async {
        do {
            let newGroup = try await communityService.createStudyGroup(
                name: name,
                description: description,
                isPrivate: isPrivate
            )
            
            // Add to beginning of list
            studyGroups.insert(newGroup, at: 0)
            
            // Track analytics
            await analyticsService.trackEvent(
                "study_group_created",
                parameters: [
                    "group_name": name,
                    "is_private": isPrivate,
                    "category": category
                ]
            )
            
            // Cache updated data
            dataManager.saveForOffline(studyGroups, key: "study_groups")
            
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
        // For now, create locally - in real app, this would be an API call
        let newEvent = CommunityEvent(
            id: UUID().uuidString,
            title: title,
            description: description,
            organizer: AuthService.shared.currentUser?.username ?? "Unknown",
            date: DateFormatter.eventDateFormatter.string(from: date),
            location: location,
            attendees: 1,
            maxAttendees: maxAttendees,
            category: category,
            isOnline: isOnline,
            price: nil,
            isUserAttending: true
        )
        
        localEvents.insert(newEvent, at: 0)
        
        // Track analytics
        await analyticsService.trackEvent(
            "event_created",
            parameters: [
                "event_title": title,
                "is_online": isOnline,
                "category": category.rawValue,
                "max_attendees": maxAttendees
            ]
        )
        
        // Cache updated data
        dataManager.saveForOffline(localEvents, key: "community_events")
    }
    
    func updateLeaderboardTimeframe(_ timeframe: String) async {
        selectedTimeframe = timeframe
        await loadLeaderboard()
    }
    
    // MARK: - Private Methods
    private func loadEvents() async {
        do {
            let events: [StudyEvent] = try await communityService.getEvents()
            // Convert StudyEvent to CommunityEvent if needed, or update the model
            localEvents = events.map { event in
                CommunityEvent(
                    id: event.id,
                    title: event.title,
                    description: event.description,
                    date: event.startTime,
                    time: event.startTime,
                    location: event.location ?? "Virtual",
                    category: .study, // Default category
                    attendees: event.participantCount,
                    isUserAttending: false // This would need to be determined by user ID
                )
            }
            dataManager.saveForOffline(localEvents, key: "community_events")
        } catch {
            errorMessage = "Failed to load events: \(error.localizedDescription)"
            loadCachedEvents()
        }
    }
    
    private func loadStudyGroups() async {
        do {
            let groups: [StudyGroup] = try await communityService.getStudyGroups()
            studyGroups = groups
            dataManager.saveForOffline(groups, key: "study_groups")
        } catch {
            errorMessage = "Failed to load study groups: \(error.localizedDescription)"
            loadCachedStudyGroups()
        }
    }
    
    private func loadLeaderboard() async {
        do {
            let timeframe: TimeFrame = {
                switch selectedTimeframe {
                case "day": return .daily
                case "week": return .weekly
                case "month": return .monthly
                case "year": return .yearly
                default: return .weekly
                }
            }()
            
            let leaderboardData = try await gamificationService.getLeaderboard(
                type: .xp,
                timeframe: timeframe
            )
            
            // Convert to LeaderboardUser format
            leaderboard = leaderboardData.entries.map { entry in
                LeaderboardUser(
                    id: entry.userId,
                    name: entry.username,
                    avatar: entry.avatar,
                    points: entry.score,
                    rank: entry.rank,
                    badge: entry.badge
                )
            }
            
            // Get current user rank
            let userRank = try await gamificationService.getUserRank(
                type: .xp,
                timeframe: timeframe
            )
            
            currentUserRank = LeaderboardUser(
                id: "", // Would be set from current user
                name: "", // Would be set from current user
                avatar: nil,
                points: userRank.score,
                rank: userRank.rank,
                badge: nil
            )
            
            dataManager.saveForOffline(leaderboard, key: "leaderboard_\(selectedTimeframe)")
        } catch {
            errorMessage = "Failed to load leaderboard: \(error.localizedDescription)"
            loadCachedLeaderboard()
        }
    }
    
    private func loadUserStats() async {
        do {
            let stats: UserStats = try await communityService.getUserStats()
            userStats = stats
            dataManager.saveForOffline(stats, key: "user_stats")
        } catch {
            print("Failed to load user stats: \(error.localizedDescription)")
            loadCachedUserStats()
        }
    }
    
    private func loadCachedData() {
        loadCachedEvents()
        loadCachedStudyGroups()
        loadCachedLeaderboard()
        loadCachedUserStats()
        
        // Load mock learning locations for now
        learningLocations = LearningLocation.mockLocations()
    }
    
    private func loadCachedEvents() {
        if let cached: [CommunityEvent] = dataManager.loadFromOffline([CommunityEvent].self, key: "community_events") {
            localEvents = cached
        }
    }
    
    private func loadCachedStudyGroups() {
        if let cached: [StudyGroup] = dataManager.loadFromOffline([StudyGroup].self, key: "study_groups") {
            studyGroups = cached
        }
    }
    
    private func loadCachedLeaderboard() {
        if let cached: LeaderboardResponse = dataManager.loadFromOffline(LeaderboardResponse.self, key: "leaderboard_\(selectedTimeframe)") {
            leaderboard = cached.users
            currentUserRank = cached.currentUser
        }
    }
    
    private func loadCachedUserStats() {
        if let cached: UserStats = dataManager.loadFromOffline(UserStats.self, key: "user_stats") {
            userStats = cached
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: Constants.NotificationNames.userDidLogin)
            .sink { [weak self] _ in
                Task {
                    await self?.refreshData()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Constants.NotificationNames.dataDidSync)
            .sink { [weak self] _ in
                Task {
                    await self?.loadData()
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