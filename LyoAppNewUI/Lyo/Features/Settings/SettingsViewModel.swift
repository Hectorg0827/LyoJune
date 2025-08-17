import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var settings: UserSettings?
    @Published private(set) var isLoading: Bool = false

    // MARK: - Private Properties

    private let settingsService: ProfileAndSettingsServicing

    // MARK: - Initialization

    init(settingsService: ProfileAndSettingsServicing) {
        self.settingsService = settingsService
    }

    // MARK: - Public Intent Methods

    func fetchSettings() {
        isLoading = true
        Task {
            do {
                self.settings = try await settingsService.getSettings()
            } catch {
                // In a real app, show an error.
                print("Failed to fetch settings: \(error)")
            }
            isLoading = false
        }
    }

    func saveSettings() {
        guard let settings = settings else { return }

        Task {
            do {
                _ = try await settingsService.updateSettings(settings)
            } catch {
                // In a real app, show an error and potentially revert the UI state.
                print("Failed to save settings: \(error)")
            }
        }
    }
}
