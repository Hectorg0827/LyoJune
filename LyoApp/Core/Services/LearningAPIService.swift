import Foundation
import Combine

// MARK: - Local Type Definitions for API Service
// These avoid import conflicts and ambiguity issues

// Local types namespace to avoid conflicts
public enum LearningAPI {
    // Local Lesson type for API responses
    public struct Lesson: Codable, Identifiable {
        public let id: UUID
        public let courseId: UUID
        public let title: String
        public let description: String
        public let content: String
        public let duration: TimeInterval
        public let order: Int
        public let videoURL: URL?
        public let resourceURLs: [URL]
        
        public init(id: UUID, courseId: UUID, title: String, description: String, content: String, duration: TimeInterval, order: Int, videoURL: URL? = nil, resourceURLs: [URL] = []) {
            self.id = id
            self.courseId = courseId
            self.title = title
            self.description = description
            self.content = content
            self.duration = duration
            self.order = order
            self.videoURL = videoURL
            self.resourceURLs = resourceURLs
        }
    }

    // Local Quiz type for API responses
    public struct Quiz: Codable, Identifiable {
        public let id: UUID
        public let topicId: UUID
        public let title: String
        public let description: String
        public let questions: [QuizQuestion]
        public let timeLimit: TimeInterval?
        public let passingScore: Double
        
        public init(id: UUID, topicId: UUID, title: String, description: String, questions: [QuizQuestion], timeLimit: TimeInterval? = nil, passingScore: Double) {
            self.id = id
            self.topicId = topicId
            self.title = title
            self.description = description
            self.questions = questions
            self.timeLimit = timeLimit
            self.passingScore = passingScore
        }
    }

    // Removed duplicate QuizQuestion - use the canonical one from AppModels.swift
    
    // Local UserCourse type for API responses
    public struct UserCourse: Codable, Identifiable {
        public let id: UUID
        public let courseId: UUID
        public let userId: UUID
        public let enrolledAt: Date
        public let progress: Double
        public let completedAt: Date?
        public let lastAccessedAt: Date
        
        public init(id: UUID, courseId: UUID, userId: UUID, enrolledAt: Date, progress: Double, completedAt: Date? = nil, lastAccessedAt: Date) {
            self.id = id
            self.courseId = courseId
            self.userId = userId
            self.enrolledAt = enrolledAt
            self.progress = progress
            self.completedAt = completedAt
            self.lastAccessedAt = lastAccessedAt
        }
    }
}

public struct LearningAPILessonProgress: Codable {
    public let lessonId: String
    public let isCompleted: Bool
    public let timeSpent: TimeInterval
    public let score: Double?
    public let completedAt: Date
}

public struct LearningAPIStudyPlan: Codable {
    public let id: String
    public let title: String
    public let goals: [String]
    public let difficulty: String
}

public struct LearningAPIStudyPlanProgress: Codable {
    public let completedMilestones: [String]
    public let hoursSpent: TimeInterval
}

public struct LearningAPIQuizFeedback: Codable {
    public let isCorrect: Bool
    public let explanation: String
    public let score: Int
}

public struct LearningAPIRecommendation: Codable {
    public let id: String
    public let type: String
    public let title: String
    public let description: String
}

// MARK: - Learning API Service
@MainActor
class LearningAPIService {
    static let shared = LearningAPIService()
    
    private let networkManager: EnhancedNetworkManager
    
    private init(networkManager: EnhancedNetworkManager = EnhancedNetworkManager.shared) {
        self.networkManager = networkManager
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
        
        var endpoint = "/courses"
        if !queryParams.isEmpty {
            let queryString = queryParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
            endpoint += "?" + queryString
        }
        
        return try await networkManager.get(endpoint: endpoint)
    }

    func getUserCourses() async throws -> [LearningAPI.UserCourse] {
        return try await networkManager.get(endpoint: "/courses/enrolled")
    }

    func enrollInCourse(_ courseId: String) async throws -> LearningAPI.UserCourse {
        let request = EnrollCourseRequest(courseId: courseId)
        return try await networkManager.post(endpoint: "/courses/enroll", body: request)
    }

    func unenrollFromCourse(_ courseId: String) async throws {
        let _: EmptyResponse = try await networkManager.delete(endpoint: "/courses/\(courseId)/enroll")
    }

    // MARK: - Lessons and Progress
    func getLessons(for courseId: String) async throws -> [LearningAPI.Lesson] {
        return try await networkManager.get(endpoint: "/courses/\(courseId)/lessons")
    }

    func markLessonCompleted(_ lessonId: String, timeSpent: TimeInterval, score: Double? = nil) async throws -> LearningAPILessonProgress {
        let request = CompleteLessonRequest(
            lessonId: lessonId,
            timeSpent: timeSpent,
            score: score,
            completedAt: Date()
        )
        return try await networkManager.post(endpoint: "/courses/lessons/\(lessonId)/complete", body: request)
    }

    func getUserProgress() async throws -> UserProgress {
        return try await networkManager.get(endpoint: "/analytics/progress")
    }

    // MARK: - Study Plans
    func generateStudyPlan(goals: [String], timePerWeek: Int, difficulty: String) async throws -> LearningAPIStudyPlan {
        let request = GenerateStudyPlanRequest(
            learningGoals: goals,
            hoursPerWeek: timePerWeek,
            preferredDifficulty: difficulty
        )
        return try await networkManager.post(endpoint: "/ai/study-plan", body: request)
    }

    func updateStudyPlan(_ planId: String, progress: StudyPlanProgress) async throws -> LearningAPIStudyPlan {
        let request = UpdateStudyPlanRequest(
            planId: planId,
            progress: progress
        )
        return try await networkManager.put(endpoint: "/ai/study-plan/\(planId)", body: request)
    }

    // MARK: - AI-Powered Features
    func generateQuiz(for topicId: String, difficulty: String, questionCount: Int) async throws -> LearningAPI.Quiz {
        let request = GenerateQuizRequest(
            topicId: topicId,
            difficulty: difficulty,
            questionCount: questionCount
        )
        return try await networkManager.post(endpoint: "/ai/quiz/generate", body: request)
    }

    func submitQuizAnswer(_ quizId: String, questionId: String, answer: String) async throws -> LearningAPIQuizFeedback {
        let request = SubmitQuizAnswerRequest(
            quizId: quizId,
            questionId: questionId,
            answer: answer
        )
        return try await networkManager.post(endpoint: "/ai/quiz/\(quizId)/answer", body: request)
    }

    func getPersonalizedRecommendations() async throws -> [LearningAPIRecommendation] {
        return try await networkManager.get(endpoint: "/ai/recommendations")
    }
}
