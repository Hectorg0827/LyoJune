import XCTest
@testable import LyoApp

@MainActor
final class SettingsViewModelTests: XCTestCase {

    private var sut: SettingsViewModel!
    private var mockService: MockProfileAndSettingsService!

    override func setUp() {
        super.setUp()
        mockService = MockProfileAndSettingsService()
        sut = SettingsViewModel(settingsService: mockService)
    }

    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_fetchSettings_onSuccess_populatesSettings() async {
        // Given
        let settings = UserSettings.placeholder
        mockService.settingsResult = .success(settings)

        // When
        sut.fetchSettings()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockService.getSettingsCallCount, 1)
        XCTAssertEqual(sut.settings, settings)
        XCTAssertFalse(sut.isLoading)
    }

    func test_saveSettings_callsUpdateSettings() async {
        // Given
        let settings = UserSettings.placeholder
        sut.settings = settings
        mockService.updateSettingsResult = .success(settings)

        // When
        sut.saveSettings()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockService.updateSettingsCallCount, 1)
    }

    func test_saveSettings_withNilSettings_doesNotCallService() {
        // Given
        sut.settings = nil

        // When
        sut.saveSettings()

        // Then
        XCTAssertEqual(mockService.updateSettingsCallCount, 0)
    }
}

extension UserSettings {
    static var placeholder: UserSettings {
        .init(
            notifications: .init(likes: true, comments: false, newFollowers: true),
            privacy: .init(isPrivateAccount: false)
        )
    }
}
