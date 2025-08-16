import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var userProfile: UserProfile?
    @Published private(set) var viewState: ViewState = .loading

    enum ViewState {
        case loading, loaded, error
    }

    // MARK: - Private Properties

    private let userId: UUID
    private let profileService: ProfileAndSettingsServicing

    // MARK: - Initialization

    init(userId: UUID, profileService: ProfileAndSettingsServicing) {
        self.userId = userId
        self.profileService = profileService
    }

    // MARK: - Public Intent Methods

    func fetchProfile() {
        viewState = .loading
        Task {
            do {
                let profile = try await profileService.getProfile(for: userId)
                self.userProfile = profile
                self.viewState = .loaded
            } catch {
                self.viewState = .error
            }
        }
    }

    func toggleFollow() {
        guard let profile = userProfile else { return }

        // Optimistic UI update
        let originalFollowState = profile.isFollowedByCurrentUser
        userProfile?.isFollowedByCurrentUser.toggle()

        Task {
            do {
                if originalFollowState {
                    try await profileService.unfollowUser(userId: userId)
                } else {
                    try await profileService.followUser(userId: userId)
                }
                // Optionally, refetch the profile to get the new follower count
                fetchProfile()
            } catch {
                // Revert optimistic update on failure
                userProfile?.isFollowedByCurrentUser = originalFollowState
            }
        }
    }
}
