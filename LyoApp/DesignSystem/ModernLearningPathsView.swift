import SwiftUI

/// Modern learning paths view
struct ModernLearningPathsView: View {
    let paths: [LearningPath]
    let searchText: String
    
    private var filteredPaths: [LearningPath] {
        if searchText.isEmpty {
            return paths
        }
        return paths.filter { path in
            path.title.lowercased().contains(searchText.lowercased()) ||
            path.description.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.medium) {
                ForEach(filteredPaths, id: \.id) { path in
                    ModernLearningPathCard(path: path)
                        .transition(AnimationSystem.Presets.slideFromLeft)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.medium)
            .animation(AnimationSystem.Presets.easeInOut, value: filteredPaths.count)
        }
        .scrollIndicators(.hidden)
    }
}
