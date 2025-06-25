
import Foundation

public struct LoginRequest: Codable {
    let email: String
    let password: String
    let deviceId: String
    let deviceName: String
}

public struct RegisterRequest: Codable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    let username: String
    let deviceId: String
    let deviceName: String
}

public struct AuthResponse: Codable {
    let user: User
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
}

public struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

public struct UpdateProfileRequest: Codable {
    let firstName: String
    let lastName: String
    let bio: String?
}

public struct EmptyRequest: Codable {}
public struct EmptyResponse: Codable {}
