import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var recentActivities: [RecentActivity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadData() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            achievements = Achievement.mockAchievements()
            recentActivities = RecentActivity.mockActivities()
        } catch {
            errorMessage = "Failed to load profile data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        achievements.removeAll()
        recentActivities.removeAll()
        await loadData()
    }
    
    func updateProfile(displayName: String, bio: String) async {
        // Simulate profile update API call
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // In a real app, you'd update the user profile through the auth service
    }
    
    func deleteAccount() async {
        // Simulate account deletion API call
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        // In a real app, you'd handle account deletion
    }
}