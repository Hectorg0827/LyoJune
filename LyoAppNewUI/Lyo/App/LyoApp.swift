import SwiftUI

@main
struct LyoApp: App {

    // Connect the AppDelegate for handling app-level events, such as push notifications.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            // The RootView now manages the app's main navigation and tab structure.
            RootView()
        }
    }
}
