import SwiftUI

/// CDAchievement card
struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.small) {
            Image(systemName: "star.fill")
                .font(.system(size: 32))
                .foregroundColor(DesignTokens.Colors.primary)
            
            Text(achievement.title)
                .font(DesignTokens.Typography.labelMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            if let unlockedAt = achievement.unlockedAt {
                Text(unlockedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
        }
        .frame(width: 120)
        .padding(DesignTokens.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.medium)
                .fill(DesignTokens.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.medium)
                        .stroke(DesignTokens.Colors.primary.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
