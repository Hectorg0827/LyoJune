import Foundation
import Combine

// Import required protocols and models
// Note: In a real project, these would be properly imported through modules

// MARK: - Learning API Service
@MainActor
class LearningAPIService: BaseAPIService {
    static let shared = LearningAPIService()
    
    private override init(apiClient: APIClientProtocol = {
        return ConfigurationManager.shared.shouldUseMockBackend ? MockAPIClient.shared : APIClient.shared
    }()) {
        super.init(apiClient: apiClient)
    }
    
    // MARK: - Convenience initializer for dependency injection
    init(apiClient: APIClientProtocol) {
        super.init(apiClient: apiClient)
    }

    // MARK: - Courses
    func getCourses(category: String? = nil, difficulty: String? = nil) async throws -> [LearningCourse] {
        var queryParams: [String: String] = [:]
        if let category = category {
            queryParams["category"] = category
        }
        if let difficulty = difficulty {
            queryParams["difficulty"] = difficulty
        }
        
        let endpoint = Endpoint(path: "/courses", queryParameters: queryParams)
        return try await apiClient.request(endpoint)
    }

    func getUserCourses() async throws -> [UserCourse] {
        let endpoint = Endpoint(path: "/courses/enrolled")
        return try await apiClient.request(endpoint)
    }

    func enrollInCourse(_ courseId: String) async throws -> UserCourse {
        let request = EnrollCourseRequest(courseId: courseId)
        let endpoint = Endpoint(path: "/courses/enroll", method: .post, body: request)
        return try await apiClient.request(endpoint)
    }

    func unenrollFromCourse(_ courseId: String) async throws {
        let endpoint = Endpoint(path: "/courses/\(courseId)/enroll", method: .delete)
        let _: EmptyResponse = try await apiClient.request(endpoint)
    }

    // MARK: - Lessons and Progress
    func getLessons(for courseId: String) async throws -> [Lesson] {
        let endpoint = Endpoint(path: "/courses/\(courseId)/lessons")
        return try await apiClient.request(endpoint)
    }

    func markLessonCompleted(_ lessonId: String, timeSpent: TimeInterval, score: Double? = nil) async throws -> LessonProgress {
        let request = CompleteLessonRequest(
            lessonId: lessonId,
            timeSpent: timeSpent,
            score: score,
            completedAt: Date()
        )
        let endpoint = Endpoint(path: "/courses/lessons/\(lessonId)/complete", method: .post, body: request)
        return try await apiClient.request(endpoint)
    }

    func getUserProgress() async throws -> UserProgress {
        let endpoint = Endpoint(path: "/analytics/progress")
        return try await apiClient.request(endpoint)
    }

    // MARK: - Study Plans
    func generateStudyPlan(goals: [String], timePerWeek: Int, difficulty: String) async throws -> StudyPlan {
        let request = GenerateStudyPlanRequest(
            learningGoals: goals,
            hoursPerWeek: timePerWeek,
            preferredDifficulty: difficulty
        )
        let endpoint = Endpoint(path: "/ai/study-plan", method: .post, body: request)
        return try await apiClient.request(endpoint)
    }

    func updateStudyPlan(_ planId: String, progress: StudyPlanProgress) async throws -> StudyPlan {
        let request = UpdateStudyPlanRequest(
            planId: planId,
            progress: progress
        )
        let endpoint = Endpoint(path: "/ai/study-plan/\(planId)", method: .put, body: request)
        return try await apiClient.request(endpoint)
    }

    // MARK: - AI-Powered Features
    func generateQuiz(for topicId: String, difficulty: String, questionCount: Int) async throws -> Quiz {
        let request = GenerateQuizRequest(
            topicId: topicId,
            difficulty: difficulty,
            questionCount: questionCount
        )
        let endpoint = Endpoint(path: "/ai/quiz/generate", method: .post, body: request)
        return try await apiClient.request(endpoint)
    }

    func submitQuizAnswer(_ quizId: String, questionId: String, answer: String) async throws -> QuizFeedback {
        let request = SubmitQuizAnswerRequest(
            quizId: quizId,
            questionId: questionId,
            answer: answer
        )
        let endpoint = Endpoint(path: "/ai/quiz/\(quizId)/answer", method: .post, body: request)
        return try await apiClient.request(endpoint)
    }

    func getPersonalizedRecommendations() async throws -> [LearningRecommendation] {
        let endpoint = Endpoint(path: "/ai/recommendations")
        return try await apiClient.request(endpoint)
    }
}
