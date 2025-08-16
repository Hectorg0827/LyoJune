import SwiftUI

@main
struct LyoApp: App {

    // Connect the AppDelegate for handling app-level events, such as push notifications.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            // This is the root view of the application.
            // It will be replaced by the main app router or tab controller.
            // For now, it shows a placeholder text.
            Text("Lyo App - Coming Soon!")
                .font(.largeTitle)
        }
    }
}
