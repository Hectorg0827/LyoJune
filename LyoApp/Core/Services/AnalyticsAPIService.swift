import Foundation
import Combine

// MARK: - Analytics API Service
class AnalyticsAPIService: ObservableObject {
    static let shared = AnalyticsAPIService()
    
    private let networkManager: EnhancedNetworkManager
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        self.networkManager = EnhancedNetworkManager.shared
    }
    
    // MARK: - Event Tracking
    func trackEvent(_ eventName: String, parameters: [String: Any]? = nil) async {
        guard let baseURL = URL(string: ConfigurationManager.shared.baseURL) else {
            print("❌ Invalid analytics base URL")
            return
        }
        
        let url = baseURL.appendingPathComponent("analytics/track")
        
        let eventData: [String: Any] = [
            "event_name": eventName,
            "parameters": parameters ?? [:],
            "timestamp": Date().timeIntervalSince1970,
            "session_id": UUID().uuidString
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: eventData)
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = data
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("✅ Analytics event tracked: \(eventName)")
                } else {
                    print("⚠️ Analytics tracking failed with status: \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("❌ Analytics tracking error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - User Events
    func trackUserAction(_ action: String, context: [String: Any]? = nil) async {
        await trackEvent("user_action", parameters: [
            "action": action,
            "context": context ?? [:]
        ])
    }
    
    func trackScreenView(_ screenName: String, parameters: [String: Any]? = nil) async {
        await trackEvent("screen_view", parameters: [
            "screen_name": screenName,
            "additional_data": parameters ?? [:]
        ])
    }
    
    func trackError(_ error: Error, context: [String: Any]? = nil) async {
        await trackEvent("error", parameters: [
            "error_description": error.localizedDescription,
            "error_type": String(describing: type(of: error)),
            "context": context ?? [:]
        ])
    }
}
