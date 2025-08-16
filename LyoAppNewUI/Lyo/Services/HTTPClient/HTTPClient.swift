import Foundation

// MARK: - HTTPClient Protocol

/// A protocol defining the interface for a client that performs network requests.
public protocol HTTPClienting {
    /// Performs a network request for a given endpoint and decodes the response.
    /// - Parameter endpoint: The `Endpoint` to request.
    /// - Returns: The decoded response object.
    /// - Throws: An `APIError` if the request fails for any reason.
    func request<T>(_ endpoint: Endpoint<T>) async throws -> T
}

// MARK: - HTTPClient Implementation

/// The main implementation of the `HTTPClienting` protocol.
public final class HTTPClient: HTTPClienting {

    private let session: URLSession
    private let baseURL: URL
    private let authorizer: RequestAuthorizer

    /// Initializes a new HTTP client.
    /// - Parameters:
    ///   - session: The `URLSession` to use for network requests. Defaults to `URLSession.shared`.
    ///   - baseURL: The base URL to which endpoint paths will be appended.
    ///   - authService: A service conforming to `AuthServicing` for token management.
    public init(session: URLSession = .shared, baseURL: URL, authService: AuthServicing) {
        self.session = session
        self.baseURL = baseURL
        self.authorizer = RequestAuthorizer(authService: authService)
    }

    public func request<T>(_ endpoint: Endpoint<T>) async throws -> T where T : Decodable {
        do {
            // Attempt to perform the request, with retries for GETs.
            return try await performRequestWithRetries(endpoint, authorization: await authorizer.currentAccessToken())
        } catch APIError.unexpectedStatusCode(401) {
            // If it fails with a 401, handle the unauthorized error (which triggers a token refresh).
            try await authorizer.handleUnauthorizedError()

            // Retry the request with the (presumably) new token.
            return try await performRequestWithRetries(endpoint, authorization: await authorizer.currentAccessToken())
        } catch {
            // Propagate any other errors.
            throw error
        }
    }

    /// Performs a request, applying a retry policy with exponential backoff for idempotent GET requests.
    private func performRequestWithRetries<T>(_ endpoint: Endpoint<T>, authorization token: String?) async throws -> T {
        // Only apply retry logic to idempotent GET requests.
        guard endpoint.method == .get else {
            return try await performSingleRequest(endpoint, authorization: token)
        }

        var attempts = 0
        let maxAttempts = 3
        var delay: TimeInterval = 1.0 // Initial delay of 1 second

        while true {
            attempts += 1
            do {
                return try await performSingleRequest(endpoint, authorization: token)
            } catch let error as APIError {
                // Only retry on network-level failures, and only if we have attempts left.
                guard case .requestFailed = error, attempts < maxAttempts else {
                    throw error
                }

                // Wait for the calculated delay.
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

                // Double the delay for the next attempt.
                delay *= 2
            }
        }
    }

    /// Performs a single network request and handles its response.
    private func performSingleRequest<T>(_ endpoint: Endpoint<T>, authorization token: String?) async throws -> T where T : Decodable {
        // 1. Construct URL
        let url = baseURL.appendingPathComponent(endpoint.path)
        var request = URLRequest(url: url)

        // 2. Set Method, Body, and Headers
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        endpoint.headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        // 3. Add Authorization
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // 4. Perform Request
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            // Wrap underlying URLSession errors in our custom APIError.
            throw APIError.requestFailed(error)
        }

        // 5. Check Response Status Code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed(URLError(.badServerResponse))
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.unexpectedStatusCode(httpResponse.statusCode)
        }

        // 6. Decode Response
        // If the expected response type is EmptyResponse and the data is indeed empty,
        // we can return a success without trying to decode.
        if T.self == EmptyResponse.self && data.isEmpty {
            return EmptyResponse() as! T
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }
}

// MARK: - Request Authorizer Actor

/// An actor responsible for managing and refreshing authentication tokens in a thread-safe manner.
private actor RequestAuthorizer {

    private let authService: AuthServicing
    private var refreshTask: Task<Void, Error>?

    init(authService: AuthServicing) {
        self.authService = authService
    }

    func currentAccessToken() async -> String? {
        return await authService.currentAccessToken()
    }

    func handleUnauthorizedError() async throws {
        if let refreshTask = refreshTask {
            try await refreshTask.value
            return
        }

        let task = Task {
            defer { self.refreshTask = nil }
            try await authService.refreshToken()
        }

        self.refreshTask = task
        try await task.value
    }
}
