import SwiftUI
import Foundation



/// Enhanced Learning View with modern design system
struct ModernLearnView: View {
    @StateObject private var viewModel = LearnViewModel()
    @State private var selectedTab = 0
    @State private var isLoading = true
    @State private var searchText = ""
    
    private let tabs = ["Courses", "Paths", "Progress"]
    
    var body: some View {
        mainContent
    }

    private var mainContent: some View {
        NavigationView {
            ZStack {
                // Modern gradient background
                LinearGradient(
                    colors: [
                        DesignTokens.Colors.background,
                        DesignTokens.Colors.surface.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    
                    
                    
                    
                    // Content
                    if isLoading {
                        loadingView
                    } else {
                        contentView
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await loadContent()
            }
        }
        .refreshable {
            await viewModel.refreshData()
        }
    }
    
    private func loadContent() async {
        isLoading = true
        await viewModel.loadData()
        
        // Simulate loading for better UX
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        withAnimation(AnimationSystem.Presets.easeInOut) {
            isLoading = false
        }
    }
}

extension ModernLearnView {
    private var loadingView: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ForEach(0..<3, id: \.self) { _ in
                SkeletonLoader(height: 80, width: 80)
            }
        }
        .transition(AnimationSystem.Presets.fadeInOut)
    }

    private var contentView: some View {
        TabView(selection: $selectedTab) {
            coursesTabView
            pathsTabView
            progressTabView
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .transition(AnimationSystem.Presets.slideUp)
    }

    private var coursesTabView: some View {
        ModernCoursesView(
            courses: viewModel.featuredCourses,
            searchText: searchText
        )
        .tag(0)
    }

    private var pathsTabView: some View {
        ModernLearningPathsView(
            paths: viewModel.learningPaths,
            searchText: searchText
        )
        .tag(1)
    }

    private var progressTabView: some View {
        Group {
            if let userProgress = viewModel.userProgress {
                ModernProgressView(
                    progress: userProgress
                )
                .tag(2)
            } else {
                EmptyProgressView()
                    .tag(2)
            }
        }
    }
}

#Preview {
    ModernLearnView()
}
