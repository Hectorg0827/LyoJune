import Foundation

/// A utility for providing configuration values from the `Config.plist` file.
/// This approach centralizes access to environment-specific variables and provides type safety.
public enum AppConfig {

    // MARK: - Private Properties

    private static let info: AppSettings = {
        guard let url = Bundle.main.url(forResource: "Config", withExtension: "plist") else {
            fatalError("FATAL: Config.plist not found. Please ensure it is added to the correct target.")
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = PropertyListDecoder()
            return try decoder.decode(AppSettings.self, from: data)
        } catch {
            fatalError("FATAL: Could not decode Config.plist. Error: \(error)")
        }
    }()

    // MARK: - Public Configuration Properties

    /// The base URL for the Lyo REST API.
    public static var baseURL: URL {
        guard let url = URL(string: info.LYO_BASE_URL) else {
            fatalError("FATAL: LYO_BASE_URL in Config.plist is not a valid URL.")
        }
        return url
    }

    /// The WebSocket URL for real-time communication.
    public static var webSocketURL: URL {
        guard let url = URL(string: info.LYO_WS_URL) else {
            fatalError("FATAL: LYO_WS_URL in Config.plist is not a valid URL.")
        }
        return url
    }

    /// The selected ranker for content feeds.
    public static var rankerChoice: String {
        info.RANKER_CHOICE
    }

    /// A flag to enable or disable exploration features.
    public static var isExplorationEnabled: Bool {
        info.EXPLORATION_ENABLED
    }
}

// MARK: - Private Decodable Struct

/// A Decodable struct that maps directly to the keys and values in `Config.plist`.
private struct AppSettings: Decodable {
    let LYO_BASE_URL: String
    let LYO_WS_URL: String
    let RANKER_CHOICE: String
    let EXPLORATION_ENABLED: Bool
}
