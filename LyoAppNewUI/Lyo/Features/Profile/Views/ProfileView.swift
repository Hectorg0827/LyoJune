import SwiftUI

struct ProfileView: View {

    @StateObject private var viewModel: ProfileViewModel
    @State private var isShowingEditSheet = false

    init(viewModel: ProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.viewState {
            case .loading:
                ProgressView()
            case .loaded:
                if let profile = viewModel.userProfile {
                    profileContent(for: profile)
                } else {
                    Text("Profile data is unavailable.")
                }
            case .error:
                EmptyStateView(
                    image: Image(systemName: "exclamationmark.triangle"),
                    title: "Could Not Load Profile",
                    description: "Please try again later.",
                    actionView: {
                        Button("Retry", action: viewModel.fetchProfile)
                    }
                )
            }
        }
        .onAppear(perform: viewModel.fetchProfile)
        .navigationTitle(viewModel.userProfile?.username ?? "Profile")
        .sheet(isPresented: $isShowingEditSheet) {
            // This requires creating the dependencies for the sheet's view model.
            // In a real app, a DI container would provide this.
            if let profile = viewModel.userProfile {
                let service = ProfileAndSettingsService(httpClient: buildHttpClient()) // Helper needed
                let editViewModel = EditProfileViewModel(profile: profile, profileService: service)
                EditProfileView(viewModel: editViewModel)
            }
        }
    }

    @ViewBuilder
    private func profileContent(for profile: UserProfile) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header, Stats, Bio... (as before)
                VStack {
                    AsyncImage(url: profile.profileImageURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.circle.fill").font(.system(size: 80)).foregroundColor(.secondary)
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())

                    Text("@\(profile.username)").font(.title2).bold()
                }

                HStack(spacing: 32) {
                    VStack { Text("\(profile.followerCount)").bold(); Text("Followers") }
                    VStack { Text("\(profile.followingCount)").bold(); Text("Following") }
                }
                .font(.subheadline)

                if let bio = profile.bio, !bio.isEmpty {
                    Text(bio).multilineTextAlignment(.center)
                }

                actionButton(for: profile)

                Text("User's content grid...").foregroundColor(.secondary)
            }
            .padding()
        }
        .toolbar {
            if profile.isCurrentUser {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // This should navigate to the SettingsView
                    NavigationLink(destination: settingsDestination) {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func actionButton(for profile: UserProfile) -> some View {
        if profile.isCurrentUser {
            Button("Edit Profile") {
                isShowingEditSheet = true
            }
            .buttonStyle(.bordered)
        } else {
            Button(profile.isFollowedByCurrentUser ? "Unfollow" : "Follow") {
                viewModel.toggleFollow()
            }
            .buttonStyle(profile.isFollowedByCurrentUser ? .bordered : .borderedProminent)
            .animation(.default, value: profile.isFollowedByCurrentUser)
        }
    }

    // Helper view for settings destination
    private var settingsDestination: some View {
        let service = ProfileAndSettingsService(httpClient: buildHttpClient())
        let viewModel = SettingsViewModel(settingsService: service)
        return SettingsView(viewModel: viewModel)
    }

    // Helper to build a default HTTPClient.
    private func buildHttpClient() -> HTTPClienting {
        let tempAuthService = AuthService(baseURL: AppConfig.baseURL, session: .shared, storage: KeychainStorage())
        return HTTPClient(baseURL: AppConfig.baseURL, authService: tempAuthService)
    }
}
