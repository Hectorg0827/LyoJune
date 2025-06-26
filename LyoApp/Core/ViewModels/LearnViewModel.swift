import SwiftUI
import Combine

// MARK: - Learning Type Definitions
struct LearningPath: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let courses: [String] // Course IDs
    let estimatedDuration: TimeInterval
    let difficulty: String
    let category: String
    let progress: Double
    
    init(title: String, description: String, courses: [String] = [], estimatedDuration: TimeInterval = 0, difficulty: String = "beginner", category: String = "general", progress: Double = 0.0) {
        self.title = title
        self.description = description
        self.courses = courses
        self.estimatedDuration = estimatedDuration
        self.difficulty = difficulty
        self.category = category
        self.progress = progress
    }
}

struct ProgressUpdate: Codable {
    let courseId: String
    let lessonId: String?
    let progress: Double
    let timestamp: Date
    
    init(courseId: String, lessonId: String? = nil, progress: Double, timestamp: Date = Date()) {
        self.courseId = courseId
        self.lessonId = lessonId
        self.progress = progress
        self.timestamp = timestamp
    }
}

struct CourseUpdate: Codable {
    let courseId: String
    let title: String?
    let status: String?
    let updatedAt: Date
    
    init(courseId: String, title: String? = nil, status: String? = nil, updatedAt: Date = Date()) {
        self.courseId = courseId
        self.title = title
        self.status = status
        self.updatedAt = updatedAt
    }
}

// MARK: - UserProgress Extension
extension UserProgress {
    static func mockProgress() -> UserProgress {
        return UserProgress(
            totalCoursesEnrolled: 5,
            totalCoursesCompleted: 2,
            totalLessonsCompleted: 25,
            averageScore: 85.0,
            totalStudyTime: 3600 * 24, // 24 hours
            currentStreak: 7,
            lastStudyDate: Date(),
            weeklyGoal: 3600 * 10, // 10 hours
            weeklyProgress: 3600 * 6 // 6 hours
        )
    }
}

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
    @Published var isOffline = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // Enhanced services
    private let serviceFactory = EnhancedServiceFactory.shared
    
    private var apiService: EnhancedAPIService {
        serviceFactory.apiService
    }
    
    private var coreDataManager: CoreDataManager {
        serviceFactory.coreDataManager
    }
    
    private var webSocketManager: WebSocketManager {
        serviceFactory.webSocketManager
    }
    
    init() {
        setupNotifications()
        setupRealTimeUpdates()
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
        
        do {
            // Load from cache first for instant UI
            await loadCachedData()
            
            // Then fetch fresh data from API
            async let coursesTask = apiService.getFeaturedCourses()
            async let userCoursesTask = apiService.getUserCourses()
            async let progressTask = apiService.getUserProgress()
            async let pathsTask = apiService.getLearningPaths()
            
            let (courses, userCoursesData, progress, paths) = try await (coursesTask, userCoursesTask, progressTask, pathsTask)
            
            featuredCourses = courses
            userCourses = userCoursesData
            userProgress = progress
            learningPaths = paths
            
            // Cache the new data
            await cacheLearningData()
            
            isOffline = false
            
        } catch {
            handleError(error)
            // If network fails, show cached data
            if featuredCourses.isEmpty {
                await loadCachedData()
            }
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        await loadData()
    }
    
    func enrollInCourse(_ courseId: String) async {
        do {
            let enrollment = try await apiService.enrollInCourse(courseId: courseId)
            
            // Update local state
            if let index = featuredCourses.firstIndex(where: { $0.id == courseId }) {
                userCourses.append(UserCourse(
                    id: enrollment.id,
                    course: featuredCourses[index],
                    enrolledAt: Date(),
                    progress: 0.0,
                    completedLessons: 0,
                    totalLessons: featuredCourses[index].lessons?.count ?? 0
                ))
            }
            
            // Update cache
            await coreDataManager.saveUserCourse(enrollment)
            
            // Track analytics
            await apiService.trackAnalyticsEvent(
                eventName: "course_enrolled",
                properties: [
                    "course_id": courseId,
                    "enrollment_method": "featured_courses"
                ]
            )
            
        } catch {
            handleError(error)
        }
    }
    
    func markLessonComplete(_ lessonId: String, courseId: String) async {
        do {
            let progressUpdate = try await apiService.markLessonComplete(
                lessonId: lessonId,
                courseId: courseId
            )
            
            // Update local progress
            if let courseIndex = userCourses.firstIndex(where: { $0.course.id == courseId }) {
                userCourses[courseIndex].completedLessons += 1
                userCourses[courseIndex].progress = progressUpdate.progress
            }
            
            // Update overall user progress
            userProgress.totalCompletedLessons += 1
            userProgress.streak = progressUpdate.currentStreak
            userProgress.points += progressUpdate.pointsEarned
            
            // Update cache
            await coreDataManager.updateLessonProgress(lessonId: lessonId, courseId: courseId, isCompleted: true)
            
            // Track analytics
            await apiService.trackAnalyticsEvent(
                eventName: "lesson_completed",
                properties: [
                    "lesson_id": lessonId,
                    "course_id": courseId,
                    "progress": progressUpdate.progress
                ]
            )
            
        } catch {
            handleError(error)
        }
    }
    
    func searchCourses(_ query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        do {
            let results = try await apiService.searchCourses(query: query, category: selectedCategory)
            searchResults = results
            
            // Track search analytics
            await apiService.trackAnalyticsEvent(
                eventName: "course_search",
                properties: [
                    "query": query,
                    "category": selectedCategory ?? "all",
                    "results_count": results.count
                ]
            )
            
        } catch {
            handleError(error)
            searchResults = []
        }
        
        isSearching = false
    }
    
    // MARK: - Private Methods
    private func setupNotifications() {
        // Listen for network connectivity changes
        NotificationCenter.default.publisher(for: .networkConnectivityChanged)
            .sink { [weak self] notification in
                Task { @MainActor in
                    self?.isOffline = !(notification.object as? Bool ?? true)
                    if !self!.isOffline && self!.featuredCourses.isEmpty {
                        await self?.loadData()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Listen for authentication changes
        NotificationCenter.default.publisher(for: .authenticationStateChanged)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.loadData()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupRealTimeUpdates() {
        // Listen for real-time progress updates
        webSocketManager.progressUpdatesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handleRealTimeProgressUpdate(update)
            }
            .store(in: &cancellables)
        
        // Listen for new course announcements
        webSocketManager.courseUpdatesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handleRealTimeCourseUpdate(update)
            }
            .store(in: &cancellables)
    }
    
    private func setupSearchDebounce() {
        $searchQuery
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                Task {
                    await self?.searchCourses(query)
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleRealTimeProgressUpdate(_ update: ProgressUpdate) {
        // Update user progress from real-time updates
        userProgress.points = update.totalPoints
        userProgress.streak = update.currentStreak
        userProgress.level = update.level
        
        // Update specific course progress if available
        if let courseId = update.courseId,
           let courseIndex = userCourses.firstIndex(where: { $0.course.id == courseId }) {
            userCourses[courseIndex].progress = update.courseProgress
            userCourses[courseIndex].completedLessons = update.completedLessons
        }
    }
    
    private func handleRealTimeCourseUpdate(_ update: CourseUpdate) {
        switch update.type {
        case .newCourse:
            if let newCourse = update.course, !featuredCourses.contains(where: { $0.id == newCourse.id }) {
                featuredCourses.insert(newCourse, at: 0)
            }
        case .courseUpdated:
            if let updatedCourse = update.course,
               let index = featuredCourses.firstIndex(where: { $0.id == updatedCourse.id }) {
                featuredCourses[index] = updatedCourse
            }
        }
    }
    
    private func loadCachedData() async {
        do {
            let cachedCourses = try await coreDataManager.getCachedCourses()
            let cachedUserCourses = try await coreDataManager.getCachedUserCourses()
            let cachedProgress = try await coreDataManager.getCachedUserProgress()
            
            if !cachedCourses.isEmpty {
                featuredCourses = cachedCourses
                isOffline = true
            }
            
            if !cachedUserCourses.isEmpty {
                userCourses = cachedUserCourses
            }
            
            if let progress = cachedProgress {
                userProgress = progress
            }
            
        } catch {
            print("Failed to load cached learning data: \(error.localizedDescription)")
        }
    }
    
    private func cacheLearningData() async {
        do {
            try await coreDataManager.cacheCourses(featuredCourses)
            try await coreDataManager.cacheUserCourses(userCourses)
            try await coreDataManager.cacheUserProgress(userProgress)
        } catch {
            print("Failed to cache learning data: \(error.localizedDescription)")
        }
    }
    
    private func handleError(_ error: Error) {
        if let apiError = error as? APIError {
            switch apiError {
            case .networkError:
                errorMessage = "No internet connection. Showing cached content."
                isOffline = true
            case .unauthorized:
                errorMessage = "Session expired. Please log in again."
                Task {
                    await serviceFactory.authService.refreshToken()
                }
            case .serverError:
                errorMessage = "Server error. Please try again later."
            default:
                errorMessage = "Something went wrong. Please try again."
            }
        } else {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - User Course Model
struct UserCourse: Codable, Identifiable {
    let id: UUID
    let course: Course
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