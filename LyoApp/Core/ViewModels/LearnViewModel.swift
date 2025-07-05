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
        
        do {
            // Load courses, user courses, and progress from API
            async let coursesResponse = apiClient.getCourses()
            async let userCoursesResponse = apiClient.getUserCourses()
            async let progressResponse = apiClient.getUserProgress()
            
            let courses = try await coursesResponse
            let userCoursesData = try await userCoursesResponse
            let progress = try await progressResponse
            
            DispatchQueue.main.async {
                self.featuredCourses = courses
                self.userCourses = userCoursesData
                self.userProgress = progress
                self.isOffline = false
            }
            
            // Cache the new data
            await cacheLearningData()
            
        } catch {
            print("Error loading learning data: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load courses: \(error.localizedDescription)"
                self.isOffline = true
            }
            
            // Fall back to cached data if API fails
            await loadCachedData()
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        await loadData()
    }
    
    func enrollInCourse(_ courseId: String) async {
        do {
            let enrollment = try await apiClient.enrollInCourse(courseId: courseId)
            
            // Update local state
            DispatchQueue.main.async {
                self.userCourses.append(enrollment)
            }
            
            // Cache updated data
            await cacheLearningData()
            
            // Track analytics
            await AnalyticsAPIService.shared.trackEvent("course_enrolled", parameters: [
                "course_id": courseId,
                "enrollment_method": "featured_courses"
            ])
            
        } catch {
            print("Error enrolling in course: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to enroll in course: \(error.localizedDescription)"
            }
        }
    }
    
    func markLessonComplete(_ lessonId: String, courseId: String) async {
        do {
            let progressUpdate = try await apiClient.markLessonComplete(
                lessonId: lessonId,
                courseId: courseId
            )
            
            // Update local progress
            DispatchQueue.main.async {
                if let userCourseIndex = self.userCourses.firstIndex(where: { $0.courseId.uuidString == courseId }) {
                    self.userCourses[userCourseIndex].progress = progressUpdate.progress
                    self.userCourses[userCourseIndex].lastAccessedAt = Date()
                }
                
                // Update overall user progress
                self.userProgress = progressUpdate.userProgress
            }
            
            // Cache updated data
            await cacheLearningData()
            
            // Track analytics
            await AnalyticsAPIService.shared.trackEvent("lesson_completed", parameters: [
                "lesson_id": lessonId,
                "course_id": courseId,
                "progress": String(progressUpdate.progress)
            ])
            
        } catch {
            print("Error marking lesson complete: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to update lesson progress: \(error.localizedDescription)"
            }
        }
    }
    
    func searchCourses(_ query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        do {
            let results = try await apiClient.searchCourses(query: query)
            DispatchQueue.main.async {
                self.searchResults = results
            }
            
            // Track search analytics
            await AnalyticsAPIService.shared.trackEvent("course_search", parameters: [
                "query": query,
                "results_count": String(results.count)
            ])
            
        } catch {
            print("Error searching courses: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Search failed: \(error.localizedDescription)"
                self.searchResults = []
            }
        }
        
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
        if let progressPublisher = webSocketManager.progressUpdatesPublisher {
            progressPublisher
                .sink { [weak self] update in
                    self?.handleRealTimeProgressUpdate(update)
                }
                .store(in: &cancellables)
        }
        
        // Listen for course updates
        if let coursePublisher = webSocketManager.courseUpdatesPublisher {
            coursePublisher
                .sink { [weak self] update in
                    self?.handleRealTimeCourseUpdate(update)
                }
                .store(in: &cancellables)
        }
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
        DispatchQueue.main.async {
            // Update user course progress
            if let userCourseIndex = self.userCourses.firstIndex(where: { $0.courseId.uuidString == update.courseId }) {
                self.userCourses[userCourseIndex].progress = update.progress
                self.userCourses[userCourseIndex].lastAccessedAt = update.timestamp
            }
            
            // Refresh user progress from API to get latest data
            Task {
                do {
                    let latestProgress = try await self.apiClient.getUserProgress()
                    DispatchQueue.main.async {
                        self.userProgress = latestProgress
                    }
                } catch {
                    print("Error fetching updated progress: \(error)")
                }
            }
        }
        
        print("Progress update received for course: \(update.courseId)")
    }
    
    private func handleRealTimeCourseUpdate(_ update: CourseUpdate) {
        DispatchQueue.main.async {
            // Update course in featured courses list
            if let courseIndex = self.featuredCourses.firstIndex(where: { $0.id.uuidString == update.courseId }) {
                if let title = update.title {
                    self.featuredCourses[courseIndex].title = title
                }
                // Update other course properties as needed
            }
            
            // Update course in user courses list
            if let userCourseIndex = self.userCourses.firstIndex(where: { $0.courseId.uuidString == update.courseId }) {
                self.userCourses[userCourseIndex].lastAccessedAt = update.updatedAt
            }
        }
        
        print("Course update received: \(update.courseId)")
    }
    
    private func loadCachedData() async {
        let cachedCourses = coreDataManager.fetchCachedCourses()
        let cachedUserCourses = coreDataManager.fetchCachedUserCourses()
        let cachedProgress = coreDataManager.fetchCachedUserProgress()
        
        DispatchQueue.main.async {
            if !cachedCourses.isEmpty {
                self.featuredCourses = cachedCourses
                self.isOffline = true
            }
            
            if !cachedUserCourses.isEmpty {
                self.userCourses = cachedUserCourses
            }
            
            if let progress = cachedProgress {
                self.userProgress = progress
            }
        }
    }
    
    private func cacheLearningData() async {
        coreDataManager.cacheCourses(featuredCourses)
        print("Cached \(featuredCourses.count) featured courses")
        
        coreDataManager.cacheUserCourses(userCourses)
        print("Cached \(userCourses.count) user courses")
        
        if let progress = userProgress {
            coreDataManager.cacheUserProgress(progress)
            print("Cached user progress")
        }
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