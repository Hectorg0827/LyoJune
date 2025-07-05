import SwiftUI

/// Overall progress card
struct OverallProgressCard: View {
    let progress: UserProgress
    
    var completedStat: some View {
        StatView(
            title: "Completed",
            value: "\(progress.completedCourses)",
            delay: 0.0
        )
    }
    
    var inProgressStat: some View {
        StatView(
            title: "In Progress",
            value: "\(progress.inProgressCourses)",
            delay: 0.1
        )
    }
    
    var totalHoursStat: some View {
        StatView(
            title: "Total Hours",
            value: "\(progress.totalLearningHours)",
            delay: 0.2
        )
    }
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.medium) {
            let totalEnrolled = max(progress.totalCoursesEnrolled, 1)
            let completionRatio = Double(progress.totalCoursesCompleted) / Double(totalEnrolled)
            let percentComplete = Int(completionRatio * 100)
            let progressRatio = completionRatio
            HStack {
                Text("Your Progress")
                    .font(DesignTokens.Typography.titleLarge)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Text("\(percentComplete)%")
                    .font(DesignTokens.Typography.headlineSmall)
                    .foregroundColor(DesignTokens.Colors.primary)
            }
            
            ProgressBar(
                progress: progressRatio,
                height: 12,
                backgroundColor: DesignTokens.Colors.neutral200,
                foregroundColor: DesignTokens.Colors.primary
            )
            
            HStack {
                completedStat
                
                Spacer()
                
                inProgressStat
                
                Spacer()
                
                totalHoursStat
            }
        }
        .padding(DesignTokens.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.large)
                .fill(DesignTokens.Colors.surface)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}
