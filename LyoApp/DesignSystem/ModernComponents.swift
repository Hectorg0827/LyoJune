import SwiftUI
import Foundation

// Import models to use CDInstructor, CDUserProgress, etc.
// Note: These imports provide access to canonical types from Core/Models

// Use course from CDCourseModels to avoid conflicts

// MARK: - Modern Enhanced Components
// Phase 2: Integrated modern components with animations, haptics, and loading states





// MARK: - Enhanced Floating Action Button
struct EnhancedFloatingActionButton: View {
    let icon: String
    let action: () -> Void
    let size: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    
    @State private var isPressed = false
    @State private var isVisible = false
    @State private var rotation: Double = 0
    
    init(
        icon: String,
        size: CGFloat = 56,
        backgroundColor: Color = DesignTokens.Colors.primary,
        foregroundColor: Color = DesignTokens.Colors.onPrimary,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            HapticManager.shared.selectionFeedback()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                rotation += 360
            }
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundColor(foregroundColor)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(backgroundColor)
                        .shadow(
                            color: .black.opacity(0.3),
                            radius: isPressed ? 8 : 12,
                            x: 0,
                            y: isPressed ? 4 : 6
                        )
                )
                .scaleEffect(isPressed ? 0.9 : (isVisible ? 1.0 : 0.8))
                .rotationEffect(.degrees(rotation))
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
            if pressing {
                HapticManager.shared.selectionFeedback()
            }
        }, perform: {})
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3)) {
                isVisible = true
            }
        }
        .accessibilityLabel("Floating action button")
        .accessibilityHint("Double tap to perform main action")
    }
}

// MARK: - Modern Interactive Card
struct ModernInteractiveCard<Content: View>: View {
    let content: Content
    let onTap: (() -> Void)?
    
    @State private var isPressed = false
    @State private var isVisible = false
    
    init(onTap: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.onTap = onTap
        self.content = content()
    }
    
    var body: some View {
        Button(action: {
            onTap?()
            HapticManager.shared.selectionFeedback()
        }) {
            content
                .padding(DesignTokens.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.card)
                        .fill(DesignTokens.Colors.surface)
                        .shadow(
                            color: .black.opacity(0.1),
                            radius: isPressed ? 2 : 8,
                            x: 0,
                            y: isPressed ? 1 : 4
                        )
                )
                .scaleEffect(isPressed ? 0.98 : (isVisible ? 1.0 : 0.9))
                .opacity(isVisible ? 1.0 : 0.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(onTap == nil)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Enhanced Learning CDCourse Card
struct EnhancedCourseCard: View {
    let course: Course
    let isLoading: Bool
    let onTap: () -> Void
    
    @State private var imageLoaded = false
    
    var body: some View {
        ProgressiveLoadingView(isLoading: isLoading) {
            // Loaded content
            ModernInteractiveCard(onTap: onTap) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    // CDCourse image with progressive loading
                    GeometryReader { geometry in
                        AsyncImage(url: URL(string: course.thumbnail?.url ?? "https://via.placeholder.com/300x200")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: 120)
                                .clipped()
                                .onAppear {
                                    withAnimation(.easeIn) {
                                        imageLoaded = true
                                    }
                                }
                        } placeholder: {
                            Rectangle()
                                .fill(DesignTokens.Colors.neutral200)
                                .shimmer()
                                .frame(height: 120)
                        }
                    }
                    .frame(height: 120)
                    .cornerRadius(DesignTokens.BorderRadius.md)
                    
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        // CDCourse title
                        Text(course.title)
                            .font(DesignTokens.Typography.titleMedium)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .lineLimit(2)
                            .smoothAppear(delay: 0.1)
                        
                        // CDCourse description
                        Text(course.description)
                            .font(DesignTokens.Typography.bodySmall)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .lineLimit(3)
                            .smoothAppear(delay: 0.2)
                        
                        // CDCourse metadata
                        HStack {
                            // CDInstructor info
                            HStack(spacing: DesignTokens.Spacing.xs) {
                                AsyncImage(url: course.instructor.avatarURL) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Circle()
                                        .fill(DesignTokens.Colors.neutral300)
                                }
                                .frame(width: 24, height: 24)
                                .clipShape(Circle())
                                
                                Text(course.instructor.name)
                                    .font(DesignTokens.Typography.labelSmall)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            // Duration
                            Text(formatDuration(course.duration))
                                .font(DesignTokens.Typography.labelSmall)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        .smoothAppear(delay: 0.3)
                        
                        // Progress bar (if enrolled) - Temporarily commented out due to type conflicts
                        // TODO: Fix CDCourse type to include userProgress property
                        /*
                        if let progress = course.userProgress {
                            ProgressBar(
                                progress: progress.completionPercentage,
                                height: 4,
                                backgroundColor: DesignTokens.Colors.neutral200,
                                foregroundColor: DesignTokens.Colors.primary
                            )
                            .smoothAppear(delay: 0.4)
                        }
                        */
                    }
                }
            }
        } loadingContent: {
            // Loading skeleton
            SkeletonLayouts.courseCard
        }
    }
}

// MARK: - Modern Progress Bar
struct ProgressBar: View {
    let progress: Double
    let height: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    
    @State private var animatedProgress: Double = 0
    
    init(
        progress: Double,
        height: CGFloat = 8,
        backgroundColor: Color = DesignTokens.Colors.neutral200,
        foregroundColor: Color = DesignTokens.Colors.primary
    ) {
        self.progress = progress
        self.height = height
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(backgroundColor)
                    .frame(height: height)
                
                // Progress
                Rectangle()
                    .fill(foregroundColor)
                    .frame(
                        width: geometry.size.width * animatedProgress,
                        height: height
                    )
            }
        }
        .frame(height: height)
        .cornerRadius(height / 2)
        .onAppear {
            withAnimation(.easeOut.delay(0.5)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newProgress in
            withAnimation(.easeOut) {
                animatedProgress = newProgress
            }
        }
    }
}

// MARK: - Enhanced Feed CDPost Card
struct EnhancedFeedPost: View {
    let post: Post
    let isLoading: Bool
    let onLike: () -> Void
    let onComment: () -> Void
    let onShare: () -> Void
    
    @State private var isLiked = false
    @State private var likeScale: CGFloat = 1.0
    
    var body: some View {
        ProgressiveLoadingView(isLoading: isLoading) {
            // Loaded content
            ModernInteractiveCard {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    // Author header
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        AsyncImage(url: URL(string: post.author.avatarURL ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(DesignTokens.Colors.neutral300)
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(post.author.displayName)
                                .font(DesignTokens.Typography.labelMedium)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                            
                            Text(post.formattedTimestamp)
                                .font(DesignTokens.Typography.labelSmall)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .smoothAppear(delay: 0.1)
                    
                    // CDPost content
                    Text(post.content)
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .smoothAppear(delay: 0.2)
                    
                    // Media content (if available)
                    if let imageURL = post.imageURL {
                        AsyncImage(url: URL(string: imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxHeight: 200)
                                .clipped()
                                .cornerRadius(DesignTokens.BorderRadius.md)
                        } placeholder: {
                            Rectangle()
                                .fill(DesignTokens.Colors.neutral200)
                                .frame(height: 200)
                                .cornerRadius(DesignTokens.BorderRadius.md)
                                .shimmer()
                        }
                        .smoothAppear(delay: 0.3)
                    }
                    
                    // Action buttons
                    HStack(spacing: DesignTokens.Spacing.lg) {
                        // Like button
                        HapticButton(hapticType: .lightImpact, action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                isLiked.toggle()
                                likeScale = 1.3
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    likeScale = 1.0
                                }
                            }
                            
                            onLike()
                        }) {
                            HStack(spacing: DesignTokens.Spacing.xs) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .foregroundColor(isLiked ? .red : DesignTokens.Colors.textSecondary)
                                    .scaleEffect(likeScale)
                                
                                Text("\(post.likesCount)")
                                    .font(DesignTokens.Typography.labelSmall)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                            }
                        }
                        
                        // Comment button
                        HapticButton(hapticType: .selection, action: onComment) {
                            HStack(spacing: DesignTokens.Spacing.xs) {
                                Image(systemName: "message")
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                
                                Text("\(post.commentsCount)")
                                    .font(DesignTokens.Typography.labelSmall)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                            }
                        }
                        
                        // Share button
                        HapticButton(hapticType: .selection, action: onShare) {
                            HStack(spacing: DesignTokens.Spacing.xs) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                
                                Text("Share")
                                    .font(DesignTokens.Typography.labelSmall)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .smoothAppear(delay: 0.4)
                }
            }
        } loadingContent: {
            // Loading skeleton
                        SkeletonLayouts.feedPost
        }
    }
}

// MARK: - Enhanced Profile Header
struct EnhancedProfileHeader: View {
    let user: User
    let isLoading: Bool
    let onEditProfile: () -> Void
    
    var body: some View {
        ProgressiveLoadingView(isLoading: isLoading) {
            // Loaded content
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Profile image and basic info
                HStack(spacing: DesignTokens.Spacing.md) {
                    AsyncImage(url: URL(string: user.profileImageURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(DesignTokens.Colors.neutral300)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(DesignTokens.Colors.neutral500)
                            )
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .smoothAppear()
                    
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text(user.displayName)
                            .font(DesignTokens.Typography.headlineSmall)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .smoothAppear(delay: 0.1)
                        
                        if let bio = user.bio {
                            Text(bio)
                                .font(DesignTokens.Typography.bodySmall)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                                .lineLimit(2)
                                .smoothAppear(delay: 0.2)
                        }
                        
                        ModernEnhancedButton(
                            title: "Edit Profile",
                            icon: "pencil",
                            style: .tertiary,
                            action: onEditProfile
                        )
                        .smoothAppear(delay: 0.3)
                    }
                    
                    Spacer()
                }
                
                // Stats row
                HStack {
                    StatView(
                        title: "Courses",
                        value: "\(user.coursesCompleted)",
                        delay: 0.4
                    )
                    
                    Spacer()
                    
                    StatView(
                        title: "XP Points",
                        value: "\(user.totalXP)",
                        delay: 0.5
                    )
                    
                    Spacer()
                    
                    StatView(
                        title: "Streak",
                        value: "\(user.currentStreak)",
                        delay: 0.6
                    )
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.surface)
            .cornerRadius(DesignTokens.BorderRadius.card)
        } loadingContent: {
            // Loading skeleton
            SkeletonLayouts.userProfile
        }
    }
}

// MARK: - Stat View Component
struct StatView: View {
    let title: String
    let value: String
    let delay: Double
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            Text(value)
                .font(DesignTokens.Typography.titleLarge)
                .fontWeight(.bold)
                .foregroundColor(DesignTokens.Colors.primary)
            
            Text(title)
                .font(DesignTokens.Typography.labelSmall)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .smoothAppear(delay: delay)
    }
}

// MARK: - Preview Provider
struct ModernComponents_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Enhanced FAB
                EnhancedFloatingActionButton(icon: "plus") {
                    print("FAB tapped")
                }
                
                // Progress bar
                ProgressBar(progress: 0.7)
                    .frame(height: 8)
                
                // Sample course card - Create a mock course with required parameters
                EnhancedCourseCard(
                    course: Course(
                        id: UUID(),
                        title: "Sample Course",
                        description: "Sample Description",
                        instructor: Instructor(
                            id: UUID(),
                            name: "Sample Instructor",
                            bio: "Sample bio",
                            avatarURL: nil,
                            expertise: ["iOS Development"],
                            rating: 4.5,
                            totalStudents: 100,
                            totalCourses: 5,
                            isVerified: true,
                            socialLinks: [:]
                        ),
                        category: .programming,
                        difficulty: .beginner,
                        duration: 3600,
                        lessons: []
                    ),
                    isLoading: false
                ) {
                    print("CDCourse tapped")
                }
                
                Spacer()
            }
            .padding()
        }
        .background(DesignTokens.Colors.background)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Helper Functions
private func formatDuration(_ duration: TimeInterval) -> String {
    let hours = Int(duration) / 3600
    let minutes = (Int(duration) % 3600) / 60
    
    if hours > 0 {
        return "\(hours)h \(minutes)m"
    } else {
        return "\(minutes)m"
    }
}

// MARK: - Sample Extensions
extension Course {
    static let sampleCourse = Course(
        id: UUID(),
        title: "SwiftUI Fundamentals",
        description: "Learn the basics of SwiftUI development with hands-on examples and real-world projects.",
        instructor: Instructor(id: UUID(), name: "John Doe", bio: "Experienced instructor", avatarURL: nil, expertise: [], rating: 5.0, totalStudents: 1000, totalCourses: 5, isVerified: true, socialLinks: [:]),
        category: .programming,
        difficulty: .beginner,
        duration: 3600,
        lessons: [],
        thumbnail: nil,
        previewVideo: nil,
        tags: ["SwiftUI", "iOS", "Programming"],
        language: "en",
        price: CoursePrice(),
        rating: CourseRating(),
        isPublished: true,
        publishedAt: Date(),
        createdAt: Date(),
        updatedAt: Date(),
        serverID: nil,
        syncStatus: .synced,
        lastSyncedAt: Date(),
        version: 1,
        etag: nil,
        downloadStatus: .notDownloaded,
        downloadProgress: 0.0,
        downloadSize: nil
    )
}
