import SwiftUI

/// Modern search bar component
struct ModernSearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.small) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            TextField("Search courses, paths, topics...", text: $text)
                .font(DesignTokens.Typography.bodyMedium)
                .focused($isFocused)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                    HapticManager.shared.lightImpact()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.medium)
        .padding(.vertical, DesignTokens.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.lg)
                .fill(DesignTokens.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.lg)
                        .stroke(
                            isFocused ? DesignTokens.Colors.primary : DesignTokens.Colors.neutral300,
                            lineWidth: isFocused ? 2 : 1
                        )
                )
        )
        .onAppear {
            isFocused = true
        }
    }
}
