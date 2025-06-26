import SwiftUI

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
                        SkeletonLoader.courseList()
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
                            
                            ModernProgressView(
                                progress: viewModel.userProgress
                            )
                            .tag(2)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .transition(AnimationSystem.Presets.slideUp)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.never)
        .onAppear {
            Task {
                await loadContent()
            }
        }
        .refreshable {
            await viewModel.refreshContent()
        }
    }
    
    private func loadContent() async {
        isLoading = true
        await viewModel.loadContent()
        
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
                        HapticManager.shared.impact(.light)
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
                    .buttonStyle(HapticButtonStyle())
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
                    HapticManager.shared.impact(.light)
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
            RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.large)
                .fill(DesignTokens.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.large)
                        .stroke(
                            isFocused ? DesignTokens.Colors.primary : DesignTokens.Colors.border,
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
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button(action: {
                    HapticManager.shared.selection()
                    withAnimation(AnimationSystem.Presets.spring) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: DesignTokens.Spacing.extraSmall) {
                        Text(tab)
                            .font(selectedTab == index ? 
                                  DesignTokens.Typography.titleMedium : 
                                  DesignTokens.Typography.bodyMedium)
                            .foregroundColor(
                                selectedTab == index ? 
                                DesignTokens.Colors.primary : 
                                DesignTokens.Colors.textSecondary
                            )
                            .animation(AnimationSystem.Presets.easeInOut, value: selectedTab)
                        
                        if selectedTab == index {
                            RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.small)
                                .fill(DesignTokens.Colors.primary)
                                .frame(height: 3)
                                .matchedGeometryEffect(id: "tab_indicator", in: tabNamespace)
                        } else {
                            RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.small)
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
            course.description?.lowercased().contains(searchText.lowercased()) == true
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
                    EnhancedCourseCard(course: course)
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
            path.name.lowercased().contains(searchText.lowercased()) ||
            path.description?.lowercased().contains(searchText.lowercased()) == true
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
                    Text(path.name)
                        .font(DesignTokens.Typography.titleMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    if let description = path.description {
                        Text(description)
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .lineLimit(isExpanded ? nil : 2)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    HapticManager.shared.impact(.light)
                    withAnimation(AnimationSystem.Presets.spring) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(AnimationSystem.Presets.easeInOut, value: isExpanded)
                }
            }
            
            // Progress indicator
            ProgressBar(
                progress: path.progress,
                showPercentage: true,
                color: DesignTokens.Colors.success
            )
            
            if isExpanded {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                    Text("Courses in this path:")
                        .font(DesignTokens.Typography.labelMedium)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    ForEach(path.courses, id: \.id) { course in
                        HStack {
                            Image(systemName: course.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 16))
                                .foregroundColor(course.isCompleted ? DesignTokens.Colors.success : DesignTokens.Colors.textSecondary)
                            
                            Text(course.title)
                                .font(DesignTokens.Typography.bodyMedium)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .strikethrough(course.isCompleted)
                            
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
            VStack(spacing: DesignTokens.Spacing.large) {
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
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.medium) {
            HStack {
                Text("Your Progress")
                    .font(DesignTokens.Typography.titleLarge)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Text("\(Int(progress.overallProgress * 100))%")
                    .font(DesignTokens.Typography.headlineSmall)
                    .foregroundColor(DesignTokens.Colors.primary)
            }
            
            ProgressBar(
                progress: progress.overallProgress,
                showPercentage: false,
                color: DesignTokens.Colors.primary,
                height: 12
            )
            
            HStack {
                StatView(
                    title: "Completed",
                    value: "\(progress.completedCourses)",
                    icon: "checkmark.circle.fill",
                    color: DesignTokens.Colors.success
                )
                
                Spacer()
                
                StatView(
                    title: "In Progress",
                    value: "\(progress.inProgressCourses)",
                    icon: "clock.fill",
                    color: DesignTokens.Colors.warning
                )
                
                Spacer()
                
                StatView(
                    title: "Total Hours",
                    value: "\(progress.totalLearningHours)",
                    icon: "clock.fill",
                    color: DesignTokens.Colors.info
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
            Image(systemName: achievement.icon)
                .font(.system(size: 32))
                .foregroundColor(DesignTokens.Colors.primary)
            
            Text(achievement.title)
                .font(DesignTokens.Typography.labelMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(achievement.dateEarned.formatted(date: .abbreviated, time: .omitted))
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.textSecondary)
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
                
                Text("\(progress.currentStreak) days")
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
                    current: progress.weeklyGoals.completedCourses,
                    target: progress.weeklyGoals.targetCourses
                )
                
                GoalRow(
                    title: "Study 10 hours",
                    current: progress.weeklyGoals.studyHours,
                    target: progress.weeklyGoals.targetHours
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
                showPercentage: false,
                color: progress >= 1.0 ? DesignTokens.Colors.success : DesignTokens.Colors.info,
                height: 6
            )
        }
    }
}

#Preview {
    ModernLearnView()
}
