import SwiftUI

// MARK: - Enhanced Design System for LyoApp Phase 2
// Building on the existing design system with modern enhancements

struct DesignSystem {
    
    // MARK: - Modern Colors (Enhanced)
    
    struct Colors {
        // Primary colors - Enhanced with accessibility
        static let primary = Color.blue
        static let secondary = Color.purple
        static let accent = Color.cyan
        
        // Modern semantic colors
        static let surfacePrimary = Color(.systemBackground)
        static let surfaceSecondary = Color(.secondarySystemBackground)
        static let textPrimary = Color(.label)
        static let textSecondary = Color(.secondaryLabel)
        
        // Aliases for compatibility with DesignTokens
        static let background = DesignTokens.Colors.background
        static let surface = DesignTokens.Colors.surface
        
        // Glass effect colors - Enhanced
        static let glassPrimary = Color.white.opacity(0.1)
        static let glassSecondary = Color.white.opacity(0.05)
        static let glassBorder = Color.white.opacity(0.2)
        static let glassBackground = Color.black.opacity(0.3)
        
        // Interactive states
        static let interactive = DesignTokens.Colors.interactive
        static let interactiveHover = DesignTokens.Colors.interactiveHover
        static let interactivePressed = DesignTokens.Colors.interactivePressed
        
        // Background gradients - Enhanced
        static let backgroundPrimary = LinearGradient(
            gradient: Gradient(colors: [
                Color.black,
                Color.blue.opacity(0.2),
                Color.purple.opacity(0.1),
                Color.black
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let backgroundSecondary = LinearGradient(
            gradient: Gradient(colors: [
                Color.black.opacity(0.9),
                Color.blue.opacity(0.1),
                Color.black.opacity(0.9)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Category gradients
        static func categoryGradient(for category: VideoCategory) -> LinearGradient {
            return LinearGradient(
                gradient: Gradient(colors: [category.color, category.color.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // MARK: - Typography
    
    struct Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let headline = Font.headline.weight(.semibold)
        static let body = Font.body.weight(.medium)
        static let caption = Font.caption.weight(.medium)
        static let smallCaption = Font.caption2.weight(.medium)
    }
    
    // MARK: - Spacing
    
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 20
        static let circle: CGFloat = 50
    }
    
    // MARK: - Shadows
    
    struct Shadows {
        static let light = Shadow(
            color: .black.opacity(0.1),
            radius: 5,
            x: 0,
            y: 2
        )
        
        static let medium = Shadow(
            color: .black.opacity(0.2),
            radius: 10,
            x: 0,
            y: 5
        )
        
        static let heavy = Shadow(
            color: .black.opacity(0.3),
            radius: 20,
            x: 0,
            y: 10
        )
        
        static let glow = Shadow(
            color: .blue.opacity(0.3),
            radius: 15,
            x: 0,
            y: 0
        )
    }
    
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
}

// MARK: - Glass Effect Modifiers

struct GlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let borderColor: Color
    let shadowEnabled: Bool
    
    init(
        cornerRadius: CGFloat = DesignSystem.CornerRadius.large,
        borderColor: Color = DesignSystem.Colors.glassBorder,
        shadowEnabled: Bool = true
    ) {
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.shadowEnabled = shadowEnabled
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Material.ultraThin)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
            .conditionalModifier(shadowEnabled) { view in
                view.shadow(
                    color: DesignSystem.Shadows.medium.color,
                    radius: DesignSystem.Shadows.medium.radius,
                    x: DesignSystem.Shadows.medium.x,
                    y: DesignSystem.Shadows.medium.y
                )
            }
    }
}

struct GlassButtonModifier: ViewModifier {
    let isPressed: Bool
    let cornerRadius: CGFloat
    
    init(isPressed: Bool = false, cornerRadius: CGFloat = DesignSystem.CornerRadius.medium) {
        self.isPressed = isPressed
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Material.ultraThin)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(DesignSystem.Colors.glassBorder, lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

// MARK: - Custom Button Styles

struct GlassPrimaryButtonStyle: ButtonStyle {
    let color: Color
    
    init(color: Color = DesignSystem.Colors.primary) {
        self.color = color
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [color, color.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(DesignSystem.CornerRadius.large)
            .shadow(
                color: color.opacity(0.3),
                radius: 10,
                x: 0,
                y: 5
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct GlassSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .fontWeight(.medium)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .modifier(GlassButtonModifier(isPressed: configuration.isPressed))
    }
}

// MARK: - View Extensions

extension View {
    func glassCard(
        cornerRadius: CGFloat = DesignSystem.CornerRadius.large,
        borderColor: Color = DesignSystem.Colors.glassBorder,
        shadowEnabled: Bool = true
    ) -> some View {
        self.modifier(GlassCardModifier(
            cornerRadius: cornerRadius,
            borderColor: borderColor,
            shadowEnabled: shadowEnabled
        ))
    }
    
    func glassPrimaryButton(color: Color = DesignSystem.Colors.primary) -> some View {
        self.buttonStyle(GlassPrimaryButtonStyle(color: color))
    }
    
    func glassSecondaryButton() -> some View {
        self.buttonStyle(GlassSecondaryButtonStyle())
    }
    
    @ViewBuilder
    func conditionalModifier<T: View>(
        _ condition: Bool,
        modifier: (Self) -> T
    ) -> some View {
        if condition {
            modifier(self)
        } else {
            self
        }
    }
    
    func glowEffect(color: Color = .blue, radius: CGFloat = 10) -> some View {
        self
            .shadow(color: color.opacity(0.3), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.1), radius: radius * 2, x: 0, y: 0)
    }
}

// MARK: - Animated Components

struct PulsingView: View {
    @State private var isPulsing = false
    let color: Color
    let size: CGFloat
    
    init(color: Color = .blue, size: CGFloat = 20) {
        self.color = color
        self.size = size
    }
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .scaleEffect(isPulsing ? 1.2 : 1.0)
            .opacity(isPulsing ? 0.6 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                .white.opacity(0.3),
                                .clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: phase)
                    .animation(
                        Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
                        value: phase
                    )
            )
            .onAppear {
                phase = 300
            }
            .clipped()
    }
}

// MARK: - Shimmer Extension for Views
extension View {
    func shimmer() -> some View {
        overlay(
            Rectangle()
                .foregroundColor(.clear)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.4),
                            Color.white.opacity(0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .rotationEffect(.degrees(30))
                .offset(x: -200)
                .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: UUID())
        )
        .clipped()
    }
}

// MARK: - Loading States

struct SkeletonLoadingView: View {
    let cornerRadius: CGFloat
    let height: CGFloat
    
    init(cornerRadius: CGFloat = 8, height: CGFloat = 20) {
        self.cornerRadius = cornerRadius
        self.height = height
    }
    
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(height: height)
            .cornerRadius(cornerRadius)
            .shimmer()
    }
}

// MARK: - Interactive Components

struct InteractiveScaleButton<Content: View>: View {
    let action: () -> Void
    let content: Content
    @State private var isPressed = false
    
    init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: action) {
            content
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        } perform: {}
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Design System Preview")
            .font(DesignSystem.Typography.title)
            .foregroundColor(.white)
        
        VStack {
            Text("Glass Card Example")
                .foregroundColor(.white)
            
            Text("This is a glass effect card with modern styling")
                .foregroundColor(.white.opacity(0.8))
                .font(.caption)
        }
        .padding()
        .glassCard()
        
        Button("Primary Button") {}
            .glassPrimaryButton()
        
        Button("Secondary Button") {}
            .glassSecondaryButton()
        
        PulsingView(color: .blue, size: 30)
        
        SkeletonLoadingView(height: 40)
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}

// MARK: - Form Components

struct GlassFormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
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
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Material.ultraThin)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}