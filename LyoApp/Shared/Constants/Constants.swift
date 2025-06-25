import Foundation
import UIKit

struct Constants {
    
    // MARK: - App Information
    
    struct App {
        static let name = "LyoApp"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.lyo.lyoapp"
    }
    
    // MARK: - API Configuration
    
    struct API {
        static let baseURL = "https://api.lyo.app/v1"
        static let timeout: TimeInterval = 30.0
        static let maxRetryAttempts = 3
        
        struct Endpoints {
            static let auth = "/auth"
            static let courses = "/courses"
            static let videos = "/videos"
            static let posts = "/posts"
            static let community = "/community"
            static let profile = "/profile"
            static let analytics = "/analytics"
        }
    }
    
    // MARK: - User Defaults Keys
    
    struct UserDefaultsKeys {
        static let isOnboarded = "isOnboarded"
        static let authToken = "authToken"
        static let refreshToken = "refreshToken"
        static let userPreferences = "userPreferences"
        static let lastSyncDate = "lastSyncDate"
        static let offlineContent = "offlineContent"
    }
    
    // MARK: - Keychain Keys
    
    struct KeychainKeys {
        static let authToken = "auth_token"
        static let refreshToken = "refresh_token"
        static let userCredentials = "user_credentials"
        static let biometricData = "biometric_data"
    }
    
    // MARK: - Notification Names
    
    struct NotificationNames {
        static let userDidLogin = Notification.Name("userDidLogin")
        static let userDidLogout = Notification.Name("userDidLogout")
        static let networkStatusChanged = Notification.Name("networkStatusChanged")
        static let dataDidSync = Notification.Name("dataDidSync")
        static let courseCompleted = Notification.Name("courseCompleted")
        static let achievementUnlocked = Notification.Name("achievementUnlocked")
    }
    
    // MARK: - Analytics Events
    
    struct AnalyticsEvents {
        static let appLaunched = "app_launched"
        static let userSignedIn = "user_signed_in"
        static let userSignedOut = "user_signed_out"
        static let courseStarted = "course_started"
        static let courseCompleted = "course_completed"
        static let lessonCompleted = "lesson_completed"
        static let videoWatched = "video_watched"
        static let postShared = "post_shared"
        static let eventJoined = "event_joined"
        static let studyGroupJoined = "study_group_joined"
        static let achievementEarned = "achievement_earned"
        static let searchPerformed = "search_performed"
        static let contentCreated = "content_created"
    }
    
    // MARK: - File Paths
    
    struct FilePaths {
        static let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        static let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        static let temporary = FileManager.default.temporaryDirectory
        
        static var offlineContent: URL {
            documents.appendingPathComponent("OfflineContent")
        }
        
        static var downloadedVideos: URL {
            documents.appendingPathComponent("Videos")
        }
        
        static var userGenerated: URL {
            documents.appendingPathComponent("UserContent")
        }
    }
    
    // MARK: - Limits and Constraints
    
    struct Limits {
        static let maxVideoLength: TimeInterval = 300 // 5 minutes
        static let maxPostLength = 2000
        static let maxBioLength = 150
        static let maxUsernameLength = 30
        static let minPasswordLength = 8
        static let maxFileSizeMB = 50
        static let maxImagesPerPost = 5
        static let cacheSize = 100 * 1024 * 1024 // 100MB
    }
    
    // MARK: - Animation Durations
    
    struct Animations {
        static let short: TimeInterval = 0.2
        static let medium: TimeInterval = 0.3
        static let long: TimeInterval = 0.5
        static let extraLong: TimeInterval = 0.8
        
        static let springResponse = 0.3
        static let springDamping = 0.7
    }
    
    // MARK: - Device Information
    
    struct Device {
        static let isPhone = UIDevice.current.userInterfaceIdiom == .phone
        static let isPad = UIDevice.current.userInterfaceIdiom == .pad
        static let screenSize = UIScreen.main.bounds.size
        static let deviceModel = UIDevice.current.model
        static let systemVersion = UIDevice.current.systemVersion
        
        static var isSmallScreen: Bool {
            return screenSize.height < 812 // iPhone 8 and smaller
        }
        
        static var hasNotch: Bool {
            if #available(iOS 11.0, *) {
                let window = UIApplication.shared.windows.first
                return window?.safeAreaInsets.top ?? 0 > 24
            }
            return false
        }
    }
    
    // MARK: - Feature Flags
    
    struct FeatureFlags {
        static let enableOfflineMode = true
        static let enableDarkMode = true
        static let enableBiometricAuth = true
        static let enablePushNotifications = true
        static let enableAnalytics = true
        static let enableCrashlytics = true
        static let enableBetaFeatures = false
        static let enableDebugMode = _isDebugAssertConfiguration()
    }
    
    // MARK: - Error Messages
    
    struct ErrorMessages {
        static let networkError = "No internet connection available"
        static let serverError = "Server is currently unavailable"
        static let authenticationError = "Please sign in to continue"
        static let permissionError = "Permission required to access this feature"
        static let validationError = "Please check your input and try again"
        static let genericError = "Something went wrong. Please try again"
        static let timeoutError = "Request timed out. Please try again"
        static let parseError = "Unable to process the response"
    }
    
    // MARK: - Success Messages
    
    struct SuccessMessages {
        static let profileUpdated = "Profile updated successfully"
        static let courseCompleted = "Congratulations! Course completed"
        static let achievementUnlocked = "New achievement unlocked!"
        static let postShared = "Post shared successfully"
        static let eventJoined = "Successfully joined the event"
        static let groupJoined = "Welcome to the study group!"
        static let contentSaved = "Content saved for offline viewing"
        static let settingsSaved = "Settings saved successfully"
    }
    
    // MARK: - Regular Expressions
    
    struct RegexPatterns {
        static let email = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        static let password = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)[a-zA-Z\\d@$!%*?&]{8,}$"
        static let username = "^[a-zA-Z0-9_]{3,30}$"
        static let phoneNumber = "^\\+?[1-9]\\d{1,14}$"
        static let url = "https?:\\/\\/(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-zA-Z0-9()]{1,6}\\b([-a-zA-Z0-9()@:%_\\+.~#?&//=]*)"
    }
    
    // MARK: - Social Media
    
    struct SocialMedia {
        static let websiteURL = "https://lyo.app"
        static let supportEmail = "support@lyo.app"
        static let twitterHandle = "@lyoapp"
        static let instagramHandle = "@lyoapp"
        static let linkedinHandle = "company/lyoapp"
        static let appStoreURL = "https://apps.apple.com/app/lyoapp"
        static let privacyPolicyURL = "https://lyo.app/privacy"
        static let termsOfServiceURL = "https://lyo.app/terms"
    }
}

// MARK: - Environment Helper

private func _isDebugAssertConfiguration() -> Bool {
    #if DEBUG
    return true
    #else
    return false
    #endif
}