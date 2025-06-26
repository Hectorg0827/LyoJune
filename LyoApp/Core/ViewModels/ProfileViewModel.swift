import SwiftUI
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var recentActivities: [RecentActivity] = []
    @Published var userStats: UserAnalytics?
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
    
    private var apiService: EnhancedAPIService {
        serviceFactory.apiService
    }
    
    private var coreDataManager: CoreDataManager {
        serviceFactory.coreDataManager
    }
    
    private var webSocketManager: WebSocketManager {
        serviceFactory.webSocketManager
    }
    
    var currentUser: User? {
        Task {
            return await authService.getCurrentUser()
        }
        return nil // This will be updated to use async properly
    }
    
    init() {
        setupNotifications()
        setupRealTimeUpdates()
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
        
        do {
            // Load from cache first for instant UI
            await loadCachedData()
            
            // Then fetch fresh data from API
            async let statsTask = apiService.getUserAnalytics()
            async let achievementsTask = apiService.getUserAchievements()
            async let activitiesTask = apiService.getRecentActivities()
            
            let (stats, achievementsData, activities) = try await (statsTask, achievementsTask, activitiesTask)
            
            userStats = stats
            achievements = achievementsData
            recentActivities = activities
            
            // Cache the new data
            await cacheProfileData()
            
            isOffline = false
            
        } catch {
            handleError(error)
            // If network fails, show cached data
            if achievements.isEmpty {
                await loadCachedData()
            }
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
            try await authService.updateProfile(
                firstName: firstName,
                lastName: lastName,
                bio: bio
            )
            
            // Track analytics
            await analyticsService.trackEvent(
                "profile_updated",
                parameters: [
                    "has_bio": bio != nil,
                    "bio_length": bio?.count ?? 0
                ]
            )
            
        } catch {
            errorMessage = "Failed to update profile: \(error.localizedDescription)"
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
            try await authService.uploadAvatar(imageData: imageData)
            
            // Clear selected image
            selectedImage = nil
            
            // Track analytics
            await analyticsService.trackEvent("avatar_uploaded")
            
        } catch {
            errorMessage = "Failed to upload avatar: \(error.localizedDescription)"
        }
        
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
        await analyticsService.trackEvent("account_deletion_attempted")
    }
    
    func exportData() async -> URL? {
        // Create a data export for the user
        let exportData = createUserDataExport()
        
        do {
            let data = try JSONEncoder().encode(exportData)
            let fileName = "LyoApp_Export_\(Date().timeIntervalSince1970).json"
            
            let fileURL = try dataManager.saveFile(
                data: data,
                filename: fileName,
                in: Constants.FilePaths.userGenerated
            )
            
            // Track analytics
            await analyticsService.trackEvent("data_exported")
            
            return fileURL
            
        } catch {
            errorMessage = "Failed to export data: \(error.localizedDescription)"
            return nil
        }
    }
    
    func clearCache() async {
        dataManager.clearCache()
        
        // Track analytics
        await analyticsService.trackEvent("cache_cleared")
        
        // Reload data
        await refreshData()
    }
    
    // MARK: - Private Methods
    private func loadUserStats() async {
        do {
            let stats = try await analyticsService.getUserAnalytics()
            userStats = stats
            dataManager.saveForOffline(stats, key: "user_analytics")
        } catch {
            errorMessage = "Failed to load user statistics: \(error.localizedDescription)"
            loadCachedStats()
        }
    }
    
    private func loadAchievements() async {
        // For now, load mock achievements
        // In a real app, this would come from an API
        achievements = Achievement.mockAchievements()
        dataManager.saveForOffline(achievements, key: "user_achievements")
    }
    
    private func loadRecentActivities() async {
        // For now, load mock activities
        // In a real app, this would come from an API
        recentActivities = RecentActivity.mockActivities()
        dataManager.saveForOffline(recentActivities, key: "recent_activities")
    }
    
    private func loadCachedData() {
        loadCachedStats()
        
        if let cached: [Achievement] = dataManager.loadFromOffline([Achievement].self, key: "user_achievements") {
            achievements = cached
        }
        
        if let cached: [RecentActivity] = dataManager.loadFromOffline([RecentActivity].self, key: "recent_activities") {
            recentActivities = cached
        }
    }
    
    private func loadCachedStats() {
        if let cached: UserAnalytics = dataManager.loadFromOffline(UserAnalytics.self, key: "user_analytics") {
            userStats = cached
        }
    }
    
    private func setupNotifications() {
        // Listen for user updates
        authService.$currentUser
            .sink { [weak self] _ in
                Task {
                    await self?.loadData()
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
        
        NotificationCenter.default.publisher(for: Constants.NotificationNames.achievementUnlocked)
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
    let userStats: UserAnalytics?
    let exportDate: Date
}