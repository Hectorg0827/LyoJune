import Foundation
import Combine

// MARK: - API Client Protocol
public protocol APIClientProtocol {
    func request<T: Codable>(_ endpoint: APIEndpoint, responseType: T.Type) async throws -> T
    func request<T: Codable>(_ endpoint: APIEndpoint) async throws -> T
    func performRequest<T: Codable>(_ request: URLRequest, responseType: T.Type) -> Future<T, NetworkError>
    func uploadFile<T: Codable>(to endpoint: APIEndpoint, fileData: Data, fileName: String, mimeType: String) -> Future<T, NetworkError>
}

// MARK: - Base API Client
public class BaseAPIClient: APIClientProtocol {
    protected let session: URLSession
    protected let baseURL: String
    
    public init(baseURL: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    public func request<T: Codable>(_ endpoint: APIEndpoint, responseType: T.Type) async throws -> T {
        let urlRequest = try buildURLRequest(for: endpoint)
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
    
    public func request<T: Codable>(_ endpoint: APIEndpoint) async throws -> T {
        return try await request(endpoint, responseType: T.self)
    }
    
    public func performRequest<T: Codable>(_ request: URLRequest, responseType: T.Type) -> Future<T, NetworkError> {
        return Future { promise in
            Task {
                do {
                    let (data, response) = try await self.session.data(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        promise(.failure(.invalidResponse))
                        return
                    }
                    
                    guard 200...299 ~= httpResponse.statusCode else {
                        promise(.failure(.serverError(httpResponse.statusCode)))
                        return
                    }
                    
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let result = try decoder.decode(T.self, from: data)
                    promise(.success(result))
                } catch {
                    if let networkError = error as? NetworkError {
                        promise(.failure(networkError))
                    } else {
                        promise(.failure(.networkError(error)))
                    }
                }
            }
        }
    }
    
    public func uploadFile<T: Codable>(to endpoint: APIEndpoint, fileData: Data, fileName: String, mimeType: String) -> Future<T, NetworkError> {
        return Future { promise in
            Task {
                do {
                    let request = try self.buildMultipartRequest(for: endpoint, fileData: fileData, fileName: fileName, mimeType: mimeType)
                    let (data, response) = try await self.session.data(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        promise(.failure(.invalidResponse))
                        return
                    }
                    
                    guard 200...299 ~= httpResponse.statusCode else {
                        promise(.failure(.serverError(httpResponse.statusCode)))
                        return
                    }
                    
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601 
                    let result = try decoder.decode(T.self, from: data)
                    promise(.success(result))
                } catch {
                    if let networkError = error as? NetworkError {
                        promise(.failure(networkError))
                    } else {
                        promise(.failure(.networkError(error)))
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    protected func buildURLRequest(for endpoint: APIEndpoint) throws -> URLRequest {
        let baseURL = URL(string: baseURL)!
        let url = baseURL.appendingPathComponent(endpoint.path)
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        
        // Add query parameters
        if !endpoint.queryParameters.isEmpty {
            components.queryItems = endpoint.queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        // Add query items if provided
        if let queryItems = endpoint.queryItems {
            components.queryItems = (components.queryItems ?? []) + queryItems
        }
        
        guard let finalURL = components.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = endpoint.method.rawValue
        
        // Add headers
        for (key, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add body if present
        if let body = endpoint.body {
            request.httpBody = body
        }
        
        return request
    }
    
    protected func buildMultipartRequest(for endpoint: APIEndpoint, fileData: Data, fileName: String, mimeType: String) throws -> URLRequest {
        let boundary = "Boundary-\(UUID().uuidString)"
        let baseURL = URL(string: baseURL)!
        let url = baseURL.appendingPathComponent(endpoint.path)
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Add headers
        for (key, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Create multipart body
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        return request
    }
}
