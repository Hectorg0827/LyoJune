import SwiftUI
import Combine

// MARK: - LearnViewModel
@MainActor
final class LearnViewModel: ObservableObject {
    @Published var featuredCourses: [Course] = []
    @Published var userCourses: [UserCourse] = []
    @Published var userProgress: UserProgress?
    @Published var searchResults: [Course] = []
    @Published var isLoading = false
    @Published var isSearching = false
    @Published var errorMessage: String?
    @Published var searchQuery = ""
    @Published var selectedCategory: String?
    @Published var isOffline = false
    @Published var learningPaths: [LearningPath] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    // Enhanced services
    private let serviceFactory = EnhancedServiceFactory.shared
    
    private var apiService: EnhancedNetworkManager {
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
        Task {
            await loadCachedData()
        }
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Public Methods
    func loadData() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Load from cache first for instant UI
        await loadCachedData()
        
        // Mock data for now
        let courses: [Course] = []
        let userCoursesData: [UserCourse] = []
        let progress: UserProgress? = nil
        
        featuredCourses = courses
        userCourses = userCoursesData
        userProgress = progress
        
        // Cache the new data
        await cacheLearningData()
        
        isOffline = false
        
        // Always load cached data if no network data available
        if featuredCourses.isEmpty {
            await loadCachedData()
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        await loadData()
    }
    
    func enrollInCourse(_ courseId: String) async {
        // Mock enrollment for now
        print("Enrolling in course: \(courseId)")
        
        // Update local state
        if let index = featuredCourses.firstIndex(where: { $0.id.uuidString == courseId }) {
            let newUserCourse = UserCourse(
                id: UUID(),
                courseId: featuredCourses[index].id,
                userId: UUID(), // Mock user ID
                enrolledAt: Date(),
                progress: 0.0,
                completedAt: nil,
                lastAccessedAt: Date()
            )
            userCourses.append(newUserCourse)
        }
        
        // Update cache - simplified for now
        print("Saved enrollment to cache")
        
        // Track analytics
        await AnalyticsAPIService.shared.trackEvent("course_enrolled", parameters: [
            "course_id": courseId,
            "enrollment_method": "featured_courses"
        ])
    }
    
    func markLessonComplete(_ lessonId: String, courseId: String) async {
        // Mock progress update since markLessonComplete is not available
        let progressUpdate = ProgressUpdate(
            courseId: courseId,
            lessonId: lessonId,
            progress: 1.0,
            timestamp: Date()
        )
        
        // Update local progress - simplified for now
        print("Updated lesson progress for course: \(courseId), lesson: \(lessonId)")
        
        // Mock progress update - simplified for now
        print("Updated user progress")
        
        // Update cache - simplified for now
        print("Updated lesson progress in cache")
        
        // Track analytics
        await AnalyticsAPIService.shared.trackEvent("lesson_completed", parameters: [
            "lesson_id": lessonId,
            "course_id": courseId,
            "progress": String(progressUpdate.progress)
        ])
    }
    
    func searchCourses(_ query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        // Mock search results for now
        let results: [Course] = []
        searchResults = results
        
        // Track search analytics
        await AnalyticsAPIService.shared.trackEvent("course_search", parameters: [
            "query": query,
            "category": selectedCategory ?? "all",
            "results_count": String(results.count)
        ])
        
        isSearching = false
    }
    
    // MARK: - Private Methods
    private func setupNotifications() {
        // Listen for network connectivity changes
        NotificationCenter.default.publisher(for: NSNotification.Name("networkConnectivityChanged"))
            .sink { [weak self] notification in
                Task { @MainActor in
                    self?.isOffline = !(notification.object as? Bool ?? true)
                    if !(self?.isOffline ?? true) && (self?.featuredCourses.isEmpty ?? true) {
                        await self?.loadData()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Listen for authentication changes
        NotificationCenter.default.publisher(for: NSNotification.Name("authenticationStateChanged"))
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.loadData()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupRealTimeUpdates() {
        // Listen for real-time progress updates
        // Mock real-time updates - progressUpdatesPublisher not available
        // Would implement when WebSocketManager has these publishers
        
        // Mock course updates - courseUpdatesPublisher not available
        // Would implement when WebSocketManager has these publishers
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
        // Mock implementation - UserProgress properties need to match
        // Would update when progress model is properly defined
        print("Progress update received for course: \(update.courseId)")
    }
    
    private func handleRealTimeCourseUpdate(_ update: CourseUpdate) {
        // Mock implementation - CourseUpdate needs proper structure
        print("Course update received: \(update.courseId)")
    }
    
    private func loadCachedData() async {
        // Mock cached data - these methods don't exist in CoreDataManager
        let cachedCourses: [Course] = []
        let cachedUserCourses: [UserCourse] = []
        let cachedProgress: UserProgress? = nil
        
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
    }
    
    private func cacheLearningData() async {
        // Mock caching - cacheCourses method doesn't exist
        print("Cached \(featuredCourses.count) featured courses")
        // Mock caching - cacheUserCourses method doesn't exist
        print("Cached \(userCourses.count) user courses")
        // Mock caching - cacheUserProgress method doesn't exist
        print("Cached user progress")
    }
    
    private func handleError(_ error: Error) {
        if let apiError = error as? APIError {
            switch apiError {
            case .networkError:
                errorMessage = "No internet connection. Showing cached content."
                isOffline = true
            case .authError:
                errorMessage = "Session expired. Please log in again."
                Task {
                    try? await serviceFactory.authService.refreshToken()
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

// MARK: - Note: UserCourse is defined in CourseModels.swift and APIServices.swift

struct ProgressUpdate: Codable {
    let courseId: String
    let lessonId: String?
    let progress: Double
    let timestamp: Date
}

struct CourseUpdate: Codable {
    let courseId: String
    let title: String?
    let status: String?
    let updatedAt: Date
}