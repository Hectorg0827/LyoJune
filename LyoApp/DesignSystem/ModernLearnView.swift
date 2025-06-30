import SwiftUI

// Import models to access Course and other canonical types
// CourseModel is a typealias for Course from AppModels.swift

/// Enhanced Learning View with modern design system
struct ModernLearnView: View {
    @StateObject private var viewModel = LearnViewModel()
    @State private var selectedTab = 0
    @State private var isLoading = true
    @State private var searchText = ""
    
    private let tabs = ["Courses", "Paths", "Progress"]
    
    var body: some View {
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
                    // Enhanced Header
                    ModernHeaderView(
                        title: "Learn",
                        subtitle: "Expand your knowledge",
                        showSearch: true,
                        searchText: $searchText
                    )
                    
                    // Modern Tab Selector
                    ModernTabSelector(
                        tabs: tabs,
                        selectedTab: $selectedTab
                    )
                    .padding(.horizontal, DesignTokens.Spacing.medium)
                    
                    // Content
                    if isLoading {
                        VStack(spacing: DesignTokens.Spacing.md) {
                            ForEach(0..<3, id: \.self) { _ in
                                SkeletonLoader(blockSize: 80)
                            }
                        }
                        .transition(AnimationSystem.Presets.fadeInOut)
                    } else {
                        TabView(selection: $selectedTab) {
                            ModernCoursesView(
                                courses: viewModel.featuredCourses,
                                searchText: searchText
                            )
                            .tag(0)
                            
                            ModernLearningPathsView(
                                paths: viewModel.learningPaths,
                                searchText: searchText
                            )
                            .tag(1)
                            
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
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .transition(AnimationSystem.Presets.slideUp)
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

/// Modern tab selector with smooth animations
struct ModernTabSelector: View {
    let tabs: [String]
    @Binding var selectedTab: Int
    @Namespace private var tabNamespace
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: ".offset") { index, tab in
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

/// Modern courses view with enhanced cards
struct ModernCoursesView: View {
    let courses: [CourseModel]
    let searchText: String
    
    private var filteredCourses: [CourseModel] {
        if searchText.isEmpty {
            return courses
        }
        return courses.filter { course in
            course.title.lowercased().contains(searchText.lowercased()) ||
            course.description.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: DesignTokens.Spacing.medium),
                    GridItem(.flexible(), spacing: DesignTokens.Spacing.medium)
                ],
                spacing: DesignTokens.Spacing.medium
            ) {
                ForEach(filteredCourses, id: \.id) { course in
                    EnhancedCourseCard(
                        course: course,
                        isLoading: false,
                        onTap: {
                            // Handle course tap
                        }
                    )
                        .transition(AnimationSystem.Presets.scaleIn)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.medium)
            .animation(AnimationSystem.Presets.easeInOut, value: filteredCourses.count)
        }
        .scrollIndicators(.hidden)
    }
}

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
                blockSize: 8,
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

/// Modern progress view
struct ModernProgressView: View {
    let progress: UserProgress
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Overall progress card
                OverallProgressCard(progress: progress)
                
                // Recent achievements
                if !progress.recentAchievements.isEmpty {
                    AchievementsSection(achievements: progress.recentAchievements)
                }
                
                // Learning streaks
                LearningStreaksCard(progress: progress)
                
                // Weekly goals
                WeeklyGoalsCard(progress: progress)
            }
            .padding(.horizontal, DesignTokens.Spacing.medium)
        }
        .scrollIndicators(.hidden)
    }
}

/// Overall progress card
struct OverallProgressCard: View {
    let progress: UserProgress
    
    var completedStat: some View {
        StatView(
            title: "Completed",
            value: "\(progress.completedCourses)",
            delay: 0.0
        )
    }
    
    var inProgressStat: some View {
        StatView(
            title: "In Progress",
            value: "\(progress.inProgressCourses)",
            delay: 0.1
        )
    }
    
    var totalHoursStat: some View {
        StatView(
            title: "Total Hours",
            value: "\(progress.totalLearningHours)",
            delay: 0.2
        )
    }
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.medium) {
            let percentComplete = Int(Double(progress.totalCoursesCompleted) / Double(max(progress.totalCoursesEnrolled, 1)) * 100)
            let progressRatio = Double(progress.totalCoursesCompleted) / Double(max(progress.totalCoursesEnrolled, 1))
            HStack {
                Text("Your Progress")
                    .font(DesignTokens.Typography.titleLarge)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Text("\(percentComplete)%")
                    .font(DesignTokens.Typography.headlineSmall)
                    .foregroundColor(DesignTokens.Colors.primary)
            }
            
            ProgressBar(
                progress: progressRatio,
                blockSize: 12,
                backgroundColor: DesignTokens.Colors.neutral200,
                foregroundColor: DesignTokens.Colors.primary
            )
            
            HStack {
                completedStat
                
                Spacer()
                
                inProgressStat
                
                Spacer()
                
                totalHoursStat
            }
        }
        .padding(DesignTokens.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.large)
                .fill(DesignTokens.Colors.surface)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

/// Achievements section
struct AchievementsSection: View {
    let achievements: [Achievement]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            Text("Recent Achievements")
                .font(DesignTokens.Typography.titleMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Spacing.medium) {
                    ForEach(achievements, id: \.id) { achievement in
                        AchievementCard(achievement: achievement)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.medium)
            }
        }
    }
}

/// Achievement card
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

/// Weekly goals card
struct WeeklyGoalsCard: View {
    let progress: UserProgress
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            HStack {
                Image(systemName: "target")
                    .font(.system(size: 24))
                    .foregroundColor(DesignTokens.Colors.info)
                
                Text("Weekly Goals")
                    .font(DesignTokens.Typography.titleMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: DesignTokens.Spacing.small) {
                GoalRow(
                    title: "Complete 3 courses",
                    current: progress.totalCoursesCompleted,
                    target: 3
                )
                
                GoalRow(
                    title: "Study 10 hours",
                    current: Int(progress.totalTimeSpent / 3600),
                    target: 10
                )
                
                GoalRow(
                    title: "7-day streak",
                    current: progress.currentStreak,
                    target: 7
                )
            }
        }
        .padding(DesignTokens.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.large)
                .fill(DesignTokens.Colors.surface)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

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
                blockSize: 6,
                backgroundColor: DesignTokens.Colors.neutral200,
                foregroundColor: progress >= 1.0 ? DesignTokens.Colors.success : DesignTokens.Colors.info
            )
        }
    }
}

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

#Preview {
    ModernLearnView()
}
