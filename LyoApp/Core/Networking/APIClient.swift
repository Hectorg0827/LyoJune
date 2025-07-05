import Foundation
import Network
import Combine
// Note: ErrorTypes and APIModels should be imported

// Importing ErrorTypes for APIError and other error types
// Importing APIModels for EmptyResponse and other API models

// MARK: - Enhanced Production API Client
@MainActor
public class APIClient: APIClientProtocol, ObservableObject {
    // MARK: - Published Properties
    @Published public var isOnline = true
    @Published public var isLoading = false
    @Published public var error: APIError?
    @Published public var isConnected = true
    
    // MARK: - Private Properties
    private let session: URLSession
    private let networkMonitor = NWPathMonitor()
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var cancellables = Set<AnyCancellable>()
    
    // Offline support
    private var offlineRequestQueue: [OfflineRequest] = []
    private let offlineQueueFile: URL
    
    // Rate limiting
    private var requestCounts: [String: (count: Int, resetTime: Date)] = [:]
    private let rateLimitWindow: TimeInterval = 60
    private let maxRequestsPerWindow = 100

    public static let shared = APIClient()

    public init(session: URLSession = .shared) {
        // Enhanced session configuration
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.httpAdditionalHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "LyoApp/1.0"
        ]
        
        self.session = URLSession(configuration: config)
        
        // Setup offline queue file
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Documents directory not found.")
        }
        self.offlineQueueFile = documentsPath.appendingPathComponent("offline_requests.json")
        
        // Configure JSON encoding/decoding
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        setupNetworkMonitoring()
        loadOfflineQueue()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.isConnected = path.status == .satisfied
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor.start(queue: queue)
    }

    public func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        // Check network connectivity
        guard isConnected else {
            throw APIError.noInternetConnection
        }
        
        let request = try endpoint.asURLRequest()
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError
            }
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case 200...299:
                break // Success
            case 401:
                throw APIError.unauthorized
            case 400...499:
                throw APIError.networkError
            case 500...599:
                throw APIError.serverError(httpResponse.statusCode, nil)
            default:
                throw APIError.networkError
            }
            
            // Handle empty responses
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(T.self, from: data)
            } catch {
                print("Decoding error: \(error)")
                throw APIError.decodingError(error)
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError
        }
    }
    
    // MARK: - Offline Queue Management
    
    private func loadOfflineQueue() {
        guard FileManager.default.fileExists(atPath: offlineQueueFile.path) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: offlineQueueFile)
            offlineRequestQueue = try decoder.decode([OfflineRequest].self, from: data)
        } catch {
            print("Failed to load offline queue: \(error)")
            offlineRequestQueue = []
        }
    }
    
    private func saveOfflineQueue() {
        do {
            let data = try encoder.encode(offlineRequestQueue)
            try data.write(to: offlineQueueFile)
        } catch {
            print("Failed to save offline queue: \(error)")
        }
    }
    
    deinit {
        networkMonitor.cancel()
    }
}

