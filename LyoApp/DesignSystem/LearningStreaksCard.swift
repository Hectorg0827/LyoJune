import SwiftUI

/// Learning streaks card
struct LearningStreaksCard: View {
    let progress: UserProgress
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 24))
                    .foregroundColor(DesignTokens.Colors.warning)
                
                Text("Learning Streak")
                    .font(DesignTokens.Typography.titleMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Text("\(progress.streakDays) days")
                    .font(DesignTokens.Typography.headlineSmall)
                    .foregroundColor(DesignTokens.Colors.warning)
            }
            
            HStack {
                ForEach(0..<7) { day in
                    Circle()
                        .fill(day < progress.currentStreak ? 
                              DesignTokens.Colors.warning : 
                              DesignTokens.Colors.surface)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(DesignTokens.Colors.border, lineWidth: 1)
                        )
                }
            }
            
            Text("Keep it up! You're on a roll 🔥")
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .padding(DesignTokens.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.large)
                .fill(DesignTokens.Colors.surface)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}
