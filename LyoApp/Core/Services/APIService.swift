import Foundation

// MARK: - API Service Base Protocol
protocol APIService {
    var apiClient: APIClientProtocol { get }
}

// MARK: - Base API Service Class
@MainActor
class BaseAPIService: APIService {
    let apiClient: APIClientProtocol
    
    init(apiClient: APIClientProtocol = {
        return ConfigurationManager.shared.shouldUseMockBackend ? MockAPIClient.shared : APIClient.shared
    }()) {
        self.apiClient = apiClient
    }
}

// MARK: - Service Factory
class ServiceFactory {
    static let shared = ServiceFactory()
    
    private init() {}
    
    private let apiClient: APIClientProtocol = {
        return ConfigurationManager.shared.shouldUseMockBackend ? MockAPIClient.shared : APIClient.shared
    }()
    
    // Service instances
    lazy var authService = EnhancedAuthService.shared
    lazy var learningService = LearningAPIService(apiClient: apiClient)
    lazy var gamificationService = GamificationAPIService(apiClient: apiClient)
    lazy var communityService = CommunityAPIService(apiClient: apiClient)
    lazy var userService = UserAPIService(apiClient: apiClient)
    lazy var searchService = SearchAPIService(apiClient: apiClient)
    lazy var storiesService = StoriesAPIService(apiClient: apiClient)
    lazy var messagesService = MessagesAPIService(apiClient: apiClient)
}