import SwiftUI
import Combine

@MainActor
class LearnViewModel: ObservableObject {
    @Published var featuredCourses: [LearningCourse] = []
    @Published var userCourses: [UserCourse] = []
    @Published var learningPaths: [LearningPath] = []
    @Published var userProgress: UserProgress = UserProgress.mockProgress()
    @Published var searchResults: [LearningCourse] = []
    @Published var isLoading = false
    @Published var isSearching = false
    @Published var errorMessage: String?
    @Published var searchQuery = ""
    @Published var selectedCategory: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let learningService = LearningAPIService.shared
    private let gamificationService = GamificationAPIService.shared
    private let dataManager = DataManager.shared
    private let analyticsService = AnalyticsAPIService.shared
    
    init() {
        setupNotifications()
        setupSearchDebounce()
        loadCachedData()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Public Methods
    func loadData() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        async let coursesTask = loadFeaturedCourses()
        async let userCoursesTask = loadUserCourses()
        async let progressTask = loadUserProgress()
        
        await coursesTask
        await userCoursesTask
        await progressTask
        
        isLoading = false
    }
    
    func refreshData() async {
        featuredCourses.removeAll()
        userCourses.removeAll()
        learningPaths.removeAll()
        await loadData()
    }
    
    func enrollInCourse(_ course: LearningCourse) async {
        do {
            let enrollment = try await learningService.enrollInCourse(course.id)
            
            if response.success {
                // Add to user courses
                let userCourse = UserCourse(
                    id: UUID(),
                    course: course,
                    enrollmentDate: response.enrollmentDate,
                    progress: 0.0,
                    isCompleted: false,
                    lastAccessed: Date()
                )
                userCourses.insert(userCourse, at: 0)
                
                // Update featured course enrollment status
                if let index = featuredCourses.firstIndex(where: { $0.id == course.id }) {
                    featuredCourses[index].isEnrolled = true
                }
                
                // Track analytics
                await analyticsService.trackEvent(
                    Constants.AnalyticsEvents.courseStarted,
                    parameters: [
                        "course_id": course.id,
                        "course_title": course.title,
                        "category": course.category
                    ]
                )
                
                // Cache updated data
                dataManager.saveForOffline(userCourses, key: "user_courses")
                
            }
        } catch {
            errorMessage = "Failed to enroll in course: \(error.localizedDescription)"
        }
    }
    
    func updateProgress(courseId: String, lessonId: String, progress: Double) async {
        do {
            let progressUpdate = try await learningService.markLessonCompleted(
                lessonId,
                timeSpent: 0, // This would need to be tracked
                score: progress * 100
            )
            
            // Update local progress
            if let courseIndex = userCourses.firstIndex(where: { $0.course.id == courseId }) {
                userCourses[courseIndex].progress = progress
                userCourses[courseIndex].lastAccessed = Date()
                
                // Check if course is completed
                if response.totalProgress >= 1.0 && !userCourses[courseIndex].isCompleted {
                    await completeCourse(courseId: courseId)
                }
            }
            
            // Track analytics
            await analyticsService.trackEvent(
                Constants.AnalyticsEvents.lessonCompleted,
                parameters: [
                    "course_id": courseId,
                    "lesson_id": lessonId,
                    "progress": progress
                ]
            )
            
            // Cache updated data
            dataManager.saveForOffline(userCourses, key: "user_courses")
            
        } catch {
            errorMessage = "Failed to update progress: \(error.localizedDescription)"
        }
    }
    
    func completeCourse(courseId: String) async {
        do {
            // Mark course as completed and update progress
            if let courseIndex = userCourses.firstIndex(where: { $0.course.id == courseId }) {
                userCourses[courseIndex].isCompleted = true
                userCourses[courseIndex].progress = 1.0
                userCourses[courseIndex].completionDate = Date()
            }
            
            // Award XP for completion
            try await gamificationService.awardXP(
                points: 100,
                reason: "Course completed",
                categoryId: courseId
            )
            
            // Update user progress
            userProgress.coursesCompleted += 1
            userProgress.totalPoints += 100
                
                // Track analytics
                await analyticsService.trackEvent(
                    Constants.AnalyticsEvents.courseCompleted,
                    parameters: [
                        "course_id": courseId,
                        "points_earned": response.points
                    ]
                )
                
                // Show achievement notification if applicable
                if let certificateUrl = response.certificateUrl {
                    NotificationCenter.default.post(
                        name: Constants.NotificationNames.achievementUnlocked,
                        object: certificateUrl
                    )
                }
                
                // Cache updated data
                dataManager.saveForOffline(userCourses, key: "user_courses")
                dataManager.saveForOffline(userProgress, key: "user_progress")
            }
            
        } catch {
            errorMessage = "Failed to complete course: \(error.localizedDescription)"
        }
    }
    
    func searchCourses() async {
        guard !searchQuery.isEmpty else {
            searchResults.removeAll()
            return
        }
        
        isSearching = true
        
        do {
            let results: [LearningCourse] = try await learningService.getCourses(
                category: selectedCategory,
                difficulty: nil // This could be added as a filter parameter
            )
            
            // Filter results by search query locally for now
            // In a real implementation, the API would handle this
            let filteredResults = results.filter { course in
                course.title.localizedCaseInsensitiveContains(searchQuery) ||
                course.description.localizedCaseInsensitiveContains(searchQuery)
            }
            
            searchResults = filteredResults
            
            // Track search analytics
            let event = AnalyticsEvent(
                eventName: Constants.AnalyticsEvents.searchPerformed,
                properties: [
                    "query": searchQuery,
                    "category": selectedCategory ?? "all",
                    "results_count": String(filteredResults.count)
                ],
                timestamp: Date(),
                userId: nil
            )
            
            try await analyticsService.trackEvent(event)
            
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            searchResults.removeAll()
        }
        
        isSearching = false
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults.removeAll()
        selectedCategory = nil
    }
    
    // MARK: - Private Methods
    private func loadFeaturedCourses() async {
        do {
            let courses: [LearningCourse] = try await learningService.getCourses()
            featuredCourses = courses
            dataManager.saveForOffline(courses, key: "featured_courses")
        } catch {
            errorMessage = "Failed to load courses: \(error.localizedDescription)"
            loadCachedCourses()
        }
    }
    
    private func loadUserCourses() async {
        do {
            let courses: [UserCourse] = try await learningService.getUserCourses()
            userCourses = courses
            dataManager.saveForOffline(courses, key: "user_courses")
        } catch {
            errorMessage = "Failed to load user courses: \(error.localizedDescription)"
            loadCachedUserCourses()
        }
    }
    
    private func loadUserProgress() async {
        do {
            let analytics: UserAnalytics = try await AnalyticsAPIService.shared.getUserAnalytics()
            userProgress = UserProgress(
                coursesEnrolled: userCourses.count,
                coursesCompleted: analytics.coursesCompleted,
                totalStudyTime: analytics.totalStudyTime,
                currentStreak: analytics.currentStreak,
                longestStreak: analytics.longestStreak,
                totalPoints: 0, // This should come from user profile
                level: calculateLevel(from: analytics.totalStudyTime),
                achievements: [] // This should be loaded separately
            )
            dataManager.saveForOffline(userProgress, key: "user_progress")
        } catch {
            print("Failed to load user progress: \(error.localizedDescription)")
        }
    }
    
    private func loadCachedData() {
        loadCachedCourses()
        loadCachedUserCourses()
        
        if let cachedProgress: UserProgress = dataManager.loadFromOffline(UserProgress.self, key: "user_progress") {
            userProgress = cachedProgress
        }
    }
    
    private func loadCachedCourses() {
        if let cached: [LearningCourse] = dataManager.loadFromOffline([LearningCourse].self, key: "featured_courses") {
            featuredCourses = cached
        }
    }
    
    private func loadCachedUserCourses() {
        if let cached: [UserCourse] = dataManager.loadFromOffline([UserCourse].self, key: "user_courses") {
            userCourses = cached
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: Constants.NotificationNames.userDidLogin)
            .sink { [weak self] _ in
                Task {
                    await self?.refreshData()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Constants.NotificationNames.dataDidSync)
            .sink { [weak self] _ in
                Task {
                    await self?.loadData()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupSearchDebounce() {
        $searchQuery
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task {
                    await self?.searchCourses()
                }
            }
            .store(in: &cancellables)
    }
    
    private func calculateLevel(from studyTime: Double) -> Int {
        // Simple level calculation - 10 hours per level
        return max(1, Int(studyTime / 36000)) // 36000 seconds = 10 hours
    }

// MARK: - User Course Model
struct UserCourse: Codable, Identifiable {
    let id: UUID
    let course: LearningCourse
    let enrollmentDate: Date
    var progress: Double
    var isCompleted: Bool
    var lastAccessed: Date
    var completionDate: Date?
    
    init(id: UUID = UUID(), course: LearningCourse, enrollmentDate: Date, progress: Double, isCompleted: Bool, lastAccessed: Date, completionDate: Date? = nil) {
        self.id = id
        self.course = course
        self.enrollmentDate = enrollmentDate
        self.progress = progress
        self.isCompleted = isCompleted
        self.lastAccessed = lastAccessed
        self.completionDate = completionDate
    }
}