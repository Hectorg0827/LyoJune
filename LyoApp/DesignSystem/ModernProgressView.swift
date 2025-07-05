import SwiftUI

/// Modern progress view
struct ModernProgressView: View {
    let progress: UserProgress
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Overall progress card
                OverallProgressCard(progress: progress)
                
                // Recent achievements
                if !progress.recentAchievements.isEmpty {
                    
                }
                
                // Learning streaks
                
                
                
            }
            .padding(.horizontal, DesignTokens.Spacing.medium)
        }
        .scrollIndicators(.hidden)
    }
}