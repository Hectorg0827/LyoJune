import SwiftUI

// MARK: - Modern Skeleton Loading System
// Phase 2B: Enhanced loading states with smooth animations

struct SkeletonLoader: View {
    
    // MARK: - Configuration
    let cornerRadius: CGFloat
    let height: CGFloat?
    let width: CGFloat?
    
    @State private var isAnimating = false
    
    init(
        cornerRadius: CGFloat = DesignTokens.BorderRadius.md,
        height: CGFloat? = nil,
        width: CGFloat? = nil
    ) {
        self.cornerRadius = cornerRadius
        self.height = height
        self.width = width
    }
    
    // MARK: - Body
    var body: some View {
        Rectangle()
            .fill(gradientBackground)
            .cornerRadius(cornerRadius)
            .frame(width: width, height: height)
            .onAppear {
                startAnimation()
            }
    }
    
    // MARK: - Gradient Animation
    private var gradientBackground: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                DesignTokens.Colors.neutral200.opacity(0.3),
                DesignTokens.Colors.neutral300.opacity(0.7),
                DesignTokens.Colors.neutral200.opacity(0.3)
            ]),
            startPoint: isAnimating ? .leading : .trailing,
            endPoint: isAnimating ? .trailing : .leading
        )
    }
    
    private func startAnimation() {
        withAnimation(
            .linear(duration: 1.2)
            .repeatForever(autoreverses: false)
        ) {
            isAnimating.toggle()
        }
    }
}

// MARK: - Skeleton Components
struct SkeletonComponents {
    
    /// Text line skeleton
    static func textLine(width: CGFloat = 200) -> some View {
        SkeletonLoader(
            cornerRadius: DesignTokens.BorderRadius.xs,
            height: 16,
            width: width
        )
    }
    
    /// Title skeleton
    static func title(width: CGFloat = 150) -> some View {
        SkeletonLoader(
            cornerRadius: DesignTokens.BorderRadius.sm,
            height: 24,
            width: width
        )
    }
    
    /// Avatar skeleton
    static func avatar(size: CGFloat = 40) -> some View {
        SkeletonLoader(
            cornerRadius: DesignTokens.BorderRadius.full,
            height: size,
            width: size
        )
    }
    
    /// Button skeleton
    static func button(width: CGFloat = 120, height: CGFloat = 44) -> some View {
        SkeletonLoader(
            cornerRadius: DesignTokens.BorderRadius.button,
            height: height,
            width: width
        )
    }
    
    /// Card skeleton
    static func card(height: CGFloat = 120) -> some View {
        SkeletonLoader(
            cornerRadius: DesignTokens.BorderRadius.card,
            height: height
        )
    }
    
    /// Image skeleton
    static func image(width: CGFloat = 100, height: CGFloat = 100) -> some View {
        SkeletonLoader(
            cornerRadius: DesignTokens.BorderRadius.md,
            height: height,
            width: width
        )
    }
}

// MARK: - Complex Skeleton Layouts
struct SkeletonLayouts {
    
    /// Course card skeleton
    static var courseCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Image placeholder
            SkeletonComponents.image(width: .infinity, height: 120)
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                // Title
                SkeletonComponents.title(width: 180)
                
                // Description lines
                SkeletonComponents.textLine(width: 220)
                SkeletonComponents.textLine(width: 160)
                
                // Metadata
                HStack(spacing: DesignTokens.Spacing.sm) {
                    SkeletonComponents.avatar(size: 24)
                    SkeletonComponents.textLine(width: 80)
                    Spacer()
                    SkeletonComponents.textLine(width: 60)
                }
            }
            .padding(DesignTokens.Spacing.md)
        }
        .background(DesignTokens.Colors.surface)
        .cornerRadius(DesignTokens.BorderRadius.card)
    }
    
    /// User profile skeleton
    static var userProfile: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // Header with avatar and name
            HStack(spacing: DesignTokens.Spacing.md) {
                SkeletonComponents.avatar(size: 60)
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    SkeletonComponents.title(width: 120)
                    SkeletonComponents.textLine(width: 100)
                }
                
                Spacer()
            }
            
            // Stats row
            HStack {
                ForEach(0..<3, id: \.self) { index in
                    VStack(spacing: DesignTokens.Spacing.xs) {
                        SkeletonComponents.title(width: 40)
                        SkeletonComponents.textLine(width: 60)
                    }
                    
                    if index < 2 { Spacer() }
                }
            }
            
            // Bio section
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                SkeletonComponents.textLine(width: .infinity)
                SkeletonComponents.textLine(width: 280)
                SkeletonComponents.textLine(width: 200)
            }
        }
        .padding(DesignTokens.Spacing.md)
    }
    
    /// Feed post skeleton
    static var feedPost: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // Author info
            HStack(spacing: DesignTokens.Spacing.sm) {
                SkeletonComponents.avatar(size: 40)
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    SkeletonComponents.textLine(width: 100)
                    SkeletonComponents.textLine(width: 80)
                }
                
                Spacer()
            }
            
            // Post content
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                SkeletonComponents.textLine(width: .infinity)
                SkeletonComponents.textLine(width: .infinity)
                SkeletonComponents.textLine(width: 240)
            }
            
            // Image placeholder (optional)
            SkeletonComponents.image(width: .infinity, height: 200)
            
            // Action buttons
            HStack {
                ForEach(0..<3, id: \.self) { index in
                    SkeletonComponents.button(width: 80, height: 32)
                    if index < 2 { Spacer() }
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .cornerRadius(DesignTokens.BorderRadius.card)
    }
    
    /// Learning lesson skeleton
    static var learningLesson: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // Video placeholder
            SkeletonComponents.image(width: .infinity, height: 200)
                .overlay(
                    SkeletonComponents.avatar(size: 60) // Play button placeholder
                )
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                // Title and metadata
                SkeletonComponents.title(width: 250)
                
                HStack {
                    SkeletonComponents.textLine(width: 80) // Duration
                    Spacer()
                    SkeletonComponents.textLine(width: 60) // Progress
                }
                
                // Description
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    SkeletonComponents.textLine(width: .infinity)
                    SkeletonComponents.textLine(width: .infinity)
                    SkeletonComponents.textLine(width: 180)
                }
                
                // Action buttons
                HStack {
                    SkeletonComponents.button(width: 120, height: 44)
                    Spacer()
                    SkeletonComponents.button(width: 100, height: 44)
                }
            }
            .padding(DesignTokens.Spacing.md)
        }
        .background(DesignTokens.Colors.surface)
        .cornerRadius(DesignTokens.BorderRadius.card)
    }
}

// MARK: - Static Methods for Easy Access
extension SkeletonLoader {
    /// Create a rectangle skeleton
    static func rectangle(width: CGFloat, height: CGFloat) -> some View {
        SkeletonComponents.image(width: width, height: height)
    }
    
    /// Create a feed list skeleton
    static func feedList() -> some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ForEach(0..<5, id: \.self) { _ in
                SkeletonLayouts.feedPost
            }
        }
    }
    
    /// Create a course list skeleton
    static func courseList() -> some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: DesignTokens.Spacing.md) {
                    SkeletonLoader.image(width: 80, height: 60)
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        SkeletonLoader.title(width: 180)
                        SkeletonLoader.textLine(width: 120)
                        SkeletonLoader.textLine(width: 90)
                    }
                    Spacer()
                }
                .padding(DesignTokens.Spacing.md)
                .background(DesignTokens.Colors.neutral100)
                .cornerRadius(DesignTokens.BorderRadius.md)
            }
        }
    }
}

// MARK: - Loading State Manager
@MainActor
class LoadingStateManager: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var loadingMessage: String = "Loading..."
    @Published var progress: Double = 0.0
    
    func setLoading(_ loading: Bool, message: String = "Loading...") {
        withAnimation(.easeInOut(duration: DesignTokens.Duration.fast)) {
            isLoading = loading
            loadingMessage = message
        }
    }
    
    func updateProgress(_ progress: Double) {
        withAnimation(.easeInOut(duration: DesignTokens.Duration.fast)) {
            self.progress = progress
        }
    }
}

// MARK: - Progressive Loading View
struct ProgressiveLoadingView<Content: View, LoadingContent: View>: View {
    let isLoading: Bool
    let content: Content
    let loadingContent: LoadingContent
    
    init(
        isLoading: Bool,
        @ViewBuilder content: () -> Content,
        @ViewBuilder loadingContent: () -> LoadingContent
    ) {
        self.isLoading = isLoading
        self.content = content()
        self.loadingContent = loadingContent()
    }
    
    var body: some View {
        Group {
            if isLoading {
                loadingContent
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                content
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeInOut(duration: DesignTokens.Duration.normal), value: isLoading)
    }
}

// MARK: - Preview Provider
struct SkeletonLoader_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            SkeletonLayouts.courseCard
            SkeletonLayouts.feedPost
            SkeletonLayouts.userProfile
        }
        .padding()
        .background(DesignTokens.Colors.background)
        .preferredColorScheme(.dark)
    }
}
