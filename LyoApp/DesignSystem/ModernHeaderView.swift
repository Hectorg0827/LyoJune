import SwiftUI
import Foundation

/// Modern Header with search functionality
struct ModernHeaderView: View {
    let title: String
    let subtitle: String?
    let showSearch: Bool
    @Binding var searchText: String
    
    @State private var isSearching = false
    
    init(
        title: String,
        subtitle: String? = nil,
        showSearch: Bool = false,
        searchText: Binding<String> = .constant("")
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showSearch = showSearch
        self._searchText = searchText
    }
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.medium) {
            HStack {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraSmall) {
                    Text(title)
                        .font(DesignTokens.Typography.headlineLarge)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                if showSearch {
                    Button(action: {
                        HapticManager.shared.lightImpact()
                        withAnimation(AnimationSystem.Presets.spring) {
                            isSearching.toggle()
                        }
                    }) {
                        Image(systemName: isSearching ? "xmark" : "magnifyingglass")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(DesignTokens.Colors.surface)
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Search bar
            if isSearching && showSearch {
                ModernSearchBar(text: $searchText)
                    .transition(AnimationSystem.Presets.slideDown)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.medium)
        .padding(.top, DesignTokens.Spacing.small)
    }
}