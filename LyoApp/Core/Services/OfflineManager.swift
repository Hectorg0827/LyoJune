import Foundation
import Network
import Combine

@MainActor
class OfflineManager: ObservableObject {
    static let shared = OfflineManager()
    
    @Published var isOffline = false
    @Published var hasOfflineData = false
    @Published var lastOnlineTime: Date?
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "OfflineMonitor")
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let wasOffline = self?.isOffline ?? false
                self?.isOffline = path.status != .satisfied
                
                if wasOffline && path.status == .satisfied {
                    // Just came back online
                    self?.handleBackOnline()
                } else if path.status != .satisfied {
                    // Just went offline
                    self?.handleWentOffline()
                }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    private func handleWentOffline() {
        lastOnlineTime = Date()
        
        // Check if we have offline data available
        checkOfflineDataAvailability()
        
        // Post notification for offline mode
        NotificationCenter.default.post(
            name: NSNotification.Name("AppWentOffline"),
            object: nil
        )
    }
    
    private func handleBackOnline() {
        // Post notification for online mode
        NotificationCenter.default.post(
            name: NSNotification.Name("AppCameOnline"),
            object: nil
        )
        
        // Trigger data sync if needed
        Task {
            await syncOfflineData()
        }
    }
    
    private func checkOfflineDataAvailability() {
        // Check if we have cached data for offline use
        // This would typically check Core Data, UserDefaults, or other local storage
        
        let hasCachedCourses = UserDefaults.standard.object(forKey: "cached_courses") != nil
        let hasCachedProfile = UserDefaults.standard.object(forKey: "cached_profile") != nil
        let hasCachedFeed = UserDefaults.standard.object(forKey: "cached_feed") != nil
        
        hasOfflineData = hasCachedCourses || hasCachedProfile || hasCachedFeed
    }
    
    private func syncOfflineData() async {
        // Sync any offline changes when coming back online
        // This would typically involve:
        // 1. Uploading offline changes
        // 2. Downloading latest data
        // 3. Resolving conflicts
        
        print("Syncing offline data...")
        
        // Simulate sync process
        try? await Task.sleep(for: .seconds(1))
        
        print("Offline data sync completed")
    }
    
    func enableOfflineMode() {
        // Prepare app for offline usage
        // Cache essential data
        cacheEssentialData()
    }
    
    func disableOfflineMode() {
        // Clean up offline data if needed
        // Re-enable full online functionality
    }
    
    private func cacheEssentialData() {
        // Cache user profile, recent courses, etc.
        // This would be implemented based on specific app needs
        print("Caching essential data for offline use")
    }
    
    func getOfflineDuration() -> TimeInterval? {
        guard let lastOnlineTime = lastOnlineTime else { return nil }
        return Date().timeIntervalSince(lastOnlineTime)
    }
    
    func getOfflineMessage() -> String {
        if let duration = getOfflineDuration() {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.minute, .hour, .day]
            formatter.unitsStyle = .abbreviated
            
            if let formattedDuration = formatter.string(from: duration) {
                return "Offline for \(formattedDuration)"
            }
        }
        
        return "Currently offline"
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - Offline Data Models
struct OfflineCapability {
    let isAvailable: Bool
    let features: [String]
    let limitations: [String]
    
    static let `default` = OfflineCapability(
        isAvailable: true,
        features: [
            "View downloaded courses",
            "Access saved notes",
            "Review completed lessons",
            "Practice offline quizzes"
        ],
        limitations: [
            "Cannot sync progress",
            "New content unavailable",
            "Social features disabled",
            "AI features limited"
        ]
    )
}
