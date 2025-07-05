import SwiftUI

/// Modern courses view with enhanced cards
struct ModernCoursesView: View {
    let courses: [CourseModel]
    let searchText: String
    
    private var filteredCourses: [CourseModel] {
        if searchText.isEmpty {
            return courses
        }
        return courses.filter { course in
            course.title.lowercased().contains(searchText.lowercased()) ||
            course.description.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: DesignTokens.Spacing.medium),
                    GridItem(.flexible(), spacing: DesignTokens.Spacing.medium)
                ],
                spacing: DesignTokens.Spacing.medium
            ) {
                ForEach(filteredCourses, id: \.id) { course in
                    EnhancedCourseCard(
                        course: course,
                        isLoading: false,
                        onTap: {
                            // Handle course tap
                        }
                    )
                        .transition(AnimationSystem.Presets.scaleIn)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.medium)
            .animation(AnimationSystem.Presets.easeInOut, value: filteredCourses.count)
        }
        .scrollIndicators(.hidden)
    }
}