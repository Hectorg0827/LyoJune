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
        
        do {
            // Load profile data from API
            async let statsResponse = apiClient.getUserStats()
            async let achievementsResponse = apiClient.getUserAchievements()
            async let activitiesResponse = apiClient.getRecentActivities()
            
            let stats = try await statsResponse
            let achievementsData = try await achievementsResponse
            let activities = try await activitiesResponse
            
            DispatchQueue.main.async {
                self.userStats = stats
                self.achievements = achievementsData
                self.recentActivities = activities
                self.isOffline = false
            }
            
            // Cache the new data
            await cacheProfileData()
            
        } catch {
            print("Error loading profile data: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load profile: \(error.localizedDescription)"
                self.isOffline = true
            }
            
            // Fall back to cached data
            await loadCachedData()
        }
        
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
        
        do {
            let updatedProfile = try await apiClient.updateUserProfile(
                firstName: firstName,
                lastName: lastName,
                bio: bio
            )
            
            // Update local profile data
            DispatchQueue.main.async {
                // Update current user profile through auth service
                self.authService.updateCurrentUser(updatedProfile)
            }
            
            // Track analytics
            await AnalyticsAPIService.shared.trackEvent(
                "profile_updated",
                parameters: [
                    "has_bio": bio != nil ? "true" : "false",
                    "bio_length": String(bio?.count ?? 0)
                ]
            )
            
        } catch {
            print("Error updating profile: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to update profile: \(error.localizedDescription)"
            }
        }
        
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
        
        do {
            let updatedProfile = try await apiClient.uploadUserAvatar(imageData: imageData)
            
            // Update local profile data
            DispatchQueue.main.async {
                self.authService.updateCurrentUser(updatedProfile)
                self.selectedImage = nil
            }
            
            // Track analytics
            await AnalyticsAPIService.shared.trackEvent("avatar_uploaded")
            
        } catch {
            print("Error uploading avatar: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to upload avatar: \(error.localizedDescription)"
            }
        }
        
        isUpdatingProfile = false
    }
    
    func logout() async {
        await authService.logout()
    }
    
    func deleteAccount() async {
        do {
            try await apiClient.deleteUserAccount()
            
            // Log out after successful deletion
            await authService.logout()
            
            // Track analytics
            await AnalyticsAPIService.shared.trackEvent("account_deleted")
            
        } catch {
            print("Error deleting account: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to delete account: \(error.localizedDescription)"
            }
            
            // Track analytics for failed attempt
            await AnalyticsAPIService.shared.trackEvent("account_deletion_failed")
        }
    }
    
    func exportData() async -> URL? {
        do {
            let exportURL = try await apiClient.exportUserData()
            
            // Track analytics
            await AnalyticsAPIService.shared.trackEvent("data_exported")
            
            return exportURL
            
        } catch {
            print("Error exporting data: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to export data: \(error.localizedDescription)"
            }
            return nil
        }
    }
    
    func clearCache() async {
        do {
            try await coreDataManager.clearCache()
            
            // Track analytics
            await AnalyticsAPIService.shared.trackEvent("cache_cleared")
            
            // Reload data
            await refreshData()
            
        } catch {
            print("Error clearing cache: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to clear cache: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Private Methods
    private func loadUserStats() async {
        // Stats are loaded in the main loadData method
        // This method can be removed or used for specific stat loading
    }
    
    private func loadAchievements() async {
        // Achievements are loaded in the main loadData method
        // This method can be removed or used for specific achievement loading
    }
    
    private func loadRecentActivities() async {
        // Activities are loaded in the main loadData method
        // This method can be removed or used for specific activity loading
    }
    
    private func loadCachedData() async {
        loadCachedStats()
        
        let cachedAchievements = coreDataManager.fetchCachedAchievements()
        let cachedActivities = coreDataManager.fetchCachedRecentActivities()
        
        DispatchQueue.main.async {
            self.achievements = cachedAchievements
            self.recentActivities = cachedActivities
        }
    }
    
    private func loadCachedStats() {
        if let cachedStats = coreDataManager.fetchCachedUserStats() {
            DispatchQueue.main.async {
                self.userStats = cachedStats
            }
        }
    }
    
    private func cacheProfileData() async {
        if let stats = userStats {
            coreDataManager.cacheUserStats(stats)
        }
        coreDataManager.cacheAchievements(achievements)
        coreDataManager.cacheRecentActivities(recentActivities)
        print("Profile data cached")
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        print("Profile error: \(error)")
    }
    
    private func setupNotifications() {
        // Listen for user profile updates
        if let userPublisher = authService.currentUserPublisher {
            userPublisher
                .sink { [weak self] _ in
                    Task {
                        await self?.loadData()
                    }
                }
                .store(in: &cancellables)
        }
        
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
            userStats: userStats
        )
    }
}

struct UserDataExport: Codable, Identifiable {
    let id: UUID
    let user: User?
    let achievements: [Achievement]
    let recentActivities: [RecentActivity]
    let userStats: LearningStats?
    let exportDate: Date
    
    init(user: User?, achievements: [Achievement], recentActivities: [RecentActivity], userStats: LearningStats?) {
        self.id = UUID()
        self.user = user
        self.achievements = achievements
        self.recentActivities = recentActivities
        self.userStats = userStats
        self.exportDate = Date()
    }
}