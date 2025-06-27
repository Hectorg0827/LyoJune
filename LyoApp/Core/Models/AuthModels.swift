
// AuthModels.swift
// LyoApp - Advanced Authentication Models for Backend Integration
// Phase 4: Backend Integration & API Development

import Foundation
import Combine

// MARK: - Basic Authentication Requests (Enhanced)

public struct LoginRequest: Codable {
    public let email: String
    public let password: String
    public let deviceId: String
    public let deviceName: String
    public let rememberMe: Bool
    public let twoFactorCode: String?
    
    public init(email: String, password: String, deviceId: String, deviceName: String, rememberMe: Bool = false, twoFactorCode: String? = nil) {
        self.email = email
        self.password = password
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.rememberMe = rememberMe
        self.twoFactorCode = twoFactorCode
    }
}

public struct RegisterRequest: Codable {
    public let email: String
    public let password: String
    public let firstName: String
    public let lastName: String
    public let username: String
    public let deviceId: String
    public let deviceName: String
    public let acceptsTerms: Bool
    public let marketingOptIn: Bool
    
    public init(email: String, password: String, firstName: String, lastName: String, username: String, deviceId: String, deviceName: String, acceptsTerms: Bool = true, marketingOptIn: Bool = false) {
        self.email = email
        self.password = password
        self.firstName = firstName
        self.lastName = lastName
        self.username = username
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.acceptsTerms = acceptsTerms
        self.marketingOptIn = marketingOptIn
    }
}

public struct AuthResponse: Codable {
    public let user: User
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int
    public let tokenType: String
    public let scope: String?
    
    public init(user: User, accessToken: String, refreshToken: String, expiresIn: Int, tokenType: String = "Bearer", scope: String? = nil) {
        self.user = user
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.tokenType = tokenType
        self.scope = scope
    }
}

public struct RefreshTokenRequest: Codable {
    public let refreshToken: String
    
    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}

public struct UpdateProfileRequest: Codable {
    public let firstName: String
    public let lastName: String
    public let bio: String?
    public let location: String?
    public let website: String?
    
    public init(firstName: String, lastName: String, bio: String? = nil, location: String? = nil, website: String? = nil) {
        self.firstName = firstName
        self.lastName = lastName
        self.bio = bio
        self.location = location
        self.website = website
    }
}

// MARK: - Advanced Authentication Models

public struct AuthCredentials: Codable {
    public let email: String
    public let password: String
    
    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
    
    public func toAPIPayload() -> [String: Any] {
        return [
            "email": email,
            "password": password
        ]
    }
}

public struct AuthTokens: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let tokenType: String
    public let expiresIn: TimeInterval
    public let scope: String?
    public let issuedAt: Date
    
    public var expiresAt: Date {
        return issuedAt.addingTimeInterval(expiresIn)
    }
    
    public var isExpired: Bool {
        return Date() >= expiresAt
    }
    
    public var willExpireSoon: Bool {
        let fiveMinutesFromNow = Date().addingTimeInterval(300) // 5 minutes
        return fiveMinutesFromNow >= expiresAt
    }
    
    public init(
        accessToken: String,
        refreshToken: String,
        tokenType: String = "Bearer",
        expiresIn: TimeInterval,
        scope: String? = nil,
        issuedAt: Date = Date()
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenType = tokenType
        self.expiresIn = expiresIn
        self.scope = scope
        self.issuedAt = issuedAt
    }
    
    public static func fromAPIResponse(_ data: [String: Any]) -> AuthTokens? {
        guard let accessToken = data["access_token"] as? String,
              let refreshToken = data["refresh_token"] as? String,
              let expiresIn = data["expires_in"] as? TimeInterval else {
            return nil
        }
        
        let tokenType = data["token_type"] as? String ?? "Bearer"
        let scope = data["scope"] as? String
        let issuedAt = Date()
        
        return AuthTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            tokenType: tokenType,
            expiresIn: expiresIn,
            scope: scope,
            issuedAt: issuedAt
        )
    }
}

public struct AuthSession: Codable {
    public let user: User
    public let tokens: AuthTokens
    public let deviceInfo: DeviceInfo
    public let sessionID: String
    public let createdAt: Date
    public let lastActivity: Date
    public let ipAddress: String?
    
    public var isActive: Bool {
        return !tokens.isExpired
    }
    
    public init(
        user: User,
        tokens: AuthTokens,
        deviceInfo: DeviceInfo,
        sessionID: String = UUID().uuidString,
        createdAt: Date = Date(),
        lastActivity: Date = Date(),
        ipAddress: String? = nil
    ) {
        self.user = user
        self.tokens = tokens
        self.deviceInfo = deviceInfo
        self.sessionID = sessionID
        self.createdAt = createdAt
        self.lastActivity = lastActivity
        self.ipAddress = ipAddress
    }
}

public struct DeviceInfo: Codable {
    public let deviceID: String
    public let deviceName: String
    public let deviceModel: String
    public let osName: String
    public let osVersion: String
    public let appVersion: String
    public let buildNumber: String
    public let language: String
    public let timezone: String
    
    public init(
        deviceID: String = UUID().uuidString,
        deviceName: String = "Unknown Device",
        deviceModel: String = "Unknown Model",
        osName: String = "iOS",
        osVersion: String = "17.0",
        appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
        buildNumber: String = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1",
        language: String = Locale.current.languageCode ?? "en",
        timezone: String = TimeZone.current.identifier
    ) {
        self.deviceID = deviceID
        self.deviceName = deviceName
        self.deviceModel = deviceModel
        self.osName = osName
        self.osVersion = osVersion
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.language = language
        self.timezone = timezone
    }
    
    public func toAPIPayload() -> [String: Any] {
        return [
            "device_id": deviceID,
            "device_name": deviceName,
            "device_model": deviceModel,
            "os_name": osName,
            "os_version": osVersion,
            "app_version": appVersion,
            "build_number": buildNumber,
            "language": language,
            "timezone": timezone
        ]
    }
}

// MARK: - Social Authentication

public enum SocialProvider: String, CaseIterable, Codable {
    case apple = "apple"
    case google = "google"
    case facebook = "facebook"
    case twitter = "twitter"
    case github = "github"
    case linkedin = "linkedin"
    
    public var displayName: String {
        switch self {
        case .apple: return "Apple"
        case .google: return "Google"
        case .facebook: return "Facebook"
        case .twitter: return "Twitter"
        case .github: return "GitHub"
        case .linkedin: return "LinkedIn"
        }
    }
    
    public var iconName: String {
        return "logo.\(rawValue)"
    }
}

public struct SocialAuthCredentials: Codable {
    public let provider: SocialProvider
    public let token: String
    public let userInfo: SocialUserInfo?
    
    public init(provider: SocialProvider, token: String, userInfo: SocialUserInfo? = nil) {
        self.provider = provider
        self.token = token
        self.userInfo = userInfo
    }
    
    public func toAPIPayload() -> [String: Any] {
        var payload: [String: Any] = [
            "provider": provider.rawValue,
            "token": token
        ]
        
        if let userInfo = userInfo {
            payload["user_info"] = userInfo.toAPIPayload()
        }
        
        return payload
    }
}

public struct SocialUserInfo: Codable {
    public let id: String
    public let email: String?
    public let name: String?
    public let firstName: String?
    public let lastName: String?
    public let avatarURL: URL?
    
    public init(
        id: String,
        email: String? = nil,
        name: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        avatarURL: URL? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.firstName = firstName
        self.lastName = lastName
        self.avatarURL = avatarURL
    }
    
    public func toAPIPayload() -> [String: Any] {
        var payload: [String: Any] = [
            "id": id
        ]
        
        if let email = email { payload["email"] = email }
        if let name = name { payload["name"] = name }
        if let firstName = firstName { payload["first_name"] = firstName }
        if let lastName = lastName { payload["last_name"] = lastName }
        if let avatarURL = avatarURL { payload["avatar_url"] = avatarURL.absoluteString }
        
        return payload
    }
}

// MARK: - Two-Factor Authentication

public struct TwoFactorSetup: Codable {
    public let secret: String
    public let qrCodeURL: URL
    public let backupCodes: [String]
    public let setupComplete: Bool
    
    public init(secret: String, qrCodeURL: URL, backupCodes: [String], setupComplete: Bool = false) {
        self.secret = secret
        self.qrCodeURL = qrCodeURL
        self.backupCodes = backupCodes
        self.setupComplete = setupComplete
    }
}

public struct TwoFactorChallenge: Codable {
    public let challengeID: String
    public let method: TwoFactorMethod
    public let maskedTarget: String?
    public let expiresAt: Date
    
    public var isExpired: Bool {
        return Date() > expiresAt
    }
    
    public init(challengeID: String, method: TwoFactorMethod, maskedTarget: String? = nil, expiresAt: Date) {
        self.challengeID = challengeID
        self.method = method
        self.maskedTarget = maskedTarget
        self.expiresAt = expiresAt
    }
}

public enum TwoFactorMethod: String, CaseIterable, Codable {
    case totp = "totp"              // Time-based One-Time Password (authenticator app)
    case sms = "sms"                // SMS verification
    case email = "email"            // Email verification
    case backupCode = "backup_code" // Backup recovery codes
    case push = "push"              // Push notification
    
    public var displayName: String {
        switch self {
        case .totp: return "Authenticator App"
        case .sms: return "SMS"
        case .email: return "Email"
        case .backupCode: return "Backup Code"
        case .push: return "Push Notification"
        }
    }
}

// MARK: - Password Reset

public struct PasswordResetRequest: Codable {
    public let email: String
    
    public init(email: String) {
        self.email = email
    }
    
    public func toAPIPayload() -> [String: Any] {
        return ["email": email]
    }
}

public struct PasswordReset: Codable {
    public let token: String
    public let newPassword: String
    public let confirmPassword: String
    
    public var isValid: Bool {
        return newPassword == confirmPassword && newPassword.count >= 8
    }
    
    public init(token: String, newPassword: String, confirmPassword: String) {
        self.token = token
        self.newPassword = newPassword
        self.confirmPassword = confirmPassword
    }
    
    public func toAPIPayload() -> [String: Any] {
        return [
            "token": token,
            "password": newPassword,
            "password_confirmation": confirmPassword
        ]
    }
}

// MARK: - Account Verification

public struct EmailVerification: Codable {
    public let token: String
    public let email: String
    
    public init(token: String, email: String) {
        self.token = token
        self.email = email
    }
    
    public func toAPIPayload() -> [String: Any] {
        return [
            "token": token,
            "email": email
        ]
    }
}

// MARK: - Authentication State

public enum AuthState: Equatable {
    case unauthenticated
    case authenticating
    case authenticated(AuthSession)
    case twoFactorRequired(TwoFactorChallenge)
    case emailVerificationRequired(String) // email
    case passwordResetRequired
    case error(AuthError)
    
    public var isAuthenticated: Bool {
        if case .authenticated = self {
            return true
        }
        return false
    }
    
    public var user: User? {
        if case .authenticated(let session) = self {
            return session.user
        }
        return nil
    }
    
    public var session: AuthSession? {
        if case .authenticated(let session) = self {
            return session
        }
        return nil
    }
}

// MARK: - Security Models

public struct SecuritySettings: Codable {
    public let twoFactorEnabled: Bool
    public let biometricEnabled: Bool
    public let sessionTimeout: TimeInterval
    public let allowMultipleSessions: Bool
    public let trustedDevices: [String]
    public let lastPasswordChange: Date
    public let securityQuestions: [SecurityQuestion]
    
    public init(
        twoFactorEnabled: Bool = false,
        biometricEnabled: Bool = false,
        sessionTimeout: TimeInterval = 3600, // 1 hour
        allowMultipleSessions: Bool = true,
        trustedDevices: [String] = [],
        lastPasswordChange: Date = Date(),
        securityQuestions: [SecurityQuestion] = []
    ) {
        self.twoFactorEnabled = twoFactorEnabled
        self.biometricEnabled = biometricEnabled
        self.sessionTimeout = sessionTimeout
        self.allowMultipleSessions = allowMultipleSessions
        self.trustedDevices = trustedDevices
        self.lastPasswordChange = lastPasswordChange
        self.securityQuestions = securityQuestions
    }
}

public struct SecurityQuestion: Codable, Identifiable {
    public let id: UUID
    public let question: String
    public let answerHash: String
    public let createdAt: Date
    
    public init(id: UUID = UUID(), question: String, answerHash: String, createdAt: Date = Date()) {
        self.id = id
        self.question = question
        self.answerHash = answerHash
        self.createdAt = createdAt
    }
}

// MARK: - API Endpoints for Authentication

public struct AuthEndpoints {
    public static let login = "/api/v1/auth/login"
    public static let register = "/api/v1/auth/register"
    public static let logout = "/api/v1/auth/logout"
    public static let refresh = "/api/v1/auth/refresh"
    public static let forgotPassword = "/api/v1/auth/forgot-password"
    public static let resetPassword = "/api/v1/auth/reset-password"
    public static let verifyEmail = "/api/v1/auth/verify-email"
    public static let resendVerification = "/api/v1/auth/resend-verification"
    public static let socialAuth = "/api/v1/auth/social"
    public static let twoFactorSetup = "/api/v1/auth/2fa/setup"
    public static let twoFactorVerify = "/api/v1/auth/2fa/verify"
    public static let twoFactorDisable = "/api/v1/auth/2fa/disable"
    public static let sessions = "/api/v1/auth/sessions"
    public static let securitySettings = "/api/v1/auth/security"
}
