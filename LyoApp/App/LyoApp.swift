import SwiftUI

@main
struct LyoApp: App {
    @StateObject private var authService = LyoAuthService()
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
    }
}

@MainActor
class LyoAuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUser: User?
    
    struct User: Codable, Identifiable {
        let id: String
        let email: String
        let displayName: String
        let profileImageURL: String?
        let joinedDate: Date
        let learningStats: LearningStats?
    }
    
    struct LearningStats: Codable {
        let totalCourses: Int
        let completedCourses: Int
        let totalHours: Double
        let currentStreak: Int
    }
    
    init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isAuthenticated = true
            self?.currentUser = User(
                id: "user_123",
                email: "demo@lyo.app",
                displayName: "Demo User",
                profileImageURL: nil,
                joinedDate: Date(),
                learningStats: LearningStats(
                    totalCourses: 12,
                    completedCourses: 8,
                    totalHours: 45.2,
                    currentStreak: 7
                )
            )
            self?.isLoading = false
        }
    }
    
    func signIn(email: String, password: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run {
            isAuthenticated = true
            isLoading = false
        }
    }
    
    func signOut() {
        isAuthenticated = false
        currentUser = nil
        errorMessage = nil
    }
}