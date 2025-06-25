import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: LyoAuthService
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingSettings = false
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            ZStack {
                GlassBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile header
                        ProfileHeader(
                            user: authService.currentUser,
                            showingEditProfile: $showingEditProfile
                        )
                        
                        // Stats section
                        if let stats = authService.currentUser?.learningStats {
                            ProfileStatsSection(stats: stats)
                        }
                        
                        // Achievements section
                        ProfileAchievementsSection(achievements: viewModel.achievements)
                        
                        // Recent activity
                        ProfileActivitySection(activities: viewModel.recentActivities)
                        
                        // Settings section
                        ProfileSettingsSection(
                            showingSettings: $showingSettings,
                            onSignOut: {
                                authService.signOut()
                            }
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Material.ultraThin, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
        }
        .onAppear {
            Task {
                await viewModel.loadData()
            }
        }
    }
}

struct ProfileHeader: View {
    let user: LyoAuthService.User?
    @Binding var showingEditProfile: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile image
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
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
            
            // User info
            VStack(spacing: 8) {
                Text(user?.displayName ?? "User")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(user?.email ?? "user@example.com")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                
                if let joinedDate = user?.joinedDate {
                    Text("Joined \(joinedDate, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Edit profile button
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
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

struct ProfileStatsSection: View {
    let stats: LyoAuthService.LearningStats
    
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
                    value: "\(stats.totalCourses)",
                    icon: "book",
                    color: .blue
                )
                
                ProfileStatCard(
                    title: "Completed",
                    value: "\(stats.completedCourses)",
                    icon: "checkmark.circle",
                    color: .green
                )
                
                ProfileStatCard(
                    title: "Study Hours",
                    value: "\(Int(stats.totalHours))",
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
                .fill(achievement.color.gradient)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: achievement.icon)
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
                .fill(activity.type.color)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: activity.type.icon)
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(activity.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text(activity.timeAgo)
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
                GlassBackground()
                
                Text("Settings View")
                    .font(.title)
                    .foregroundColor(.white)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Material.ultraThin, for: .navigationBar)
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
                GlassBackground()
                
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

#Preview {
    ProfileView()
        .environmentObject(LyoAuthService())
}