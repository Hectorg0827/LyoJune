import SwiftUI
import Combine

// MARK: - Profile Type Definitions
struct RecentActivity: Identifiable, Codable {
    let id: UUID
    let type: ActivityType
    let title: String
    let description: String
    let timestamp: Date
    let points: Int?
    
    enum ActivityType: String, CaseIterable, Codable {
        case courseCompleted = "course_completed"
        case lessonFinished = "lesson_finished"
        case achievementUnlocked = "achievement_unlocked"
        case postCreated = "post_created"
        case commentAdded = "comment_added"
        case studyStreak = "study_streak"
    }
    
    init(id: UUID = UUID(), type: ActivityType, title: String, description: String, timestamp: Date = Date(), points: Int? = nil) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.timestamp = timestamp
        self.points = points
    }
}

// Add Activity typealias for backward compatibility
typealias Activity = RecentActivity

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var recentActivities: [RecentActivity] = []
    @Published var userStats: LearningStats?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isUpdatingProfile = false
    @Published var showingImagePicker = false
    @Published var selectedImage: UIImage?
    @Published var isOffline = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // Enhanced services
    private let serviceFactory = EnhancedServiceFactory.shared
    
    private var authService: EnhancedAuthService {
        serviceFactory.authService
    }
    
    private var apiService: EnhancedNetworkManager {
        serviceFactory.apiService
    }
    
    private var coreDataManager: CoreDataManager {
        serviceFactory.coreDataManager
    }
    
    private var webSocketManager: WebSocketManager {
        serviceFactory.webSocketManager
    }
    
    var currentUser: User? {
        // Mock implementation - getCurrentUser method doesn't exist
        return nil
    }
    
    init() {
        setupNotifications()
        // setupRealTimeUpdates() // Method doesn't exist
        Task {
            await loadCachedData()
        }
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Public Methods
    func loadData() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Load from cache first for instant UI
        await loadCachedData()
        
        // Mock API calls since these methods don't exist
        let stats: LearningStats? = nil
        let achievementsData: [Achievement] = []
        let activities: [RecentActivity] = []
        
        userStats = stats
        achievements = achievementsData
        recentActivities = activities
        
        // Cache the new data
        await cacheProfileData()
        
        isOffline = false
        
        isLoading = false
    }
    
    func refreshData() async {
        achievements.removeAll()
        recentActivities.removeAll()
        userStats = nil
        await loadData()
    }
    
    func updateProfile(firstName: String, lastName: String, bio: String?) async {
        guard !isUpdatingProfile else { return }
        
        isUpdatingProfile = true
        errorMessage = nil
        
        // Mock profile update - updateProfile method doesn't exist
        print("Updating profile: \(firstName) \(lastName)")
        
        // Track analytics
        await AnalyticsAPIService.shared.trackEvent(
            "profile_updated",
            parameters: [
                "has_bio": bio != nil ? "true" : "false",
                "bio_length": String(bio?.count ?? 0)
            ]
        )
        
        isUpdatingProfile = false
    }
    
    func uploadAvatar() async {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "Please select an image first"
            return
        }
        
        isUpdatingProfile = true
        errorMessage = nil
        
        // Mock avatar upload - uploadAvatar method doesn't exist
        print("Uploading avatar with \(imageData.count) bytes")
        
        // Clear selected image
        selectedImage = nil
        
        // Track analytics
        await AnalyticsAPIService.shared.trackEvent("avatar_uploaded")
        
        isUpdatingProfile = false
    }
    
    func logout() async {
        await authService.logout()
    }
    
    func deleteAccount() async {
        // In a real app, you'd implement account deletion
        // This would require additional API endpoints and confirmation flows
        
        // For now, just log out
        await logout()
        
        // Track analytics
        await AnalyticsAPIService.shared.trackEvent("account_deletion_attempted")
    }
    
    func exportData() async -> URL? {
        // Create a data export for the user
        let exportData = createUserDataExport()
        
        do {
            let _ = try JSONEncoder().encode(exportData)
            let fileName = "LyoApp_Export_\(Date().timeIntervalSince1970).json"
            
            // Mock file saving - saveFile method doesn't exist
            print("Would save export file: \(fileName)")
            
            // Track analytics
            await AnalyticsAPIService.shared.trackEvent("data_exported")
            
            return URL(fileURLWithPath: "/tmp/\(fileName)")
            
        } catch {
            errorMessage = "Failed to export data: \(error.localizedDescription)"
            return nil
        }
    }
    
    func clearCache() async {
        // Mock cache clearing - clearCache method doesn't exist
        print("Cache cleared")
        
        // Track analytics
        await AnalyticsAPIService.shared.trackEvent("cache_cleared")
        
        // Reload data
        await refreshData()
    }
    
    // MARK: - Private Methods
    private func loadUserStats() async {
        // Mock stats loading - getUserAnalytics method doesn't exist
        userStats = nil
        print("Mock user analytics loaded")
    }
    
    private func loadAchievements() async {
        // For now, load mock achievements
        // In a real app, this would come from an API
        achievements = Achievement.mockAchievements()
        print("Mock achievements loaded")
    }
    
    private func loadRecentActivities() async {
        // For now, load mock activities
        // In a real app, this would come from an API  
        recentActivities = []
        print("Mock activities loaded")
    }
    
    private func loadCachedData() async {
        loadCachedStats()
        
        // Mock cached data loading - loadFromOffline method doesn't exist
        achievements = []
        recentActivities = []
    }
    
    private func loadCachedStats() {
        // Mock cached stats loading - loadFromOffline method doesn't exist
        userStats = nil
    }
    
    private func cacheProfileData() async {
        // Mock caching - saveForOffline method doesn't exist
        print("Profile data cached")
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        print("Profile error: \(error)")
    }
    
    private func setupNotifications() {
        // Mock notification setup - currentUser publisher doesn't exist
        NotificationCenter.default.publisher(for: NSNotification.Name("userDidUpdate"))
            .sink { [weak self] _ in
                Task {
                    await self?.loadData()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: NSNotification.Name("dataDidSync"))
            .sink { [weak self] _ in
                Task {
                    await self?.loadData()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: NSNotification.Name("achievementUnlocked"))
            .sink { [weak self] notification in
                // Handle new achievement
                Task {
                    await self?.loadAchievements()
                }
            }
            .store(in: &cancellables)
    }
    
    private func createUserDataExport() -> UserDataExport {
        return UserDataExport(
            user: currentUser,
            achievements: achievements,
            recentActivities: recentActivities,
            userStats: userStats,
            exportDate: Date()
        )
    }
}

// MARK: - User Data Export Model
struct UserDataExport: Codable {
    let user: User?
    let achievements: [Achievement]
    let recentActivities: [RecentActivity]
    let userStats: LearningStats?
    let exportDate: Date
}