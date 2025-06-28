import Foundation
import Combine

// MARK: - Local Type Definitions
struct LearningContext: Codable {
    let subject: String
    let difficulty: String
    let topic: String?
    let userLevel: String
    
    init(subject: String, difficulty: String, topic: String? = nil, userLevel: String = "beginner") {
        self.subject = subject
        self.difficulty = difficulty
        self.topic = topic
        self.userLevel = userLevel
    }
}

// Removed duplicate QuestionType - use the canonical one from AppModels.swift

// Removed duplicate QuizQuestion - use the canonical one from AppModels.swift

// MARK: - Enhanced AI Service
@MainActor
class EnhancedAIService {
    static let shared = EnhancedAIService()
    
    private let networkManager = EnhancedNetworkManager.shared
    
    // API endpoints
    private let openAIEndpoint = "https://api.openai.com/v1/chat/completions"
    private let gemmaEndpoint = "https://api.gemma.dev/v1/generate"
    
    private init() {}
    
    // MARK: - Configuration
    private let anthropicEndpoint = "https://api.anthropic.com/v1/messages"
    
    private var currentProvider: AIProvider = .gemma
    
    enum AIProvider {
        case gemma
        case openai
        case anthropic
        case local
    }
    
    // MARK: - Chat Completion
    func generateResponse(
        prompt: String,
        context: AIContext?,
        provider: AIProvider = .gemma
    ) async throws -> AIResponse {
        
        let request = createChatRequest(prompt: prompt, context: context)
        
        switch provider {
        case .gemma:
            return try await sendGemmaRequest(request)
        case .openai:
            return try await sendOpenAIRequest(request)
        case .anthropic:
            return try await sendAnthropicRequest(request)
        case .local:
            return try await sendLocalAIRequest(request)
        }
    }
    
    // MARK: - Learning-Specific AI Features
    func explainConcept(
        concept: String,
        context: LearningContext?,
        difficulty: String = "intermediate"
    ) async throws -> ConceptExplanation {
        
        let prompt = buildConceptExplanationPrompt(
            concept: concept,
            context: context,
            difficulty: difficulty
        )
        
        let response = try await generateResponse(
            prompt: prompt,
            context: AIContext(
                type: .conceptExplanation,
                learningContext: context,
                userPreferences: getUserPreferences()
            )
        )
        
        return ConceptExplanation(
            concept: concept,
            explanation: response.content,
            examples: response.examples ?? [],
            relatedConcepts: response.relatedTopics ?? [],
            difficulty: difficulty,
            estimatedReadTime: calculateReadTime(response.content)
        )
    }
    
    func generateQuizQuestions(
        topic: String,
        count: Int = 5,
        difficulty: String = "intermediate",
        questionTypes: [QuestionType] = [.multipleChoice, .trueFalse]
    ) async throws -> [QuizQuestion] {
        
        let prompt = buildQuizGenerationPrompt(
            topic: topic,
            count: count,
            difficulty: difficulty,
            questionTypes: questionTypes
        )
        
        let response = try await generateResponse(
            prompt: prompt,
            context: AIContext(
                type: .quizGeneration,
                learningContext: nil,
                userPreferences: getUserPreferences()
            )
        )
        
        return parseQuizQuestions(from: response.content)
    }
    
    func provideFeedback(
        answer: String,
        correctAnswer: String,
        question: String,
        explanation: String?
    ) async throws -> FeedbackResponse {
        
        let prompt = buildFeedbackPrompt(
            answer: answer,
            correctAnswer: correctAnswer,
            question: question,
            explanation: explanation
        )
        
        let response = try await generateResponse(
            prompt: prompt,
            context: AIContext(
                type: .feedback,
                learningContext: nil,
                userPreferences: getUserPreferences()
            )
        )
        
        return FeedbackResponse(
            isCorrect: answer.lowercased() == correctAnswer.lowercased(),
            feedback: response.content,
            suggestions: response.suggestions ?? [],
            encouragement: response.encouragement ?? "Keep learning!",
            nextSteps: response.nextSteps ?? []
        )
    }
    
    func generateStudyPlan(
        goals: [String],
        timeAvailable: Int, // hours per week
        currentLevel: String,
        interests: [String]
    ) async throws -> StudyPlan {
        
        let prompt = buildStudyPlanPrompt(
            goals: goals,
            timeAvailable: timeAvailable,
            currentLevel: currentLevel,
            interests: interests
        )
        
        let response = try await generateResponse(
            prompt: prompt,
            context: AIContext(
                type: .studyPlanning,
                learningContext: nil,
                userPreferences: getUserPreferences()
            )
        )
        
        return parseStudyPlan(from: response.content)
    }
    
    func analyzeProgress(
        progressData: UserProgressData,
        goals: [String]
    ) async throws -> ProgressAnalysis {
        
        let prompt = buildProgressAnalysisPrompt(
            progressData: progressData,
            goals: goals
        )
        
        let response = try await generateResponse(
            prompt: prompt,
            context: AIContext(
                type: .progressAnalysis,
                learningContext: nil,
                userPreferences: getUserPreferences()
            )
        )
        
        return ProgressAnalysis(
            overallScore: extractOverallScore(from: response.content),
            strengths: response.strengths ?? [],
            improvements: response.improvements ?? [],
            recommendations: response.recommendations ?? [],
            insights: response.content
        )
    }
    
    // MARK: - Private Implementation Methods
    
    private func createChatRequest(prompt: String, context: AIContext?) -> ChatRequest {
        var messages: [ChatMessage] = []
        
        // Add system context
        if let context = context {
            messages.append(ChatMessage(
                role: .system,
                content: buildSystemPrompt(for: context)
            ))
        }
        
        // Add conversation history
        messages.append(contentsOf: getRecentConversation())
        
        // Add current prompt
        messages.append(ChatMessage(
            role: .user,
            content: prompt
        ))
        
        return ChatRequest(
            messages: messages,
            temperature: 0.7,
            maxTokens: 1000,
            topP: 0.9
        )
    }
    
    private func sendGemmaRequest(_ request: ChatRequest) async throws -> AIResponse {
        guard let url = URL(string: gemmaEndpoint) else {
            throw AIError.invalidEndpoint
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(getAPIKey(for: .gemma))", forHTTPHeaderField: "Authorization")
        
        let requestData = try JSONEncoder().encode(request)
        urlRequest.httpBody = requestData
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            throw AIError.httpError(httpResponse.statusCode)
        }
        
        let gemmaResponse = try JSONDecoder().decode(GemmaResponse.self, from: data)
        return convertGemmaResponse(gemmaResponse)
    }
    
    private func sendOpenAIRequest(_ request: ChatRequest) async throws -> AIResponse {
        // Implementation for OpenAI API
        guard let url = URL(string: openAIEndpoint) else {
            throw AIError.invalidEndpoint
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(getAPIKey(for: .openai))", forHTTPHeaderField: "Authorization")
        
        let openAIRequest = OpenAIRequest(
            model: "gpt-4",
            messages: request.messages,
            temperature: request.temperature,
            max_tokens: request.maxTokens
        )
        
        let requestData = try JSONEncoder().encode(openAIRequest)
        urlRequest.httpBody = requestData
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            throw AIError.httpError(httpResponse.statusCode)
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return convertOpenAIResponse(openAIResponse)
    }
    
    private func sendAnthropicRequest(_ request: ChatRequest) async throws -> AIResponse {
        // Implementation for Anthropic Claude API
        guard let url = URL(string: anthropicEndpoint) else {
            throw AIError.invalidEndpoint
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(getAPIKey(for: .anthropic), forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let anthropicRequest = AnthropicRequest(
            model: "claude-3-sonnet-20240229",
            messages: request.messages.map { msg in
                AnthropicMessage(role: msg.role.rawValue, content: msg.content)
            },
            max_tokens: request.maxTokens
        )
        
        let requestData = try JSONEncoder().encode(anthropicRequest)
        urlRequest.httpBody = requestData
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            throw AIError.httpError(httpResponse.statusCode)
        }
        
        let anthropicResponse = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        return convertAnthropicResponse(anthropicResponse)
    }
    
    private func sendLocalAIRequest(_ request: ChatRequest) async throws -> AIResponse {
        // Fallback for when APIs are not available
        return AIResponse(
            content: "I'm currently offline. Please check your internet connection and try again.",
            confidence: 0.5,
            examples: nil,
            suggestions: ["Check internet connection", "Try again later"],
            relatedTopics: nil,
            encouragement: "Don't worry, I'll be back online soon!",
            nextSteps: nil,
            strengths: nil,
            improvements: nil,
            recommendations: nil
        )
    }
    
    // MARK: - Helper Methods
    
    private func getAPIKey(for provider: AIProvider) -> String {
        // In a real app, these would be securely stored
        switch provider {
        case .gemma:
            return ProcessInfo.processInfo.environment["GEMMA_API_KEY"] ?? ""
        case .openai:
            return ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        case .anthropic:
            return ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? ""
        case .local:
            return ""
        }
    }
    
    private func getUserPreferences() -> UserPreferences {
        // This would be loaded from user settings
        return UserPreferences(
            notifications: true,
            darkMode: false,
            language: "en",
            biometricAuth: false,
            pushNotifications: true,
            emailNotifications: true
        )
    }
    
    private func getRecentConversation() -> [ChatMessage] {
        // Return recent conversation history for context
        return []
    }
    
    private func buildSystemPrompt(for context: AIContext) -> String {
        switch context.type {
        case .conceptExplanation:
            return """
            You are an expert tutor specializing in clear, engaging explanations. 
            Adapt your teaching style to the user's level and provide concrete examples.
            Always encourage curiosity and further learning.
            """
        case .quizGeneration:
            return """
            You are an expert at creating educational assessments. 
            Generate fair, challenging questions that test real understanding.
            Provide clear explanations for correct answers.
            """
        case .feedback:
            return """
            You are a supportive learning coach. 
            Provide constructive feedback that motivates and guides improvement.
            Always highlight what was done well before suggesting improvements.
            """
        case .studyPlanning:
            return """
            You are a personalized learning strategist. 
            Create practical, achievable study plans based on individual goals and constraints.
            Focus on sustainable progress and skill building.
            """
        case .progressAnalysis:
            return """
            You are a learning analytics expert. 
            Analyze progress patterns and provide actionable insights.
            Celebrate achievements while identifying growth opportunities.
            """
        }
    }
    
    private func buildConceptExplanationPrompt(
        concept: String,
        context: LearningContext?,
        difficulty: String
    ) -> String {
        var prompt = "Explain the concept of \(concept) at a \(difficulty) level."
        
        if let context = context {
            if let topic = context.topic {
                prompt += " This is in the context of \(topic)."
            }
            prompt += " The student is learning \(context.subject) at \(context.userLevel) level."
        }
        
        prompt += " Provide clear examples and practical applications. Include related concepts they should know."
        
        return prompt
    }
    
    private func buildQuizGenerationPrompt(
        topic: String,
        count: Int,
        difficulty: String,
        questionTypes: [QuestionType]
    ) -> String {
        let typeNames = questionTypes.map { $0.rawValue }.joined(separator: ", ")
        
        return """
        Generate \(count) \(difficulty) level quiz questions about \(topic).
        Use these question types: \(typeNames).
        Format as JSON with: question, options (if applicable), correct_answer, explanation.
        Make questions test understanding, not just memorization.
        """
    }
    
    private func buildFeedbackPrompt(
        answer: String,
        correctAnswer: String,
        question: String,
        explanation: String?
    ) -> String {
        var prompt = """
        Question: \(question)
        Student Answer: \(answer)
        Correct Answer: \(correctAnswer)
        """
        
        if let explanation = explanation {
            prompt += "\nExplanation: \(explanation)"
        }
        
        prompt += """
        
        Provide constructive feedback on the student's answer. 
        If incorrect, explain why and guide them toward the right thinking.
        If correct, acknowledge their understanding and provide additional insights.
        Be encouraging and supportive.
        """
        
        return prompt
    }
    
    private func buildStudyPlanPrompt(
        goals: [String],
        timeAvailable: Int,
        currentLevel: String,
        interests: [String]
    ) -> String {
        return """
        Create a personalized study plan with these details:
        Goals: \(goals.joined(separator: ", "))
        Available time: \(timeAvailable) hours per week
        Current level: \(currentLevel)
        Interests: \(interests.joined(separator: ", "))
        
        Include:
        - Weekly schedule breakdown
        - Specific learning resources
        - Milestone checkpoints
        - Progress tracking methods
        - Motivation techniques
        
        Make it practical and achievable.
        """
    }
    
    private func buildProgressAnalysisPrompt(
        progressData: UserProgressData,
        goals: [String]
    ) -> String {
        return """
        Analyze this learning progress data:
        Time studied: \(progressData.totalTime) hours
        Courses completed: \(progressData.coursesCompleted)
        Quiz scores: \(progressData.averageQuizScore)%
        Streak: \(progressData.currentStreak) days
        Goals: \(goals.joined(separator: ", "))
        
        Provide insights on:
        - Progress toward goals
        - Learning patterns
        - Areas of strength
        - Areas for improvement
        - Actionable recommendations
        """
    }
    
    // MARK: - Response Parsing
    
    private func convertGemmaResponse(_ response: GemmaResponse) -> AIResponse {
        return AIResponse(
            content: response.response,
            confidence: response.confidence,
            examples: response.examples,
            suggestions: response.suggestions,
            relatedTopics: response.relatedTopics,
            encouragement: response.encouragement,
            nextSteps: response.nextSteps,
            strengths: nil,
            improvements: nil,
            recommendations: nil
        )
    }
    
    private func convertOpenAIResponse(_ response: OpenAIResponse) -> AIResponse {
        let content = response.choices.first?.message.content ?? ""
        
        return AIResponse(
            content: content,
            confidence: 0.8, // OpenAI doesn't provide confidence scores
            examples: nil,
            suggestions: nil,
            relatedTopics: nil,
            encouragement: nil,
            nextSteps: nil,
            strengths: nil,
            improvements: nil,
            recommendations: nil
        )
    }
    
    private func convertAnthropicResponse(_ response: AnthropicResponse) -> AIResponse {
        let content = response.content.first?.text ?? ""
        
        return AIResponse(
            content: content,
            confidence: 0.8, // Claude doesn't provide confidence scores
            examples: nil,
            suggestions: nil,
            relatedTopics: nil,
            encouragement: nil,
            nextSteps: nil,
            strengths: nil,
            improvements: nil,
            recommendations: nil
        )
    }
    
    private func parseQuizQuestions(from content: String) -> [QuizQuestion] {
        // Implementation would parse JSON or structured text
        // For now, return empty array
        return []
    }
    
    private func parseStudyPlan(from content: String) -> StudyPlan {
        // Implementation would parse the structured study plan
        // For now, return a basic plan
        return StudyPlan(
            id: UUID().uuidString,
            userId: "",
            goals: [],
            timeline: StudyTimeline(
                startDate: Date(),
                endDate: Date().addingTimeInterval(30 * 24 * 3600),
                milestones: []
            ),
            recommendations: [],
            progress: StudyPlanProgress(
                completedMilestones: [],
                currentMilestone: nil,
                overallProgress: 0.0,
                weeklyHours: 0,
                streakDays: 0
            ),
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func calculateReadTime(_ text: String) -> Int {
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines).count
        return max(1, wordCount / 200) // Assuming 200 words per minute
    }
    
    private func extractOverallScore(from content: String) -> Double {
        // Implementation would extract score from content
        return 0.75
    }
}

// MARK: - Supporting Models

struct AIContext {
    let type: AIContextType
    let learningContext: LearningContext?
    let userPreferences: UserPreferences
}

enum AIContextType {
    case conceptExplanation
    case quizGeneration
    case feedback
    case studyPlanning
    case progressAnalysis
}

// UserPreferences is now defined in AppModels.swift

struct ConceptExplanation {
    let concept: String
    let explanation: String
    let examples: [String]
    let relatedConcepts: [String]
    let difficulty: String
    let estimatedReadTime: Int
}

struct FeedbackResponse {
    let isCorrect: Bool
    let feedback: String
    let suggestions: [String]
    let encouragement: String
    let nextSteps: [String]
}

struct ProgressAnalysis {
    let overallScore: Double
    let strengths: [String]
    let improvements: [String]
    let recommendations: [String]
    let insights: String
}

struct UserProgressData {
    let totalTime: TimeInterval
    let coursesCompleted: Int
    let averageQuizScore: Double
    let currentStreak: Int
}

struct AIResponse {
    let content: String
    let confidence: Double
    let examples: [String]?
    let suggestions: [String]?
    let relatedTopics: [String]?
    let encouragement: String?
    let nextSteps: [String]?
    let strengths: [String]?
    let improvements: [String]?
    let recommendations: [String]?
}

struct ChatRequest: Codable {
    let messages: [ChatMessage]
    let temperature: Double
    let maxTokens: Int
    let topP: Double
}

struct ChatMessage: Codable {
    let role: MessageRole
    let content: String
    
    enum MessageRole: String, Codable {
        case system = "system"
        case user = "user"
        case assistant = "assistant"
    }
}

// MARK: - API Response Models

struct GemmaResponse: Codable {
    let response: String
    let confidence: Double
    let examples: [String]?
    let suggestions: [String]?
    let relatedTopics: [String]?
    let encouragement: String?
    let nextSteps: [String]?
}

struct OpenAIRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
    let max_tokens: Int
}

struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: ChatMessage
    }
}

struct AnthropicRequest: Codable {
    let model: String
    let messages: [AnthropicMessage]
    let max_tokens: Int
}

struct AnthropicMessage: Codable {
    let role: String
    let content: String
}

struct AnthropicResponse: Codable {
    let content: [ContentBlock]
    
    struct ContentBlock: Codable {
        let text: String
    }
}
