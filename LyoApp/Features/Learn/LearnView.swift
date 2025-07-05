import SwiftUI

// MARK: - Learn Type Definitions
// Note: CDCourse type is defined in AppModels.swift and used throughout this file
struct LearningGoal: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let target: Int
    let current: Int
    let deadline: Date?
    let category: String
    
    var progress: Double {
        guard target > 0 else { return 0 }
        return Double(current) / Double(target)
    }
    
    init(title: String, description: String, target: Int, current: Int = 0, deadline: Date? = nil, category: String = "general") {
        self.id = UUID()
        self.title = title
        self.description = description
        self.target = target
        self.current = current
        self.deadline = deadline
        self.category = category
    }
}

struct LearnView: View {
    @StateObject private var viewModel = LearnViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Glass background effect
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Dynamic Header
                    LyoHeaderView()
                    
                    // Custom tab selector
                    LearnTabSelector(selectedTab: $selectedTab)
                    
                    // Tab content
                    TabView(selection: $selectedTab) {
                        CoursesView(courses: viewModel.featuredCourses)
                            .tag(0)
                        
                        ModernLearningPathsView(paths: viewModel.learningPaths, searchText: "")
                            .tag(1)
                        
                        if let userProgress = viewModel.userProgress {
                            LearningProgressView(progress: userProgress)
                                .tag(2)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
                
                // Study Buddy FAB
                StudyBuddyFAB(screenContext: "learn")
            }
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Material.ultraThin, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadData()
            }
        }
    }
}

struct LearnTabSelector: View {
    @Binding var selectedTab: Int
    private let tabs = ["CDCourses", "Paths", "Progress"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab)
                            .font(.body)
                            .fontWeight(selectedTab == index ? .semibold : .medium)
                            .foregroundColor(selectedTab == index ? .white : .white.opacity(0.6))
                        
                        Rectangle()
                            .fill(selectedTab == index ? Color.blue : Color.clear)
                            .frame(height: 3)
                            .cornerRadius(1.5)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .background(Material.ultraThin)
    }
}

struct CoursesView: View {
    let courses: [Course]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Featured section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Featured Courses")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(courses.prefix(5)) { course in
                                CourseCard(course: course, style: .featured)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // All courses section
                VStack(alignment: .leading, spacing: 16) {
                    Text("All Courses")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    LazyVStack(spacing: 12) {
                        ForEach(courses) { course in
                            CourseCard(course: course, style: .list)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.top)
        }
    }
}

struct CourseCard: View {
    let course: Course
    let style: Style
    
    enum Style {
        case featured
        case list
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Course image/icon
            courseImageSection
            
            // Course info
            courseInfoSection
        }
        .padding(style == .featured ? 12 : 8)
        .frame(width: style == .featured ? 200 : nil)
        .background(courseCardBackground)
    }
    
    @ViewBuilder
    private var courseImageSection: some View {
        if style == .featured {
            FeaturedCourseHeader(course: course)
        } else {
            AsyncImage(url: URL(string: course.thumbnail?.url ?? "")) { image in
                image.resizable()
            } placeholder: {
                Rectangle().fill(Color.gray)
            }
            .aspectRatio(16/9, contentMode: .fit)
            .cornerRadius(8)
        }
    }
    
    @ViewBuilder
    private var courseInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(course.title)
                .font(style == .featured ? .headline : .body)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(2)
            
            Text(course.instructor.name)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            courseMetadataRow
        }
    }
    
    @ViewBuilder
    private var courseMetadataRow: some View {
        HStack {
            Text("\(Int(course.duration / 60))m")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
            
            courseRatingView
        }
    }
    
    @ViewBuilder
    private var courseRatingView: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
                .font(.caption)
            Text(String(format: "%.1f", course.rating.average))
                .font(.caption)
                .foregroundColor(.yellow)
        }
    }
    
    private var courseCardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Material.ultraThin)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

struct FeaturedCourseHeader: View {
    let course: Course
    
    var body: some View {
        Rectangle()
            .fill(course.category.gradient)
            .aspectRatio(4/3, contentMode: .fit)
            .cornerRadius(12)
            .overlay(
                VStack {
                    Image(systemName: course.category.icon)
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    Text(course.category.name)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            )
    }
}

struct ListCourseHeader: View {
    let course: Course
    
    var body: some View {
        HStack {
            Circle()
                .fill(course.category.gradient)
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: course.category.icon)
                        .font(.title2)
                        .foregroundColor(.white)
                )
            
            Spacer()
        }
    }
}

struct LearningPathsView: View {
    let paths: [LearningPath]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(paths) { path in
                    LearningPathCard(path: path)
                        .padding(.horizontal)
                }
            }
            .padding(.top)
        }
    }
}

struct LearningPathCard: View {
    let path: LearningPath
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(path.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(path.description)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack {
                    Text("\(path.completedCourses)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("of \(path.courses.count)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            ProgressView(value: path.progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            HStack {
                Text("\(Int(path.estimatedDuration / 3600))h")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Text("\(Int(path.progress * 100))% complete")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.ultraThin)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct LearningProgressView: View {
    let progress: UserProgress
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Stats overview
                StatsOverviewCard(progress: progress)
                
                // Recent achievements
                AchievementsSection(achievements: progress.recentAchievements)
            }
            .padding()
        }
    }
}

struct StatsOverviewCard: View {
    let progress: UserProgress
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Your Progress")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatItem(title: "Total Hours", value: "\(Int(progress.totalHours))", icon: "clock")
                StatItem(title: "Courses", value: "\(progress.completedCourses)", icon: "book")
                StatItem(title: "Current Streak", value: "\(progress.currentStreak)", icon: "flame")
                StatItem(title: "Level", value: "\(progress.level)", icon: "star")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.ultraThin)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Material.ultraThin)
        )
    }
}

struct RecentAchievementsCard: View {
    let achievements: [Achievement]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Achievements")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            ForEach(achievements.prefix(3)) { achievement in
                HStack {
                    Circle()
                        .fill(Color.yellow.gradient)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(achievement.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Text(achievement.description)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.ultraThin)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct LearningGoalsCard: View {
    let goals: [LearningGoal]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Learning Goals")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            ForEach(goals.prefix(3)) { goal in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(goal.title)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(Int(goal.progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    ProgressView(value: goal.progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.ultraThin)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

#Preview {
    LearnView()
}