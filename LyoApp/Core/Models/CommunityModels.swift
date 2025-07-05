import Foundation

// LeaderboardUser is defined in AppModels.swift

public struct JoinGroupResponse: Codable {
    public let success: Bool
    public let memberCount: Int
}

public struct JoinEventResponse: Codable {
    public let success: Bool
    public let attendeeCount: Int
}

public struct LeaderboardResponse: Codable {
    public let users: [LeaderboardUser]
    public let currentUser: LeaderboardUser?
    public let totalUsers: Int
    public let timeframe: String
}

// UserStats is defined in AppModels.swift