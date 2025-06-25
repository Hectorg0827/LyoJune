import SwiftUI
import Combine

// MARK: - Error Handler
@MainActor
class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    @Published var currentError: AppError?
    @Published var showingError = false
    @Published var errorHistory: [AppError] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupErrorMonitoring()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    func handle(_ error: Error, context: String = "") {
        let appError = AppError(
            originalError: error,
            context: context,
            timestamp: Date(),
            userMessage: getUserFriendlyMessage(for: error)
        )
        
        currentError = appError
        showingError = true
        errorHistory.append(appError)
        
        // Log error for debugging
        logError(appError)
        
        // Track error analytics
        Task {
            await AnalyticsAPIService.shared.trackEvent(
                "error_occurred",
                parameters: [
                    "error_type": String(describing: type(of: error)),
                    "context": context,
                    "user_message": appError.userMessage
                ]
            )
        }
        
        // Auto-dismiss after 5 seconds for non-critical errors
        if appError.severity != .critical {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if self.currentError?.id == appError.id {
                    self.dismissError()
                }
            }
        }
    }
    
    func dismissError() {
        currentError = nil
        showingError = false
    }
    
    func retryAction() {
        // Implement retry logic based on error type
        dismissError()
    }
    
    private func setupErrorMonitoring() {
        // Monitor network errors
        NetworkManager.shared.$isOnline
            .sink { [weak self] isOnline in
                if !isOnline {
                    let error = NetworkError.networkError(NSError(
                        domain: "NetworkError",
                        code: -1009,
                        userInfo: [NSLocalizedDescriptionKey: "No internet connection"]
                    ))
                    self?.handle(error, context: "Network connectivity")
                }
            }
            .store(in: &cancellables)
    }
    
    private func getUserFriendlyMessage(for error: Error) -> String {
        switch error {
        case let networkError as NetworkError:
            return getNetworkErrorMessage(networkError)
        case let aiError as AIError:
            return getAIErrorMessage(aiError)
        default:
            return "Something went wrong. Please try again."
        }
    }
    
    private func getNetworkErrorMessage(_ error: NetworkError) -> String {
        switch error {
        case .networkError:
            return "Please check your internet connection and try again."
        case .serverError:
            return "Our servers are experiencing issues. Please try again in a moment."
        case .unauthorized:
            return "Please sign in again to continue."
        case .timeout:
            return "The request timed out. Please try again."
        default:
            return "A network error occurred. Please try again."
        }
    }
    
    private func getAIErrorMessage(_ error: AIError) -> String {
        switch error {
        case .speechPermissionDenied:
            return "Please enable microphone access in Settings to use voice features."
        case .speechRecognitionUnavailable:
            return "Speech recognition is not available on this device."
        default:
            return "AI assistant is temporarily unavailable. Please try again."
        }
    }
    
    private func logError(_ error: AppError) {
        print("🚨 Error: \(error.originalError.localizedDescription)")
        print("📍 Context: \(error.context)")
        print("⏰ Time: \(error.timestamp)")
        
        // In production, send to crash reporting service
        if Constants.FeatureFlags.enableCrashlytics {
            // Crashlytics.crashlytics().record(error: error.originalError)
        }
    }
}

// MARK: - User Feedback System
@MainActor
class UserFeedbackManager: ObservableObject {
    static let shared = UserFeedbackManager()
    
    @Published var showingFeedback = false
    @Published var feedbackType: FeedbackType = .success
    @Published var feedbackMessage = ""
    @Published var feedbackQueue: [FeedbackItem] = []
    
    private var feedbackTimer: Timer?
    
    private init() {}
    
    func showSuccess(_ message: String) {
        showFeedback(.success, message: message)
    }
    
    func showWarning(_ message: String) {
        showFeedback(.warning, message: message)
    }
    
    func showError(_ message: String) {
        showFeedback(.error, message: message)
    }
    
    func showInfo(_ message: String) {
        showFeedback(.info, message: message)
    }
    
    func showAchievement(_ title: String, description: String) {
        let message = "\(title): \(description)"
        showFeedback(.achievement, message: message)
    }
    
    private func showFeedback(_ type: FeedbackType, message: String) {
        let feedback = FeedbackItem(type: type, message: message)
        
        if showingFeedback {
            // Queue the feedback if one is already showing
            feedbackQueue.append(feedback)
        } else {
            displayFeedback(feedback)
        }
    }
    
    private func displayFeedback(_ feedback: FeedbackItem) {
        feedbackType = feedback.type
        feedbackMessage = feedback.message
        showingFeedback = true
        
        // Auto-dismiss based on feedback type
        let duration: TimeInterval = feedback.type == .achievement ? 4.0 : 3.0
        
        feedbackTimer?.invalidate()
        feedbackTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            Task { @MainActor in
                self.dismissFeedback()
            }
        }
        
        // Add haptic feedback
        generateHapticFeedback(for: feedback.type)
    }
    
    func dismissFeedback() {
        showingFeedback = false
        feedbackTimer?.invalidate()
        
        // Show next feedback in queue if any
        if !feedbackQueue.isEmpty {
            let nextFeedback = feedbackQueue.removeFirst()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.displayFeedback(nextFeedback)
            }
        }
    }
    
    private func generateHapticFeedback(for type: FeedbackType) {
        switch type {
        case .success, .achievement:
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        case .warning:
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        case .error:
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
        case .info:
            break // No haptic for info
        }
    }
}

// MARK: - Feedback Models
struct FeedbackItem: Identifiable {
    let id = UUID()
    let type: FeedbackType
    let message: String
    let timestamp = Date()
}

enum FeedbackType {
    case success, warning, error, info, achievement
    
    var color: Color {
        switch self {
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        case .info: return .blue
        case .achievement: return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        case .achievement: return "star.fill"
        }
    }
    
    var title: String {
        switch self {
        case .success: return "Success"
        case .warning: return "Warning"
        case .error: return "Error"
        case .info: return "Info"
        case .achievement: return "Achievement"
        }
    }
}

// MARK: - Error Display View
struct ErrorDisplayView: View {
    @ObservedObject var errorHandler: ErrorHandler
    
    var body: some View {
        Group {
            if let error = errorHandler.currentError, errorHandler.showingError {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: error.severity.icon)
                            .foregroundColor(error.severity.color)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Oops!")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(error.userMessage)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                        
                        Button("Dismiss") {
                            errorHandler.dismissError()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    if error.severity == .critical {
                        HStack {
                            Button("Retry") {
                                errorHandler.retryAction()
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("Report") {
                                // Open feedback form
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding()
                .background(Material.regular)
                .cornerRadius(12)
                .shadow(radius: 4)
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: errorHandler.showingError)
    }
}

// MARK: - Feedback Display View
struct FeedbackDisplayView: View {
    @ObservedObject var feedbackManager: UserFeedbackManager
    
    var body: some View {
        Group {
            if feedbackManager.showingFeedback {
                HStack(spacing: 12) {
                    Image(systemName: feedbackManager.feedbackType.icon)
                        .foregroundColor(feedbackManager.feedbackType.color)
                        .font(.title3)
                    
                    Text(feedbackManager.feedbackMessage)
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Button(action: feedbackManager.dismissFeedback) {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(feedbackManager.feedbackType.color.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(feedbackManager.feedbackType.color.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: feedbackManager.showingFeedback)
    }
}

// MARK: - View Extensions
extension View {
    func errorHandling() -> some View {
        self.overlay(alignment: .top) {
            ErrorDisplayView(errorHandler: ErrorHandler.shared)
        }
    }
    
    func userFeedback() -> some View {
        self.overlay(alignment: .top) {
            FeedbackDisplayView(feedbackManager: UserFeedbackManager.shared)
                .padding(.top, 8)
        }
    }
    
    func handleErrors() -> some View {
        self
            .errorHandling()
            .userFeedback()
    }
}
