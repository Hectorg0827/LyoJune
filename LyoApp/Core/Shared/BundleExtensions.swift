import Foundation
import UIKit

// MARK: - Bundle Extensions (Centralized)
public extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    var appName: String {
        return infoDictionary?["CFBundleDisplayName"] as? String ?? 
               infoDictionary?["CFBundleName"] as? String ?? "Unknown"
    }
    
    var bundleId: String {
        return bundleIdentifier ?? "Unknown"
    }
}
