import UIKit

/// A centralized manager for triggering haptic feedback.
public enum HapticManager {

    /// Triggers an impact feedback gesture.
    /// - Parameter style: The intensity of the impact (e.g., `.light`, `.medium`, `.heavy`).
    public static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        #if os(iOS)
        // Ensure haptics are played only on iPhones, not iPads or other devices.
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }

        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }

    /// Triggers a notification feedback gesture.
    /// - Parameter type: The type of notification (`.success`, `.warning`, `.error`).
    public static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        #if os(iOS)
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }

        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
        #endif
    }
}
