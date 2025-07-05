import SwiftUI

struct GamificationOverlay: View {
    @StateObject private var gamificationService = GamificationAPIService.shared
    @State private var showingAchievement = false
    @State private var showingLevelUp = false
    @State private var showingStreakBonus = false
    @State private var currentNotification: GamificationNotification?
    @State private var animationScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // CDAchievement Popup
            if showingCDAchievement, let notification = currentNotification {
                CDAchievementPopup(notification: notification) {
                    dismissNotification()
                }
                .transition(.scale.combined(with: .opacity))
                .zIndex(1000)
            }
            
            // Level Up Popup
            if showingLevelUp, let notification = currentNotification {
                LevelUpPopup(notification: notification) {
                    dismissNotification()
                }
                .transition(.scale.combined(with: .opacity))
                .zIndex(1000)
            }
            
            // Streak Bonus Popup
            if showingStreakBonus, let notification = currentNotification {
                StreakBonusPopup(notification: notification) {
                    dismissNotification()
                }
                .transition(.scale.combined(with: .opacity))
                .zIndex(1000)
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingCDAchievement)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingLevelUp)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingStreakBonus)
        .onReceive(NotificationCenter.default.publisher(for: .achievementUnlocked)) { notification in
            if let achievement = notification.object as? CDAchievement {
                showCDAchievementNotification(achievement)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .levelUp)) { notification in
            if let levelData = notification.object as? LevelUpData {
                showLevelUpNotification(levelData)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .streakBonus)) { notification in
            if let streakData = notification.object as? StreakData {
                showStreakBonusNotification(streakData)
            }
        }
    }
    
    private func showAchievementNotification(_ achievement: CDAchievement) {
        currentNotification = .achievement(achievement)
        showingCDAchievement = true
        
        // Auto-dismiss after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            dismissNotification()
        }
    }
    
    private func showLevelUpNotification(_ levelData: LevelUpData) {
        currentNotification = .levelUp(levelData)
        showingLevelUp = true
        
        // Auto-dismiss after 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            dismissNotification()
        }
    }
    
    private func showStreakBonusNotification(_ streakData: StreakData) {
        currentNotification = .streakBonus(streakData)
        showingStreakBonus = true
        
        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            dismissNotification()
        }
    }
    
    private func dismissNotification() {
        showingCDAchievement = false
        showingLevelUp = false
        showingStreakBonus = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentNotification = nil
        }
    }
}

// MARK: - CDAchievement Popup
struct AchievementPopup: View {
    let notification: GamificationNotification
    let onDismiss: () -> Void
    
    @State private var particleSystem = ParticleSystem()
    
    var body: some View {
        if case .achievement(let achievement) = notification {
            VStack(spacing: 16) {
                // CDAchievement Icon with Particle Effect
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay {
                            ParticleView(system: particleSystem)
                        }
                    
                    AsyncImage(url: URL(string: achievement.iconURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.yellow)
                    }
                    .frame(width: 60, height: 60)
                }
                
                VStack(spacing: 8) {
                    Text("🎉 CDAchievement Unlocked!")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(achievement.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text(achievement.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("+\(achievement.xpReward) XP")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(12)
                }
                
                Button("Awesome!") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 40)
            .onAppear {
                particleSystem.startEmission()
            }
        }
    }
}

// MARK: - Level Up Popup
struct LevelUpPopup: View {
    let notification: GamificationNotification
    let onDismiss: () -> Void
    
    @State private var showingRays = false
    
    var body: some View {
        if case .levelUp(let levelData) = notification {
            VStack(spacing: 20) {
                ZStack {
                    // Animated rays
                    if showingRays {
                        ForEach(0..<8, id: \.self) { index in
                            Rectangle()
                                .fill(Color.yellow.opacity(0.6))
                                .frame(width: 4, height: 60)
                                .offset(y: -30)
                                .rotationEffect(.degrees(Double(index) * 45))
                                .animation(
                                    .easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.1),
                                    value: showingRays
                                )
                        }
                    }
                    
                    // Level circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay {
                            VStack {
                                Text("LEVEL")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("\(levelData.newLevel)")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        }
                }
                
                VStack(spacing: 8) {
                    Text("🎊 Level Up!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("You've reached level \(levelData.newLevel)!")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("Keep up the great work!")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 8) {
                    HStack {
                        Text("XP Earned:")
                        Spacer()
                        Text("+\(levelData.xpEarned)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("New Rewards:")
                        Spacer()
                        Text("\(levelData.newRewards.count) items")
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Button("Continue") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 40)
            .onAppear {
                showingRays = true
            }
        }
    }
}

// MARK: - Streak Bonus Popup
struct StreakBonusPopup: View {
    let notification: GamificationNotification
    let onDismiss: () -> Void
    
    var body: some View {
        if case .streakBonus(let streakData) = notification {
            VStack(spacing: 16) {
                // Fire emoji animation
                Text("🔥")
                    .font(.system(size: 80))
                    .scaleEffect(1.2)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: true)
                
                VStack(spacing: 8) {
                    Text("Streak Bonus!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(streakData.days) Day Streak")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text("You're on fire! Keep it up!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                HStack {
                    Image(systemName: "multiply")
                        .foregroundColor(.orange)
                    Text("\(String(format: "%.1f", streakData.multiplier))x XP Multiplier")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(12)
                
                Button("Keep Going!") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Supporting Models
enum GamificationNotification {
    case achievement(Achievement)
    case levelUp(LevelUpData)
    case streakBonus(StreakData)
}

struct LevelUpData {
    let newLevel: Int
    let xpEarned: Int
    let newRewards: [String]
}

struct StreakData {
    let days: Int
    let multiplier: Double
}

// MARK: - Particle System
class ParticleSystem: ObservableObject {
    @Published var particles: [Particle] = []
    
    func startEmission() {
        for _ in 0..<20 {
            let particle = Particle(
                position: CGPoint(x: 50, y: 50),
                velocity: CGPoint(
                    x: Double.random(in: -100...100),
                    y: Double.random(in: -100...100)
                ),
                life: Double.random(in: 1...3),
                color: [.yellow, .orange, .purple, .blue].randomElement() ?? .yellow
            )
            particles.append(particle)
        }
        
        // Remove particles after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.particles.removeAll()
        }
    }
}

struct Particle {
    let position: CGPoint
    let velocity: CGPoint
    let life: Double
    let color: Color
}

struct ParticleView: View {
    @ObservedObject var system: ParticleSystem
    
    var body: some View {
        ForEach(Array(system.particles.enumerated()), id: \.offset) { index, particle in
            Circle()
                .fill(particle.color)
                .frame(width: 6, height: 6)
                .position(particle.position)
                .opacity(0.8)
                .animation(
                    .linear(duration: particle.life),
                    value: system.particles.count
                )
        }
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
    static let levelUp = Notification.Name("levelUp")
    static let streakBonus = Notification.Name("streakBonus")
}
