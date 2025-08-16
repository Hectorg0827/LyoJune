import UIKit
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure user notifications
        configureUserNotifications()

        // --- Other App-wide setup can go here ---
        // For example, initializing analytics, setting up global appearance, etc.

        return true
    }

    // MARK: - Push Notifications

    private func configureUserNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        // Request authorization to display alerts, play sounds, and badge the app icon.
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Failed to request notification authorization: \(error.localizedDescription)")
                return
            }

            guard granted else {
                print("Notification authorization denied.")
                return
            }

            // If granted, register for remote notifications on the main thread.
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Successfully registered for remote notifications with device token: \(tokenString)")

        // TODO: Send the device token to the backend via a dedicated PushService
        // This service will call POST /v1/push/register
        // sendDeviceTokenToBackend(token: tokenString)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {

    // Handle notification presentation while the app is in the foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        // Show the alert, play the sound, and update the badge
        completionHandler([.banner, .sound, .badge])
    }

    // Handle user interaction with the notification (e.g., tapping on it).
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {

        let userInfo = response.notification.request.content.userInfo
        print("Received notification response with user info: \(userInfo)")

        // TODO: Implement deep linking logic here.
        // Parse the userInfo dictionary for a deep link URL or identifier and navigate to the correct screen.

        completionHandler()
    }
}
