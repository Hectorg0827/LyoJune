
import Foundation

public struct Endpoint {
    let path: String
    var method: HTTPMethod = .get
    var body: Encodable? = nil

    func asURLRequest() throws -> URLRequest {
        guard let url = URL(string: "https://api.lyo.app/v1" + path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        return request
    }
}

enum APIError: Error {
    case invalidURL
    case networkError
    case decodingError
    case mockDataNotFound
}
