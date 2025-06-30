import SwiftUI
import Combine

// MARK: - Global Error Handler
@MainActor
class ErrorManager: ObservableObject {
    static let shared = ErrorManager()
    
    @Published var currentError: AppError?
    @Published var showError = false
    @Published var errorHistory: [AppError] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupNotifications()
    }
    
    func handle(_ error: Error, context: String? = nil) {
        let appError = AppError(
            id: UUID(),
            originalError: error,
            context: context,
            timestamp: Date()
        )
        
        errorHistory.append(appError)
        currentError = appError
        showError = true
        
        // Log error for analytics
        logError(appError)
        
        // Post notification for other components
        NotificationCenter.default.post(
            name: .errorOccurred,
            object: appError
        )
    }
    
    func dismissError() {
        currentError = nil
        showError = false
    }
    
    func clearHistory() {
        errorHistory.removeAll()
    }
    
    private func setupNotifications() {
        // Listen for network errors
        NotificationCenter.default.publisher(for: .networkError)
            .sink { [weak self] notification in
                if let error = notification.object as? Error {
                    self?.handle(error, context: "Network")
                }
            }
            .store(in: &cancellables)
    }
    
    private func logError(_ error: AppError) {
        // In a real app, this would send to analytics service
        print("Error logged: \(error.localizedDescription)")
        
        // Could send to Crashlytics, Sentry, etc.
        Task {
            await AnalyticsAPIService.shared.trackEvent("error_occurred", parameters: [
                "error_type": error.type.rawValue,
                "error_message": error.userMessage,
                "severity": error.severity.rawValue,
                "context": error.context ?? "unknown"
            ])
        }
    }
}

// MARK: - App Error Model
struct AppError: Error, Identifiable, Equatable {
    let id: UUID
    let originalError: Error
    let context: String?
    let timestamp: Date
    let userMessage: String
    
    init(id: UUID = UUID(), originalError: Error, context: String?, timestamp: Date, userMessage: String? = nil) {
        self.id = id
        self.originalError = originalError
        self.context = context
        self.timestamp = timestamp
        self.userMessage = userMessage ?? originalError.localizedDescription
    }
    
    var type: ErrorType {
        if originalError is NetworkError {
            return .network
        } else if originalError is AuthError {
            return .authentication
        } else if originalError is AIError {
            return .ai
        } else {
            return .unknown
        }
    }
    
    var severity: ErrorSeverity {
        switch type {
        case .authentication:
            return .high
        case .network:
            return .medium
        case .ai:
            return .low
        case .dataCorruption:
            return .critical
        case .unknown:
            return .medium
        }
    }
    
    var localizedDescription: String {
        let baseMessage = originalError.localizedDescription
        
        if let context = context {
            return "\(context): \(baseMessage)"
        }
        
        return baseMessage
    }
    
    var userFriendlyMessage: String {
        switch type {
        case .network:
            return "Unable to connect to the internet. Please check your connection and try again."
        case .authentication:
            return "Authentication failed. Please sign in again."
        case .ai:
            return "AI service is temporarily unavailable. Please try again later."
        case .dataCorruption:
            return "Data corruption detected. Please restart the app."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }
    
    var actionTitle: String {
        switch type {
        case .network:
            return "Retry"
        case .authentication:
            return "Sign In"
        case .ai:
            return "Try Again"
        case .dataCorruption:
            return "Restart App"
        case .unknown:
            return "OK"
        }
    }
    
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        return lhs.id == rhs.id
    }
}

enum ErrorType: String {
    case network = "network"
    case authentication = "authentication"
    case ai = "ai"
    case dataCorruption = "data_corruption"
    case unknown = "unknown"
}

enum ErrorSeverity: String {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var icon: String {
        switch self {
        case .low:
            return "info.circle"
        case .medium:
            return "exclamationmark.triangle"
        case .high:
            return "exclamationmark.circle"
        case .critical:
            return "xmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .low:
            return .blue
        case .medium:
            return .orange
        case .high:
            return .red
        case .critical:
            return .red
        }
    }
}

// MARK: - Error Banner View
struct ErrorBanner: View {
    let error: AppError
    let onDismiss: () -> Void
    let onAction: (() -> Void)?
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(error.userFriendlyMessage)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if let context = error.context {
                    Text(context)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let onAction = onAction {
                Button(error.actionTitle) {
                    onAction()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var iconName: String {
        switch error.severity {
        case .low:
            return "info.circle.fill"
        case .medium:
            return "exclamationmark.triangle.fill"
        case .high:
            return "xmark.circle.fill"
        case .critical:
            return "flame.fill"
        }
    }
    
    private var iconColor: Color {
        switch error.severity {
        case .low:
            return .blue
        case .medium:
            return .orange
        case .high:
            return .red
        case .critical:
            return .purple
        }
    }
    
    private var backgroundColor: Color {
        switch error.severity {
        case .low:
            return Color.blue.opacity(0.1)
        case .medium:
            return Color.orange.opacity(0.1)
        case .high:
            return Color.red.opacity(0.1)
        case .critical:
            return Color.purple.opacity(0.1)
        }
    }
}

// MARK: - Error Alert View
struct ErrorAlert: View {
    @Binding var isPresented: Bool
    let error: AppError
    let onAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Oops!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(error.userFriendlyMessage)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                Button("Dismiss") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                
                if let onAction = onAction {
                    Button(error.actionTitle) {
                        onAction()
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let errorOccurred = Notification.Name("errorOccurred")
    static let networkError = Notification.Name("networkError")
}

// MARK: - View Modifier for Error Handling
struct ErrorHandling: ViewModifier {
    @StateObject private var errorManager = ErrorManager.shared
    @State private var showAlert = false
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                if errorManager.showError, let error = errorManager.currentError {
                    ErrorBanner(
                        error: error,
                        onDismiss: {
                            errorManager.dismissError()
                        },
                        onAction: nil
                    )
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(), value: errorManager.showError)
                }
                
                Spacer()
            }
        }
        .alert(isPresented: $showAlert) {
            if let error = errorManager.currentError {
                return Alert(
                    title: Text("Error"),
                    message: Text(error.userFriendlyMessage),
                    dismissButton: .default(Text("OK")) {
                        errorManager.dismissError()
                    }
                )
            } else {
                return Alert(title: Text("Unknown Error"))
            }
        }
        .onChange(of: errorManager.currentError) { _, error in
            if error?.severity == .critical {
                showAlert = true
            }
        }
    }
}


