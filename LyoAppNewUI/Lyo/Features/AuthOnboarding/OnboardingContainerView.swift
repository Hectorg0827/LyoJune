import SwiftUI

struct OnboardingContainerView: View {

    @State private var currentTab: Int = 0
    private let totalTabs = 5

    var body: some View {
        VStack(spacing: 0) {
            // Page indicator
            HStack {
                ForEach(0..<totalTabs, id: \.self) { index in
                    Capsule()
                        .fill(index == currentTab ? Color.blue : Color.gray.opacity(0.5))
                        .frame(height: 6)
                }
            }
            .padding()

            // Tab view for onboarding pages
            TabView(selection: $currentTab) {
                LegalView().tag(0)
                RoleSelectionView().tag(1)
                GoalsView().tag(2)
                PrivacyView().tag(3)
                NotificationsView().tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentTab)

            // Continue button
            Button(action: advanceToNextStep) {
                Text(currentTab == totalTabs - 1 ? "Finish" : "Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding([.horizontal, .bottom], 20)
        }
        .background(Color(.systemGroupedBackground))
        .edgesIgnoringSafeArea(.bottom)
    }

    private func advanceToNextStep() {
        if currentTab < totalTabs - 1 {
            currentTab += 1
        } else {
            // Onboarding is complete, post a notification or call a delegate method to dismiss.
            print("Onboarding finished.")
            // NotificationCenter.default.post(name: .didFinishOnboarding, object: nil)
        }
    }
}

// MARK: - Placeholder Onboarding Screens

struct LegalView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Legal").font(.largeTitle).fontWeight(.bold)
            Text("Please review our terms and conditions before continuing.")
            Spacer()
        }.padding(30)
    }
}

struct RoleSelectionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What's Your Role?").font(.largeTitle).fontWeight(.bold)
            Text("This helps us personalize your experience.")
            Spacer()
        }.padding(30)
    }
}

struct GoalsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What are your goals?").font(.largeTitle).fontWeight(.bold)
            Text("Select subjects you are interested in learning about.")
            Spacer()
        }.padding(30)
    }
}

struct PrivacyView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Privacy Settings").font(.largeTitle).fontWeight(.bold)
            Text("Control how your data is used across the app.")
            Spacer()
        }.padding(30)
    }
}

struct NotificationsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Enable Notifications").font(.largeTitle).fontWeight(.bold)
            Text("Get notified about important updates and messages.")
            Spacer()
        }.padding(30)
    }
}


#if DEBUG
struct OnboardingContainerView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingContainerView()
    }
}
#endif
