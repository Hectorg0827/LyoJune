import XCTest

final class AuthSmokeTest: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()

        // We can pass launch arguments to the app to configure it for testing.
        // For example, to tell it to use a mock backend or to clear user data.
        app.launchArguments = ["-testing"]
    }

    /// A simple smoke test to ensure the app launches and displays the initial authentication screen.
    func test_appLaunches_andShowsAuthScreen() {
        app.launch()

        // Verify that the main welcome text is visible.
        let welcomeText = app.staticTexts["Welcome to Lyo"]
        XCTAssertTrue(welcomeText.waitForExistence(timeout: 5), "The welcome text should be visible on launch.")

        // Verify that the Sign in with Apple button exists.
        // The accessibility identifier for this button is determined by the system.
        // A common approach is to look for a button whose label begins with "Sign in with Apple".
        let appleButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Sign in with Apple'")).firstMatch
        XCTAssertTrue(appleButton.waitForExistence(timeout: 5), "The 'Sign in with Apple' button should be visible.")

        // Verify the other buttons exist by their label
        let googleButton = app.buttons["Sign in with Google"]
        XCTAssertTrue(googleButton.exists, "The Google sign-in button should exist.")

        let metaButton = app.buttons["Sign in with Meta"]
        XCTAssertTrue(metaButton.exists, "The Meta sign-in button should exist.")
    }
}
