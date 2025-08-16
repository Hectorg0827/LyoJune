import SwiftUI

// MARK: - ViewModel

@MainActor
final class EditProfileViewModel: ObservableObject {

    @Published var username: String
    @Published var bio: String

    private let profileService: ProfileAndSettingsServicing

    init(profile: UserProfile, profileService: ProfileAndSettingsServicing) {
        self.username = profile.username
        self.bio = profile.bio ?? ""
        self.profileService = profileService
    }

    func saveProfile() async throws {
        let request = UpdateProfileRequest(username: username, bio: bio)
        _ = try await profileService.updateProfile(request)
    }
}


// MARK: - View

struct EditProfileView: View {

    @StateObject private var viewModel: EditProfileViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: EditProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Public Information")) {
                    TextField("Username", text: $viewModel.username)
                    TextEditor(text: $viewModel.bio)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: { dismiss() })
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: saveAndDismiss)
                }
            }
        }
    }

    private func saveAndDismiss() {
        Task {
            do {
                try await viewModel.saveProfile()
                HapticManager.notify(.success)
                dismiss()
            } catch {
                // In a real app, show an alert to the user.
                HapticManager.notify(.error)
                print("Failed to save profile: \(error)")
            }
        }
    }
}
