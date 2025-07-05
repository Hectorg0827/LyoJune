import SwiftUI

/// Modern learning path card
struct ModernLearningPathCard: View {
    let path: LearningPath
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            HStack {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                    Text(path.title)
                        .font(DesignTokens.Typography.titleMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    if !path.description.isEmpty {
                        Text(path.description)
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .lineLimit(isExpanded ? nil : 2)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    HapticManager.shared.lightImpact()
                    withAnimation(AnimationSystem.Presets.spring) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.25), value: isExpanded)
                }
            }
            
            // Progress indicator
            ProgressBar(
                progress: path.progress,
                height: 8,
                backgroundColor: DesignTokens.Colors.neutral200,
                foregroundColor: DesignTokens.Colors.success
            )
            
            if isExpanded {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                    Text("Courses in this path:")
                        .font(DesignTokens.Typography.labelMedium)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    ForEach(path.courses, id: \.id) { course in
                        HStack {
                            // TODO: Show checkmark if course is completed by user
                            Image(systemName: "circle")
                                .font(.system(size: 16))
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                            Text(course.title)
                                .font(DesignTokens.Typography.bodyMedium)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                            Spacer()
                        }
                    }
                }
                .transition(AnimationSystem.Presets.fadeInOut)
            }
        }
        .padding(DesignTokens.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.large)
                .fill(DesignTokens.Colors.surface)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .scaleEffect(isExpanded ? 1.02 : 1.0)
        .animation(AnimationSystem.Presets.easeInOut, value: isExpanded)
    }
}
