import Foundation

// MARK: - Core Data Errors
public enum CoreDataError: Error, LocalizedError {
    case contextSaveFailed(Error)
    case fetchFailed(Error)
    case entityNotFound
    case invalidManagedObject
    case persistentStoreError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .contextSaveFailed(let error):
            return "Failed to save context: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Fetch request failed: \(error.localizedDescription)"
        case .entityNotFound:
            return "Entity not found in Core Data model"
        case .invalidManagedObject:
            return "Invalid managed object"
        case .persistentStoreError(let error):
            return "Persistent store error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Configuration Errors
public enum ConfigurationError: Error, LocalizedError {
    case missingAPIKey
    case missingBaseURL
    case invalidConfiguration
    case environmentNotSet
    
    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key not configured"
        case .missingBaseURL:
            return "Base URL not configured"
        case .invalidConfiguration:
            return "Invalid configuration"
        case .environmentNotSet:
            return "Environment not set"
        }
    }
}

// MARK: - WebSocket Errors
public enum WebSocketError: Error, LocalizedError {
    case connectionFailed
    case disconnected
    case messageEncodingFailed
    case messageDecodingFailed
    case invalidURL
    case authenticationFailed
    
    public var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "WebSocket connection failed"
        case .disconnected:
            return "WebSocket disconnected"
        case .messageEncodingFailed:
            return "Failed to encode WebSocket message"
        case .messageDecodingFailed:
            return "Failed to decode WebSocket message"
        case .invalidURL:
            return "Invalid WebSocket URL"
        case .authenticationFailed:
            return "WebSocket authentication failed"
        }
    }
}
