import SwiftUI

/// Goal row component
struct GoalRow: View {
    let title: String
    let current: Int
    let target: Int
    
    private var progress: Double {
        Double(current) / Double(target)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraSmall) {
            HStack {
                Text(title)
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Text("\(current)/\(target)")
                    .font(DesignTokens.Typography.labelMedium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            
            ProgressBar(
                progress: min(progress, 1.0),
                height: 6,
                backgroundColor: DesignTokens.Colors.neutral200,
                foregroundColor: progress >= 1.0 ? DesignTokens.Colors.success : DesignTokens.Colors.info
            )
        }
    }
}
