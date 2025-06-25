import SwiftUI

@MainActor
class LearnViewModel: ObservableObject {
    @Published var featuredCourses: [Course] = []
    @Published var learningPaths: [LearningPath] = []
    @Published var userProgress: UserProgress = UserProgress.mockProgress()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadData() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            featuredCourses = Course.mockCourses()
            learningPaths = LearningPath.mockPaths()
            userProgress = UserProgress.mockProgress()
        } catch {
            errorMessage = "Failed to load learning data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        featuredCourses.removeAll()
        learningPaths.removeAll()
        await loadData()
    }
    
    func enrollInCourse(_ course: Course) async {
        // Simulate enrollment API call
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Update course enrollment status
        if let index = featuredCourses.firstIndex(where: { $0.id == course.id }) {
            var updatedCourse = featuredCourses[index]
            // Note: In a real app, you'd create a new Course instance with updated properties
            // featuredCourses[index] = updatedCourse
        }
    }
}