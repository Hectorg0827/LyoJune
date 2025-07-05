import SwiftUI

/// Modern tab selector with smooth animations
struct ModernTabSelector: View {
    let tabs: [String]
    @Binding var selectedTab: Int
    @Namespace private var tabNamespace
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button(action: {
                    HapticManager.shared.selectionFeedback()
                    withAnimation(AnimationSystem.Presets.spring) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: DesignTokens.Spacing.extraSmall) {
                        Text(tab)
                            .font(tabFont(for: index))
                            .foregroundColor(tabColor(for: index))
                            .animation(AnimationSystem.Presets.easeInOut, value: selectedTab)
                        if selectedTab == index {
                            RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.xs)
                                .fill(DesignTokens.Colors.primary)
                                .frame(height: 3)
                                .matchedGeometryEffect(id: "tab_indicator", in: tabNamespace)
                        } else {
                            RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.xs)
                                .fill(Color.clear)
                                .frame(height: 3)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, DesignTokens.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.medium)
                .fill(DesignTokens.Colors.surface.opacity(0.5))
        )
    }
    
    // Helper functions for tab styling
    private func tabFont(for index: Int) -> Font {
        selectedTab == index ? DesignTokens.Typography.labelLarge : DesignTokens.Typography.labelMedium
    }
    
    private func tabColor(for index: Int) -> Color {
        selectedTab == index ? DesignTokens.Colors.primary : DesignTokens.Colors.textSecondary
    }
}