import Foundation

/// A generic, decodable struct to be used as the response type for API endpoints
/// that return an empty JSON body (`{}`) or no body at all on success.
public struct EmptyResponse: Decodable, Equatable {}
