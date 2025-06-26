import Foundation
import Combine

// MARK: - API Client Protocol (Centralized)
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
            self.session.dataTask(with: request) { data, response, error in
                if let error = error {
                    promise(.failure(.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    promise(.failure(.invalidResponse))
                    return
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    promise(.failure(.serverError(httpResponse.statusCode)))
                    return
                }
                
                guard let data = data else {
                    promise(.failure(.noData))
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let result = try decoder.decode(T.self, from: data)
                    promise(.success(result))
                } catch {
                    promise(.failure(.decodingError(error)))
                }
            }.resume()
        }
    }
    
    public func uploadFile<T: Codable>(to endpoint: APIEndpoint, fileData: Data, fileName: String, mimeType: String) -> Future<T, NetworkError> {
        return Future { promise in
            do {
                let request = try self.buildMultipartRequest(for: endpoint, fileData: fileData, fileName: fileName, mimeType: mimeType)
                
                self.session.dataTask(with: request) { data, response, error in
                    if let error = error {
                        promise(.failure(.networkError(error)))
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        promise(.failure(.invalidResponse))
                        return
                    }
                    
                    guard 200...299 ~= httpResponse.statusCode else {
                        promise(.failure(.serverError(httpResponse.statusCode)))
                        return
                    }
                    
                    guard let data = data else {
                        promise(.failure(.noData))
                        return
                    }
                    
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        let result = try decoder.decode(T.self, from: data)
                        promise(.success(result))
                    } catch {
                        promise(.failure(.decodingError(error)))
                    }
                }.resume()
            } catch {
                promise(.failure(.networkError(error)))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    protected func buildURLRequest(for endpoint: APIEndpoint) throws -> URLRequest {
        guard let url = URL(string: baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        
        // Add default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add custom headers
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
    
    protected func buildMultipartRequest(for endpoint: APIEndpoint, fileData: Data, fileName: String, mimeType: String) throws -> URLRequest {
        guard let url = URL(string: baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // Add custom headers
        endpoint.headers?.forEach { key, value in
            if key.lowercased() != "content-type" {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        return request
    }
}

// MARK: - Empty Request Type
public struct EmptyRequest: Codable {
    public init() {}
}
