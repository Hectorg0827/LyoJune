
import Foundation
import Network

// MARK: - Production API Client
public class APIClient: APIClientProtocol {
    private let session: URLSession
    private let networkMonitor = NWPathMonitor()
    private var isConnected = true

    public static let shared = APIClient()

    public init(session: URLSession = .shared) {
        self.session = session
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = path.status == .satisfied
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
                throw APIError.serverError(httpResponse.statusCode)
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
                throw APIError.decodingError
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError
        }
    }
    
    deinit {
        networkMonitor.cancel()
    }
}

