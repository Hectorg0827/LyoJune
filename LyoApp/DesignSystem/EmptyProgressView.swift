import SwiftUI

/// Empty progress view for when no user progress is available
struct EmptyProgressView: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 64))
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            Text("No Progress Yet")
                .font(DesignTokens.Typography.titleLarge)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text("Start learning to see your progress here")
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignTokens.Spacing.xl)
    }
}
