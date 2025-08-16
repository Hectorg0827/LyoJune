import SwiftUI

struct SettingsView: View {

    @StateObject private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            if viewModel.isLoading {
                ProgressView()
            } else if let settings = viewModel.settings {
                // We need to use a non-optional binding for the Toggles.
                // This creates a new binding that reads from the view model but
                // uses a default value if the optional is nil.
                let notificationSettings = Binding(
                    get: { settings.notifications },
                    set: { viewModel.settings?.notifications = $0 }
                )

                let privacySettings = Binding(
                    get: { settings.privacy },
                    set: { viewModel.settings?.privacy = $0 }
                )

                Section(header: Text("Notifications")) {
                    Toggle("Likes", isOn: notificationSettings.likes)
                    Toggle("Comments", isOn: notificationSettings.comments)
                    Toggle("New Followers", isOn: notificationSettings.newFollowers)
                }

                Section(header: Text("Privacy")) {
                    Toggle("Private Account", isOn: privacySettings.isPrivateAccount)
                }
            } else {
                Text("Could not load settings.")
            }
        }
        .navigationTitle("Settings")
        .onAppear(perform: viewModel.fetchSettings)
        .onDisappear {
            HapticManager.notify(.success)
            viewModel.saveSettings()
        }
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        // This requires a mock service that can return settings.
        let service = MockProfileAndSettingsService()
        let viewModel = SettingsViewModel(settingsService: service)

        // Simulate some data
        service.settingsResult = .success(.init(
            notifications: .init(likes: true, comments: true, newFollowers: false),
            privacy: .init(isPrivateAccount: false)
        ))

        return NavigationView {
            SettingsView(viewModel: viewModel)
        }
    }

    private class MockProfileAndSettingsService: ProfileAndSettingsServicing {
        var settingsResult: Result<UserSettings, APIError> = .success(.init(notifications: .init(likes: true, comments: true, newFollowers: true), privacy: .init(isPrivateAccount: false)))
        func getProfile(for userId: UUID) async throws -> UserProfile { fatalError() }
        func updateProfile(_ updateRequest: UpdateProfileRequest) async throws -> UserProfile { fatalError() }
        func followUser(userId: UUID) async throws {}
        func unfollowUser(userId: UUID) async throws {}
        func getSettings() async throws -> UserSettings { try settingsResult.get() }
        func updateSettings(_ settings: UserSettings) async throws -> UserSettings { settings }
        func reportContent(_ reportRequest: ReportContentRequest) async throws {}
    }
}
#endif
