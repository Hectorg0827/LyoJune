import Foundation

// Note: This file references UserProfile from AppModels.swift
// Make sure to import or reference the file containing UserProfile

// MARK: - Shared API Request/Response Models

// MARK: - Empty Request/Response
public struct EmptyRequest: Codable {
    public init() {}
}

public struct EmptyResponse: Codable {
    public init() {}
}

// MARK: - Success Response
public struct SuccessResponse: Codable {
    public let success: Bool
    public let message: String?
    
    public init(success: Bool = true, message: String? = nil) {
        self.success = success
        self.message = message
    }
}

// MARK: - Token Response
public struct TokenResponse: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: TimeInterval
    
    public init(accessToken: String, refreshToken: String, expiresIn: TimeInterval) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
    }
}

// MARK: - Error Response
public struct ErrorResponse: Codable {
    public let error: String
    public let message: String
    public let code: Int?
    
    public init(error: String, message: String, code: Int? = nil) {
        self.error = error
        self.message = message
        self.code = code
    }
}

// MARK: - Pagination
public struct PaginationInfo: Codable {
    public let currentPage: Int
    public let totalPages: Int
    public let totalItems: Int
    public let itemsPerPage: Int
    public let hasNextPage: Bool
    public let hasPreviousPage: Bool
    
    public init(
        currentPage: Int,
        totalPages: Int,
        totalItems: Int,
        itemsPerPage: Int
    ) {
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.totalItems = totalItems
        self.itemsPerPage = itemsPerPage
        self.hasNextPage = currentPage < totalPages
        self.hasPreviousPage = currentPage > 1
    }
}

// MARK: - Paginated Response
public struct PaginatedResponse<T: Codable>: Codable {
    public let data: [T]
    public let pagination: PaginationInfo
    
    public init(data: [T], pagination: PaginationInfo) {
        self.data = data
        self.pagination = pagination
    }
}

// MARK: - API Response Wrapper
public struct APIResponse<T: Codable>: Codable {
    public let data: T?
    public let message: String?
    public let success: Bool
    public let error: String?
    public let code: Int?
    public let pagination: PaginationInfo?
    
    public init(data: T? = nil, message: String? = nil, success: Bool = true,
                error: String? = nil, code: Int? = nil, pagination: PaginationInfo? = nil) {
        self.data = data
        self.message = message
        self.success = success
        self.error = error
        self.code = code
        self.pagination = pagination
    }
}
