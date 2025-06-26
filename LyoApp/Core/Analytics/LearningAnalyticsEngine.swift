import Foundation
import CoreML
import Combine

// MARK: - Learning Analytics Engine
@MainActor
public class LearningAnalyticsEngine: ObservableObject {
    // MARK: - Properties
    @Published public var learningInsights: [LearningInsight] = []
    @Published public var performanceMetrics: PerformanceMetrics?
    @Published public var learningPattern: LearningPattern?
    @Published public var recommendations: [LearningRecommendation] = []
    @Published public var isAnalyzing = false
    @Published public var error: AnalyticsError?
    
    private let coreDataStack: CoreDataStack
    private let userId: String
    private var cancellables = Set<AnyCancellable>()
    
    // ML Models (would be loaded from actual ML model files)
    private var performancePredictionModel: MLModel?
    private var recommendationModel: MLModel?
    private var engagementAnalysisModel: MLModel?
    
    // Analytics data
    private var sessionData: [StudySession] = []
    private var interactionData: [UserInteraction] = []
    private var progressData: [ProgressPoint] = []
    
    // MARK: - Initialization
    public init(coreDataStack: CoreDataStack, userId: String) {
        self.coreDataStack = coreDataStack
        self.userId = userId
        setupMLModels()
        startPeriodicAnalysis()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Public Methods
    
    /// Track a study session
    public func trackStudySession(_ session: StudySession) async {
        sessionData.append(session)
        
        // Store in Core Data
        await saveStudySession(session)
        
        // Trigger analysis if we have enough data
        if sessionData.count % 5 == 0 {
            await analyzeData()
        }
    }
    
    /// Track user interaction
    public func trackInteraction(_ interaction: UserInteraction) async {
        interactionData.append(interaction)
        
        // Store in Core Data
        await saveInteraction(interaction)
        
        // Real-time engagement analysis
        await analyzeEngagement()
    }
    
    /// Track progress point
    public func trackProgress(_ progress: ProgressPoint) async {
        progressData.append(progress)
        
        // Store in Core Data
        await saveProgress(progress)
        
        // Update learning pattern
        await updateLearningPattern()
    }
    
    /// Generate comprehensive learning report
    public func generateLearningReport(period: AnalyticsPeriod) async -> LearningReport {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        let startDate = period.startDate
        let endDate = period.endDate
        
        // Fetch data for the period
        let sessions = await fetchStudySessions(from: startDate, to: endDate)
        let interactions = await fetchInteractions(from: startDate, to: endDate)
        let progress = await fetchProgress(from: startDate, to: endDate)
        
        // Calculate metrics
        let metrics = calculatePerformanceMetrics(sessions: sessions, interactions: interactions, progress: progress)
        let insights = await generateInsights(from: sessions, interactions: interactions, progress: progress)
        let recommendations = await generateRecommendations(based: metrics, insights: insights)
        
        return LearningReport(
            period: period,
            userId: userId,
            metrics: metrics,
            insights: insights,
            recommendations: recommendations,
            generatedAt: Date()
        )
    }
    
    /// Get learning predictions
    public func getLearningPredictions() async -> [LearningPrediction] {
        guard let model = performancePredictionModel else { return [] }
        
        // Prepare input data
        let inputData = prepareMLInput()
        
        do {
            // Run prediction (this would use actual Core ML prediction)
            let predictions = try await runPerformancePrediction(model: model, input: inputData)
            return predictions
        } catch {
            self.error = AnalyticsError.predictionFailed(error.localizedDescription)
            return []
        }
    }
    
    /// Get personalized recommendations
    public func getPersonalizedRecommendations() async -> [LearningRecommendation] {
        guard let model = recommendationModel else { return [] }
        
        let inputData = prepareRecommendationInput()
        
        do {
            let recommendations = try await runRecommendationModel(model: model, input: inputData)
            self.recommendations = recommendations
            return recommendations
        } catch {
            self.error = AnalyticsError.recommendationFailed(error.localizedDescription)
            return []
        }
    }
    
    /// Analyze learning effectiveness
    public func analyzeLearningEffectiveness(for courseId: String) async -> EffectivenessAnalysis {
        let courseSessions = sessionData.filter { $0.courseId == courseId }
        let courseProgress = progressData.filter { $0.courseId == courseId }
        
        let analysis = EffectivenessAnalysis(
            courseId: courseId,
            averageSessionDuration: calculateAverageSessionDuration(courseSessions),
            completionRate: calculateCompletionRate(courseProgress),
            retentionRate: calculateRetentionRate(courseSessions),
            engagementScore: calculateEngagementScore(courseSessions),
            difficultyRating: calculateDifficultyRating(courseSessions),
            recommendations: generateCourseRecommendations(analysis: courseSessions)
        )
        
        return analysis
    }
    
    /// Get learning streak analysis
    public func getStreakAnalysis() -> StreakAnalysis {
        let sortedSessions = sessionData.sorted { $0.startTime < $1.startTime }
        
        var currentStreak = 0
        var longestStreak = 0
        var streaks: [Int] = []
        var lastDate: Date?
        
        for session in sortedSessions {
            let sessionDate = Calendar.current.startOfDay(for: session.startTime)
            
            if let last = lastDate {
                let daysDifference = Calendar.current.dateComponents([.day], from: last, to: sessionDate).day ?? 0
                
                if daysDifference == 1 {
                    currentStreak += 1
                } else if daysDifference > 1 {
                    if currentStreak > 0 {
                        streaks.append(currentStreak)
                        longestStreak = max(longestStreak, currentStreak)
                    }
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }
            
            lastDate = sessionDate
        }
        
        if currentStreak > 0 {
            streaks.append(currentStreak)
            longestStreak = max(longestStreak, currentStreak)
        }
        
        return StreakAnalysis(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            averageStreak: streaks.isEmpty ? 0 : Double(streaks.reduce(0, +)) / Double(streaks.count),
            totalStreaks: streaks.count
        )
    }
    
    /// Export analytics data
    public func exportAnalyticsData(format: ExportFormat) async throws -> Data {
        let report = await generateLearningReport(period: .allTime)
        
        switch format {
        case .json:
            return try JSONEncoder().encode(report)
        case .csv:
            return try generateCSVData(from: report)
        case .pdf:
            return try await generatePDFData(from: report)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupMLModels() {
        // In a real implementation, these would load actual Core ML models
        // For now, we'll create placeholder models
        
        do {
            // Load performance prediction model
            // performancePredictionModel = try MLModel(contentsOf: performanceModelURL)
            
            // Load recommendation model
            // recommendationModel = try MLModel(contentsOf: recommendationModelURL)
            
            // Load engagement analysis model
            // engagementAnalysisModel = try MLModel(contentsOf: engagementModelURL)
            
            print("ML models loaded successfully")
        } catch {
            print("Failed to load ML models: \(error)")
        }
    }
    
    private func startPeriodicAnalysis() {
        // Run analysis every hour
        Timer.publish(every: 3600, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.analyzeData()
                }
            }
            .store(in: &cancellables)
    }
    
    private func analyzeData() async {
        guard !sessionData.isEmpty else { return }
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        // Calculate performance metrics
        performanceMetrics = calculateCurrentPerformanceMetrics()
        
        // Update learning pattern
        learningPattern = calculateLearningPattern()
        
        // Generate insights
        learningInsights = await generateCurrentInsights()
        
        // Generate recommendations
        recommendations = await getPersonalizedRecommendations()
    }
    
    private func analyzeEngagement() async {
        guard let model = engagementAnalysisModel else { return }
        
        // Analyze current engagement level
        let recentInteractions = Array(interactionData.suffix(10))
        let engagementInput = prepareEngagementInput(from: recentInteractions)
        
        // Run engagement analysis
        // In a real implementation, this would use the ML model
        let engagementScore = calculateEngagementScore(from: recentInteractions)
        
        // Generate engagement insights
        if engagementScore < 0.3 {
            let insight = LearningInsight(
                type: .engagement,
                title: "Low Engagement Detected",
                description: "Your engagement has decreased. Consider taking a break or trying a different learning approach.",
                severity: .warning,
                actionItems: ["Take a 10-minute break", "Switch to interactive content", "Set smaller goals"],
                timestamp: Date()
            )
            learningInsights.append(insight)
        }
    }
    
    private func updateLearningPattern() async {
        let pattern = LearningPattern(
            preferredTimeOfDay: calculatePreferredStudyTime(),
            averageSessionDuration: calculateAverageSessionDuration(sessionData),
            learningVelocity: calculateLearningVelocity(),
            retentionRate: calculateOverallRetentionRate(),
            strengths: identifyLearningStrengths(),
            weaknesses: identifyLearningWeaknesses(),
            preferredContentTypes: identifyPreferredContentTypes()
        )
        
        learningPattern = pattern
    }
    
    private func calculatePerformanceMetrics(sessions: [StudySession], interactions: [UserInteraction], progress: [ProgressPoint]) -> PerformanceMetrics {
        return PerformanceMetrics(
            totalStudyTime: sessions.reduce(0) { $0 + $1.duration },
            averageSessionDuration: sessions.isEmpty ? 0 : sessions.reduce(0) { $0 + $1.duration } / Double(sessions.count),
            completionRate: calculateCompletionRate(progress),
            accuracyRate: calculateAccuracyRate(sessions),
            engagementScore: calculateEngagementScore(sessions),
            progressVelocity: calculateProgressVelocity(progress),
            retentionScore: calculateRetentionScore(sessions),
            focusScore: calculateFocusScore(interactions)
        )
    }
    
    private func generateInsights(from sessions: [StudySession], interactions: [UserInteraction], progress: [ProgressPoint]) async -> [LearningInsight] {
        var insights: [LearningInsight] = []
        
        // Analyze study patterns
        if let peakTime = findPeakStudyTime(sessions) {
            insights.append(LearningInsight(
                type: .pattern,
                title: "Peak Performance Time",
                description: "You perform best around \(formatTime(peakTime)).",
                severity: .info,
                actionItems: ["Schedule important topics during this time"],
                timestamp: Date()
            ))
        }
        
        // Analyze completion patterns
        let completionRate = calculateCompletionRate(progress)
        if completionRate < 0.5 {
            insights.append(LearningInsight(
                type: .performance,
                title: "Low Completion Rate",
                description: "Your completion rate is \(Int(completionRate * 100))%. Consider breaking content into smaller chunks.",
                severity: .warning,
                actionItems: ["Set smaller daily goals", "Use the Pomodoro technique", "Remove distractions"],
                timestamp: Date()
            ))
        }
        
        // Analyze learning velocity
        let velocity = calculateProgressVelocity(progress)
        if velocity > 1.5 {
            insights.append(LearningInsight(
                type: .achievement,
                title: "Excellent Progress",
                description: "You're learning faster than average! Keep up the great work.",
                severity: .success,
                actionItems: ["Consider tackling more challenging topics"],
                timestamp: Date()
            ))
        }
        
        return insights
    }
    
    private func generateRecommendations(based metrics: PerformanceMetrics, insights: [LearningInsight]) async -> [LearningRecommendation] {
        var recommendations: [LearningRecommendation] = []
        
        // Time-based recommendations
        if metrics.averageSessionDuration < 900 { // Less than 15 minutes
            recommendations.append(LearningRecommendation(
                type: .timeManagement,
                title: "Extend Study Sessions",
                description: "Consider longer study sessions for better retention.",
                priority: .medium,
                estimatedImpact: 0.7,
                actionPlan: ["Start with 20-minute sessions", "Gradually increase to 45 minutes", "Use timers to track progress"]
            ))
        }
        
        // Performance-based recommendations
        if metrics.accuracyRate < 0.7 {
            recommendations.append(LearningRecommendation(
                type: .content,
                title: "Review Fundamentals",
                description: "Your accuracy suggests reviewing basic concepts would help.",
                priority: .high,
                estimatedImpact: 0.8,
                actionPlan: ["Revisit completed lessons", "Practice with easier exercises", "Seek additional resources"]
            ))
        }
        
        // Engagement recommendations
        if metrics.engagementScore < 0.5 {
            recommendations.append(LearningRecommendation(
                type: .engagement,
                title: "Vary Learning Methods",
                description: "Try different content types to boost engagement.",
                priority: .medium,
                estimatedImpact: 0.6,
                actionPlan: ["Mix videos with reading", "Try interactive exercises", "Join study groups"]
            ))
        }
        
        return recommendations
    }
    
    // MARK: - Calculation Methods
    
    private func calculateCurrentPerformanceMetrics() -> PerformanceMetrics {
        return calculatePerformanceMetrics(sessions: sessionData, interactions: interactionData, progress: progressData)
    }
    
    private func calculateLearningPattern() -> LearningPattern {
        return LearningPattern(
            preferredTimeOfDay: calculatePreferredStudyTime(),
            averageSessionDuration: calculateAverageSessionDuration(sessionData),
            learningVelocity: calculateLearningVelocity(),
            retentionRate: calculateOverallRetentionRate(),
            strengths: identifyLearningStrengths(),
            weaknesses: identifyLearningWeaknesses(),
            preferredContentTypes: identifyPreferredContentTypes()
        )
    }
    
    private func generateCurrentInsights() async -> [LearningInsight] {
        return await generateInsights(from: sessionData, interactions: interactionData, progress: progressData)
    }
    
    private func calculateAverageSessionDuration(_ sessions: [StudySession]) -> TimeInterval {
        guard !sessions.isEmpty else { return 0 }
        return sessions.reduce(0) { $0 + $1.duration } / Double(sessions.count)
    }
    
    private func calculateCompletionRate(_ progress: [ProgressPoint]) -> Double {
        guard !progress.isEmpty else { return 0 }
        let completed = progress.filter { $0.isCompleted }.count
        return Double(completed) / Double(progress.count)
    }
    
    private func calculateRetentionRate(_ sessions: [StudySession]) -> Double {
        // Calculate based on quiz scores and review sessions
        let quizSessions = sessions.filter { $0.type == .quiz }
        guard !quizSessions.isEmpty else { return 0.5 }
        
        let totalScore = quizSessions.reduce(0) { $0 + $1.score }
        return Double(totalScore) / Double(quizSessions.count)
    }
    
    private func calculateEngagementScore(_ sessions: [StudySession]) -> Double {
        guard !sessions.isEmpty else { return 0 }
        
        // Calculate based on session completion, interaction frequency, and focus time
        let completedSessions = sessions.filter { $0.completed }.count
        let completionRate = Double(completedSessions) / Double(sessions.count)
        
        let averageInteractions = sessions.reduce(0) { $0 + $1.interactionCount } / sessions.count
        let interactionScore = min(Double(averageInteractions) / 10.0, 1.0)
        
        return (completionRate + interactionScore) / 2.0
    }
    
    private func calculateEngagementScore(from interactions: [UserInteraction]) -> Double {
        guard !interactions.isEmpty else { return 0 }
        
        let recentInteractions = interactions.suffix(20)
        let timeSpan = recentInteractions.last!.timestamp.timeIntervalSince(recentInteractions.first!.timestamp)
        
        if timeSpan == 0 { return 1.0 }
        
        let interactionRate = Double(recentInteractions.count) / (timeSpan / 60) // interactions per minute
        return min(interactionRate / 2.0, 1.0) // Normalize to 0-1 scale
    }
    
    private func calculateAccuracyRate(_ sessions: [StudySession]) -> Double {
        let quizSessions = sessions.filter { $0.type == .quiz }
        guard !quizSessions.isEmpty else { return 0.5 }
        
        let totalScore = quizSessions.reduce(0) { $0 + $1.score }
        let maxScore = quizSessions.count * 100
        return Double(totalScore) / Double(maxScore)
    }
    
    private func calculateProgressVelocity(_ progress: [ProgressPoint]) -> Double {
        guard progress.count >= 2 else { return 0 }
        
        let sortedProgress = progress.sorted { $0.timestamp < $1.timestamp }
        let timeSpan = sortedProgress.last!.timestamp.timeIntervalSince(sortedProgress.first!.timestamp)
        
        if timeSpan == 0 { return 0 }
        
        let progressMade = Double(progress.filter { $0.isCompleted }.count)
        let daysSpan = timeSpan / (24 * 60 * 60)
        
        return progressMade / daysSpan
    }
    
    private func calculateRetentionScore(_ sessions: [StudySession]) -> Double {
        // Implement retention calculation based on spaced repetition performance
        return 0.75 // Placeholder
    }
    
    private func calculateFocusScore(_ interactions: [UserInteraction]) -> Double {
        // Calculate focus based on interaction patterns
        return 0.8 // Placeholder
    }
    
    private func calculatePreferredStudyTime() -> Int {
        let hourCounts = Array(repeating: 0, count: 24)
        var mutableHourCounts = hourCounts
        
        for session in sessionData {
            let hour = Calendar.current.component(.hour, from: session.startTime)
            mutableHourCounts[hour] += 1
        }
        
        return mutableHourCounts.enumerated().max(by: { $0.element < $1.element })?.offset ?? 9
    }
    
    private func calculateLearningVelocity() -> Double {
        return calculateProgressVelocity(progressData)
    }
    
    private func calculateOverallRetentionRate() -> Double {
        return calculateRetentionRate(sessionData)
    }
    
    private func identifyLearningStrengths() -> [String] {
        // Analyze performance across different topics/skills
        return ["Problem Solving", "Visual Learning"] // Placeholder
    }
    
    private func identifyLearningWeaknesses() -> [String] {
        // Identify areas needing improvement
        return ["Time Management", "Retention"] // Placeholder
    }
    
    private func identifyPreferredContentTypes() -> [String] {
        // Analyze engagement with different content types
        return ["Videos", "Interactive Exercises"] // Placeholder
    }
    
    private func findPeakStudyTime(_ sessions: [StudySession]) -> Date? {
        guard !sessions.isEmpty else { return nil }
        
        let bestSession = sessions.max { session1, session2 in
            let score1 = session1.score + (session1.completed ? 20 : 0)
            let score2 = session2.score + (session2.completed ? 20 : 0)
            return score1 < score2
        }
        
        return bestSession?.startTime
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Data Management
    
    private func saveStudySession(_ session: StudySession) async {
        // Save to Core Data
        // Implementation would use CoreDataStack
    }
    
    private func saveInteraction(_ interaction: UserInteraction) async {
        // Save to Core Data
        // Implementation would use CoreDataStack
    }
    
    private func saveProgress(_ progress: ProgressPoint) async {
        // Save to Core Data
        // Implementation would use CoreDataStack
    }
    
    private func fetchStudySessions(from startDate: Date, to endDate: Date) async -> [StudySession] {
        return sessionData.filter { $0.startTime >= startDate && $0.startTime <= endDate }
    }
    
    private func fetchInteractions(from startDate: Date, to endDate: Date) async -> [UserInteraction] {
        return interactionData.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
    }
    
    private func fetchProgress(from startDate: Date, to endDate: Date) async -> [ProgressPoint] {
        return progressData.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
    }
    
    // MARK: - ML Methods (Placeholders)
    
    private func prepareMLInput() -> MLInputData {
        // Prepare input data for ML models
        return MLInputData(
            sessionCount: sessionData.count,
            averageDuration: calculateAverageSessionDuration(sessionData),
            completionRate: calculateCompletionRate(progressData),
            engagementScore: calculateEngagementScore(sessionData)
        )
    }
    
    private func prepareRecommendationInput() -> RecommendationInputData {
        // Prepare input for recommendation model
        return RecommendationInputData(
            userId: userId,
            performanceMetrics: performanceMetrics ?? PerformanceMetrics.default,
            learningPattern: learningPattern ?? LearningPattern.default,
            recentSessions: Array(sessionData.suffix(10))
        )
    }
    
    private func prepareEngagementInput(from interactions: [UserInteraction]) -> EngagementInputData {
        return EngagementInputData(
            interactionCount: interactions.count,
            timeSpan: interactions.last?.timestamp.timeIntervalSince(interactions.first?.timestamp ?? Date()) ?? 0,
            interactionTypes: interactions.map { $0.type }
        )
    }
    
    private func runPerformancePrediction(model: MLModel, input: MLInputData) async throws -> [LearningPrediction] {
        // Run actual ML prediction
        // This is a placeholder implementation
        return [
            LearningPrediction(
                type: .performance,
                prediction: "You're likely to improve by 15% in the next week",
                confidence: 0.8,
                timeframe: .week
            )
        ]
    }
    
    private func runRecommendationModel(model: MLModel, input: RecommendationInputData) async throws -> [LearningRecommendation] {
        // Run recommendation model
        // This is a placeholder implementation
        return [
            LearningRecommendation(
                type: .content,
                title: "Try Advanced Problem Solving",
                description: "Based on your progress, you're ready for more challenging content.",
                priority: .high,
                estimatedImpact: 0.9,
                actionPlan: ["Complete current module", "Start advanced exercises", "Join study group"]
            )
        ]
    }
    
    // MARK: - Export Methods
    
    private func generateCSVData(from report: LearningReport) throws -> Data {
        // Generate CSV format data
        let csvContent = "Date,Study Time,Completion Rate,Accuracy\n" // Placeholder
        return csvContent.data(using: .utf8) ?? Data()
    }
    
    private func generatePDFData(from report: LearningReport) async throws -> Data {
        // Generate PDF format data
        return Data() // Placeholder
    }
}

// MARK: - Supporting Types

public struct StudySession: Codable {
    public let id: String
    public let userId: String
    public let courseId: String
    public let lessonId: String?
    public let startTime: Date
    public let endTime: Date
    public let duration: TimeInterval
    public let type: SessionType
    public let score: Int
    public let completed: Bool
    public let interactionCount: Int
    
    public enum SessionType: String, Codable {
        case lesson, quiz, review, practice
    }
}

public struct UserInteraction: Codable {
    public let id: String
    public let userId: String
    public let type: InteractionType
    public let timestamp: Date
    public let metadata: [String: String]
    
    public enum InteractionType: String, Codable {
        case tap, scroll, pause, seek, answer, bookmark, share
    }
}

public struct ProgressPoint: Codable {
    public let id: String
    public let userId: String
    public let courseId: String
    public let lessonId: String?
    public let timestamp: Date
    public let progressValue: Double
    public let isCompleted: Bool
}

public struct LearningInsight: Codable, Identifiable {
    public let id = UUID()
    public let type: InsightType
    public let title: String
    public let description: String
    public let severity: Severity
    public let actionItems: [String]
    public let timestamp: Date
    
    public enum InsightType: String, Codable {
        case pattern, performance, engagement, achievement, warning
    }
    
    public enum Severity: String, Codable {
        case info, success, warning, error
    }
}

public struct PerformanceMetrics: Codable {
    public let totalStudyTime: TimeInterval
    public let averageSessionDuration: TimeInterval
    public let completionRate: Double
    public let accuracyRate: Double
    public let engagementScore: Double
    public let progressVelocity: Double
    public let retentionScore: Double
    public let focusScore: Double
    
    public static let `default` = PerformanceMetrics(
        totalStudyTime: 0,
        averageSessionDuration: 0,
        completionRate: 0,
        accuracyRate: 0,
        engagementScore: 0,
        progressVelocity: 0,
        retentionScore: 0,
        focusScore: 0
    )
}

public struct LearningPattern: Codable {
    public let preferredTimeOfDay: Int
    public let averageSessionDuration: TimeInterval
    public let learningVelocity: Double
    public let retentionRate: Double
    public let strengths: [String]
    public let weaknesses: [String]
    public let preferredContentTypes: [String]
    
    public static let `default` = LearningPattern(
        preferredTimeOfDay: 9,
        averageSessionDuration: 1800,
        learningVelocity: 1.0,
        retentionRate: 0.7,
        strengths: [],
        weaknesses: [],
        preferredContentTypes: []
    )
}

public struct LearningRecommendation: Codable, Identifiable {
    public let id = UUID()
    public let type: RecommendationType
    public let title: String
    public let description: String
    public let priority: Priority
    public let estimatedImpact: Double
    public let actionPlan: [String]
    
    public enum RecommendationType: String, Codable {
        case content, timeManagement, engagement, difficulty, social
    }
    
    public enum Priority: String, Codable {
        case low, medium, high, urgent
    }
}

public struct LearningPrediction: Codable {
    public let type: PredictionType
    public let prediction: String
    public let confidence: Double
    public let timeframe: Timeframe
    
    public enum PredictionType: String, Codable {
        case performance, completion, retention, engagement
    }
    
    public enum Timeframe: String, Codable {
        case day, week, month, quarter
    }
}

public struct LearningReport: Codable {
    public let period: AnalyticsPeriod
    public let userId: String
    public let metrics: PerformanceMetrics
    public let insights: [LearningInsight]
    public let recommendations: [LearningRecommendation]
    public let generatedAt: Date
}

public enum AnalyticsPeriod: Codable {
    case day(Date)
    case week(Date)
    case month(Date)
    case quarter(Date)
    case year(Date)
    case custom(Date, Date)
    case allTime
    
    public var startDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .day(let date):
            return calendar.startOfDay(for: date)
        case .week(let date):
            return calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        case .month(let date):
            return calendar.dateInterval(of: .month, for: date)?.start ?? date
        case .quarter(let date):
            return calendar.dateInterval(of: .quarter, for: date)?.start ?? date
        case .year(let date):
            return calendar.dateInterval(of: .year, for: date)?.start ?? date
        case .custom(let start, _):
            return start
        case .allTime:
            return Date.distantPast
        }
    }
    
    public var endDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .day(let date):
            return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) ?? date
        case .week(let date):
            return calendar.dateInterval(of: .weekOfYear, for: date)?.end ?? date
        case .month(let date):
            return calendar.dateInterval(of: .month, for: date)?.end ?? date
        case .quarter(let date):
            return calendar.dateInterval(of: .quarter, for: date)?.end ?? date
        case .year(let date):
            return calendar.dateInterval(of: .year, for: date)?.end ?? date
        case .custom(_, let end):
            return end
        case .allTime:
            return now
        }
    }
}

public struct EffectivenessAnalysis: Codable {
    public let courseId: String
    public let averageSessionDuration: TimeInterval
    public let completionRate: Double
    public let retentionRate: Double
    public let engagementScore: Double
    public let difficultyRating: Double
    public let recommendations: [String]
}

public struct StreakAnalysis: Codable {
    public let currentStreak: Int
    public let longestStreak: Int
    public let averageStreak: Double
    public let totalStreaks: Int
}

public enum ExportFormat: String, CaseIterable {
    case json = "JSON"
    case csv = "CSV"
    case pdf = "PDF"
}

public enum AnalyticsError: LocalizedError {
    case predictionFailed(String)
    case recommendationFailed(String)
    case dataProcessingFailed(String)
    case exportFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .predictionFailed(let message):
            return "Prediction failed: \(message)"
        case .recommendationFailed(let message):
            return "Recommendation failed: \(message)"
        case .dataProcessingFailed(let message):
            return "Data processing failed: \(message)"
        case .exportFailed(let message):
            return "Export failed: \(message)"
        }
    }
}

// MARK: - ML Input Data Types

private struct MLInputData {
    let sessionCount: Int
    let averageDuration: TimeInterval
    let completionRate: Double
    let engagementScore: Double
}

private struct RecommendationInputData {
    let userId: String
    let performanceMetrics: PerformanceMetrics
    let learningPattern: LearningPattern
    let recentSessions: [StudySession]
}

private struct EngagementInputData {
    let interactionCount: Int
    let timeSpan: TimeInterval
    let interactionTypes: [UserInteraction.InteractionType]
}
