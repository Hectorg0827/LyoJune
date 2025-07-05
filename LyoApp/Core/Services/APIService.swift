import Foundation

// MARK: - API Service Base Protocol
protocol APIService {
    var apiClient: APIClientProtocol { get }
}

// MARK: - Base API Service Class
@MainActor
class BaseAPIService: APIService {
    let apiClient: APIClientProtocol
    
    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }
}

// MARK: - Service Factory
class ServiceFactory {
    static let shared = ServiceFactory()
    
    private init() {}
    
    private let apiClient: APIClientProtocol = APIClient.shared
    
    // Service instances
    lazy var authService = EnhancedAuthService.shared
    lazy var learningService = LearningAPIService(apiClient: apiClient)
    lazy var gamificationService = GamificationAPIService(apiClient: apiClient)
    lazy var communityService = CommunityAPIService(apiClient: apiClient)
    lazy var userService = CDUserAPIService(apiClient: apiClient)
    lazy var searchService = SearchAPIService(apiClient: apiClient)
    lazy var storiesService = StoriesAPIService(apiClient: apiClient)
    lazy var messagesService = MessagesAPIService(apiClient: apiClient)
}