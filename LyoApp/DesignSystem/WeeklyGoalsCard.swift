import SwiftUI

/// Weekly goals card
struct WeeklyGoalsCard: View {
    let progress: UserProgress
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            HStack {
                Image(systemName: "target")
                    .font(.system(size: 24))
                    .foregroundColor(DesignTokens.Colors.info)
                
                Text("Weekly Goals")
                    .font(DesignTokens.Typography.titleMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: DesignTokens.Spacing.small) {
                GoalRow(
                    title: "Complete 3 courses",
                    current: progress.totalCoursesCompleted,
                    target: 3
                )
                
                GoalRow(
                    title: "Study 10 hours",
                    current: Int(progress.totalTimeSpent / 3600),
                    target: 10
                )
                
                GoalRow(
                    title: "7-day streak",
                    current: progress.currentStreak,
                    target: 7
                )
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
