import SwiftUI
import Foundation

// MARK: - Phase 2 Enhanced Profile View
// Modern, personalized, and engaging profile experience

struct ProfileView: View {
    @EnvironmentObject var authService: EnhancedAuthService
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingSettings = false
    @State private var showingEditProfile = false
    @State private var profileImageScale: CGFloat = 1.0
    @State private var headerOffset: CGFloat = 0
    @State private var isAnimating = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced background with user-themed colors
                modernBackground
                    .ignoresSafeArea()
                
                // Main profile content
                profileContent
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                startProfileAnimation()
                Task {
                    await viewModel.loadData()
                }
            }
        }
    }
    
    // MARK: - Enhanced UI Components
    
    @ViewBuilder
    private var modernBackground: some View {
        ZStack {
            // Dynamic user-themed gradient
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: userThemeColor.opacity(0.2), location: 0.0),
                    .init(color: DesignTokens.Colors.background, location: 0.4),
                    .init(color: DesignTokens.Colors.surface, location: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle pattern overlay
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.03)
        }
    }
    
    @ViewBuilder
    private var profileContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Enhanced profile header
                enhancedProfileHeader
                    .padding(.top, DesignTokens.Spacing.xl)
                
                // Modern stats section
                modernStatsSection
                    .padding(.top, DesignTokens.Spacing.lg)
                
                // Enhanced achievements section
                enhancedAchievementsSection
                    .padding(.top, DesignTokens.Spacing.lg)
                
                // Modern activity section
                modernActivitySection
                    .padding(.top, DesignTokens.Spacing.lg)
                
                // Enhanced settings section
                enhancedSettingsSection
                    .padding(.top, DesignTokens.Spacing.lg)
                    .padding(.bottom, DesignTokens.Spacing.xxl)
            }
        }
        .refreshable {
            await viewModel.refreshData()
        }
    }
    
    @ViewBuilder
    private var enhancedProfileHeader: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Profile image with modern design
            profileImageSection
            
            // User info
            userInfoSection
            
            // Action buttons
            actionButtonsSection
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
    
    private var profileImageSection: some View {
        ZStack {
            // Background glow effect
            Circle()
                .fill(userThemeColor.opacity(0.3))
                .frame(width: 140, height: 140)
                .blur(radius: 20)
                .scaleEffect(profileImageScale)
                .animation(
                    DesignTokens.Animations.pulse,
                    value: profileImageScale
                )
            
            // Profile image
            AsyncImage(url: URL(string: authService.currentUser?.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                userThemeColor,
                                userThemeColor.opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    )
            }
            .frame(width: 120, height: 120)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                userThemeColor,
                                DesignTokens.Colors.accent
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
            )
            .shadow(
                color: userThemeColor.opacity(0.3),
                radius: 15,
                x: 0,
                y: 8
            )
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .animation(
                DesignTokens.Animations.spring.delay(0.2),
                value: isAnimating
            )
            
            // Edit button
            Button(action: {
                showingEditProfile = true
                HapticManager.shared.lightImpact()
            }) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(DesignTokens.Colors.primary)
                    )
                    .shadow(
                        color: DesignTokens.Colors.primary.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            }
            .offset(x: 40, y: 40)
            .scaleEffect(isAnimating ? 1.0 : 0.5)
            .animation(
                DesignTokens.Animations.springBouncy.delay(0.4),
                value: isAnimating
            )
        }
    }
    
    private var userInfoSection: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Text(authService.currentUser?.displayName ?? "Unknown User")
                .font(DesignTokens.Typography.headlineLarge)
                .fontWeight(.bold)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .opacity(isAnimating ? 1.0 : 0.3)
                .animation(
                    DesignTokens.Animations.easeInOut.delay(0.6),
                    value: isAnimating
                )
            
            if let username = authService.currentUser?.username {
                Text("@\(username)")
                    .font(DesignTokens.Typography.bodyLarge)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .opacity(isAnimating ? 1.0 : 0.3)
                    .animation(
                        DesignTokens.Animations.easeInOut.delay(0.7),
                        value: isAnimating
                    )
            }
            
            if let bio = authService.currentUser?.bio {
                Text(bio)
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    .opacity(isAnimating ? 1.0 : 0.3)
                    .animation(
                        DesignTokens.Animations.easeInOut.delay(0.8),
                        value: isAnimating
                    )
            }
        }
    }
    
    private var actionButtonsSection: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            ModernButton(
                title: "Edit Profile",
                style: .primary,
                size: .medium
            ) {
                showingEditProfile = true
            }
            
            ModernButton(
                title: "Share",
                style: .secondary,
                size: .medium,
                action: {
                    shareProfile()
                }
            )
        }
        .opacity(isAnimating ? 1.0 : 0.3)
        .offset(y: isAnimating ? 0 : 20)
        .animation(
            DesignTokens.Animations.spring.delay(1.0),
            value: isAnimating
        )
    }
    
    @ViewBuilder
    private var modernStatsSection: some View {
        if let stats = viewModel.userStats {
            VStack(spacing: DesignTokens.Spacing.md) {
                HStack {
                    Text("Your Stats")
                        .font(DesignTokens.Typography.headlineSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Spacer()
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignTokens.Spacing.md) {
                        modernStatCard(
                            title: "Courses Completed",
                            value: "\(stats.coursesCompleted)",
                            icon: "play.circle.fill",
                            color: DesignTokens.Colors.primary
                        )
                        
                        modernStatCard(
                            title: "Study Time",
                            value: "\(Int(stats.totalStudyTime / 3600))h",
                            icon: "clock.fill",
                            color: DesignTokens.Colors.accent
                        )
                        
                        modernStatCard(
                            title: "Streak",
                            value: "\(stats.currentStreak) days",
                            icon: "flame.fill",
                            color: DesignTokens.Colors.warning
                        )
                        
                        modernStatCard(
                            title: "Total Points",
                            value: "\(stats.totalPoints)",
                            icon: "star.fill",
                            color: DesignTokens.Colors.success
                        )
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                }
            }
            .opacity(isAnimating ? 1.0 : 0.3)
            .offset(y: isAnimating ? 0 : 30)
            .animation(
                DesignTokens.Animations.spring.delay(1.2),
                value: isAnimating
            )
        }
    }
    
    @ViewBuilder
    private func modernStatCard(
        title: String,
        value: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(DesignTokens.Typography.headlineSmall)
                .fontWeight(.bold)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text(title)
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignTokens.Spacing.lg)
        .frame(minWidth: 100)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .fill(DesignTokens.Colors.backgroundSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .shadow(
            color: color.opacity(0.1),
            radius: 10,
            x: 0,
            y: 4
        )
    }
    
    @ViewBuilder
    private var enhancedAchievementsSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            HStack {
                Text("Achievements")
                    .font(DesignTokens.Typography.headlineSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to achievements
                }
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.primary)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(viewModel.achievements.prefix(5), id: \.id) { achievement in
                        modernAchievementCard(achievement: achievement)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
            }
        }
        .opacity(isAnimating ? 1.0 : 0.3)
        .offset(y: isAnimating ? 0 : 40)
        .animation(
            DesignTokens.Animations.spring.delay(1.4),
            value: isAnimating
        )
    }
    
    @ViewBuilder
    private func modernAchievementCard(achievement: Achievement) -> some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                DesignTokens.Colors.accent,
                                DesignTokens.Colors.secondary
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievementIcon(for: achievement))
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Text(achievement.title)
                .font(DesignTokens.Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 80)
    }
    
    @ViewBuilder
    private var modernActivitySection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            HStack {
                Text("Recent Activity")
                    .font(DesignTokens.Typography.headlineSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            
            LazyVStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(viewModel.recentActivities.prefix(3), id: \.id) { activity in
                    modernActivityCard(activity: activity)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
        }
        .opacity(isAnimating ? 1.0 : 0.3)
        .offset(y: isAnimating ? 0 : 50)
        .animation(
            DesignTokens.Animations.spring.delay(1.6),
            value: isAnimating
        )
    }
    
    @ViewBuilder
    private func modernActivityCard(activity: Activity) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Activity icon
            Image(systemName: iconName(for: String(describing: activity.type)))
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(DesignTokens.Colors.accent)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(DesignTokens.Colors.accent.opacity(0.1))
                )
            
            // Activity details
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(activity.title)
                    .font(DesignTokens.Typography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text(activity.description)
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Timestamp
            Text(timeAgoString(from: activity.timestamp))
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                .fill(DesignTokens.Colors.backgroundSecondary)
        )
    }
    
    @ViewBuilder
    private var enhancedSettingsSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            HStack {
                Text("Settings")
                    .font(DesignTokens.Typography.headlineSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            
            VStack(spacing: DesignTokens.Spacing.xs) {
                modernSettingsRow(
                    icon: "gear",
                    title: "Preferences",
                    action: { showingSettings = true }
                )
                
                modernSettingsRow(
                    icon: "bell",
                    title: "Notifications",
                    action: { /* Handle notifications */ }
                )
                
                modernSettingsRow(
                    icon: "lock",
                    title: "Privacy",
                    action: { /* Handle privacy */ }
                )
                
                modernSettingsRow(
                    icon: "questionmark.circle",
                    title: "Help & Support",
                    action: { /* Handle help */ }
                )
                
                modernSettingsRow(
                    icon: "rectangle.portrait.and.arrow.right",
                    title: "Sign Out",
                    isDestructive: true,
                    action: {
                        Task {
                            await authService.logout()
                        }
                        HapticManager.shared.mediumImpact()
                    }
                )
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
        }
        .opacity(isAnimating ? 1.0 : 0.3)
        .offset(y: isAnimating ? 0 : 60)
        .animation(
            DesignTokens.Animations.spring.delay(1.8),
            value: isAnimating
        )
    }
    
    @ViewBuilder
    private func modernSettingsRow(
        icon: String,
        title: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isDestructive ? DesignTokens.Colors.error : DesignTokens.Colors.textSecondary)
                    .frame(width: 20)
                
                Text(title)
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(isDestructive ? DesignTokens.Colors.error : DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                    .fill(DesignTokens.Colors.backgroundSecondary)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Computed Properties
    
    private var userThemeColor: Color {
        // Generate a theme color based on user preferences or default
        return DesignTokens.Colors.primary
    }
    
    // MARK: - Private Methods
    
    private func startProfileAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                isAnimating = true
            }
        }
        
        // Start profile image scale animation
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(DesignTokens.Animations.easeInOut) {
                profileImageScale = profileImageScale == 1.0 ? 1.1 : 1.0
            }
        }
    }
    
    private func shareProfile() {
        // Implement profile sharing
        HapticManager.shared.lightImpact()
    }
}

#Preview {
    ProfileView()
        .environmentObject(EnhancedAuthService.shared)
        .preferredColorScheme(.dark)
}

struct ProfileHeader: View {
    let user: User?
    @Binding var showingEditProfile: Bool

    var body: some View {
        VStack(spacing: 16) {
            profileImage
            userInfo
            editProfileButton
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Material.ultraThin)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private var profileImage: some View {
        Circle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [.blue, .purple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Group {
                    if let user = user {
                        Text(String(user.displayName.prefix(1)))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "person")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                    }
                }
            )
            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
    }

    private var userInfo: some View {
        VStack(spacing: 8) {
            Text(user?.displayName ?? "User")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(user?.email ?? "user@example.com")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
            if let createdAt = user?.createdAt {
                Text("Joined \(createdAt)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    private var editProfileButton: some View {
        Button(action: {
            showingEditProfile = true
        }) {
            Text("Edit Profile")
                .fontWeight(.semibold)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Material.ultraThin)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
                .foregroundColor(.white)
        }
    }
}

struct ProfileStatsSection: View {
    let stats: LearningStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Learning Stats")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ProfileStatCard(
                    title: "Total Courses",
                    value: "\(stats.coursesCompleted + stats.coursesInProgress)",
                    icon: "book",
                    color: .blue
                )
                
                ProfileStatCard(
                    title: "Completed",
                    value: "\(stats.coursesCompleted)",
                    icon: "checkmark.circle",
                    color: .green
                )
                
                ProfileStatCard(
                    title: "Study Hours",
                    value: "\(Int(stats.totalStudyTime / 3600))",
                    icon: "clock",
                    color: .orange
                )
                
                ProfileStatCard(
                    title: "Current Streak",
                    value: "\(stats.currentStreak)",
                    icon: "flame",
                    color: .red
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Material.ultraThin)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct ProfileStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Material.ultraThin)
        )
    }
}

struct ProfileAchievementsSection: View {
    let achievements: [Achievement]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Achievements")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to achievements view
                }
                .foregroundColor(.blue)
                .font(.caption)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(achievements.prefix(5)) { achievement in
                        AchievementBadge(achievement: achievement)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Material.ultraThin)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct AchievementBadge: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(rarityColor(for: achievement.rarity).gradient)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: achievementIcon(for: achievement))
                        .font(.title2)
                        .foregroundColor(.white)
                )
            
            Text(achievement.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 80)
    }
}

struct ProfileActivitySection: View {
    let activities: [RecentActivity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            ForEach(activities.prefix(3)) { activity in
                ActivityItem(activity: activity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Material.ultraThin)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct ActivityItem: View {
    let activity: RecentActivity
    
    var body: some View {
        HStack {
            Circle()
                .fill(activityColor(for: String(describing: activity.type)))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: iconName(for: String(describing: activity.type)))
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(DesignTokens.Typography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(activity.description)
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text(timeAgoString(from: activity.timestamp))
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

struct ProfileSettingsSection: View {
    @Binding var showingSettings: Bool
    let onSignOut: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            SettingsRow(
                title: "Settings",
                icon: "gearshape",
                action: { showingSettings = true }
            )
            
            SettingsRow(
                title: "Privacy",
                icon: "lock",
                action: {}
            )
            
            SettingsRow(
                title: "Help & Support",
                icon: "questionmark.circle",
                action: {}
            )
            
            SettingsRow(
                title: "Sign Out",
                icon: "arrow.right.square",
                color: .red,
                action: onSignOut
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Material.ultraThin)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct SettingsRow: View {
    let title: String
    let icon: String
    var color: Color = .white
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color.opacity(0.8))
                    .frame(width: 20)
                
                Text(title)
                    .foregroundColor(color)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(color.opacity(0.5))
                    .font(.caption)
            }
            .padding(.vertical, 8)
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                
                Text("Settings View")
                    .font(.title)
                    .foregroundColor(.white)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var displayName = ""
    @State private var bio = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                
                VStack(spacing: 20) {
                    Text("Edit Profile")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    VStack(spacing: 16) {
                        GlassFormField(
                            title: "Display Name",
                            text: $displayName,
                            placeholder: "Enter your display name",
                            icon: "person"
                        )
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bio")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextEditor(text: $bio)
                                .foregroundColor(.white)
                                .scrollContentBackground(.hidden)
                                .frame(height: 100)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Material.ultraThin)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Material.ultraThin, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Shared Helper Functions

private func iconName(for activityType: String) -> String {
    switch activityType.lowercased() {
    case "course":
        return "play.circle"
    case "quiz":
        return "questionmark.circle"
    case "achievement":
        return "star.circle"
    case "study":
        return "book.circle"
    default:
        return "circle"
    }
}

private func rarityColor(for rarity: AchievementRarity) -> Color {
    switch rarity {
    case .common:
        return .gray
    case .uncommon:
        return .green
    case .rare:
        return .blue
    case .epic:
        return .purple
    case .legendary:
        return .orange
    }
}

private func activityColor(for activityType: String) -> Color {
    switch activityType.lowercased() {
    case "course":
        return DesignTokens.Colors.primary
    case "quiz":
        return DesignTokens.Colors.accent
    case "achievement":
        return DesignTokens.Colors.success
    case "study":
        return DesignTokens.Colors.info
    default:
        return DesignTokens.Colors.neutral500
    }
}

private func achievementIcon(for achievement: Achievement) -> String {
    switch achievement.category {
    case .learning:
        return "book.circle"
    case .social:
        return "person.2.circle"
    case .streak:
        return "flame"
    case .completion:
        return "checkmark.circle"
    case .engagement:
        return "bolt.circle"
    case .special:
        return "star.circle"
    }
}

private func timeAgoString(from date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.dateTimeStyle = .named
    formatter.unitsStyle = .full
    return formatter.localizedString(for: date, relativeTo: Date())
}
