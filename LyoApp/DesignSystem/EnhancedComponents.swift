import SwiftUI

// MARK: - Pattern Overlay Component
// Subtle background patterns for enhanced visual depth

struct PatternOverlay: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 20
            let dotSize: CGFloat = 1
            
            for x in stride(from: 0, to: size.width, by: spacing) {
                for y in stride(from: 0, to: size.height, by: spacing) {
                    let point = CGPoint(x: x, y: y)
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: point.x - dotSize/2,
                            y: point.y - dotSize/2,
                            width: dotSize,
                            height: dotSize
                        )),
                        with: .color(.white)
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Shimmer Loading Effect
struct ShimmerView: View {
    @State private var animationOffset: CGFloat = -1
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: ModernDesignSystem.Colors.neutral200.opacity(0.3), location: 0.0),
                        .init(color: ModernDesignSystem.Colors.neutral100.opacity(0.6), location: 0.5),
                        .init(color: ModernDesignSystem.Colors.neutral200.opacity(0.3), location: 1.0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.clear, location: max(0, animationOffset - 0.3)),
                                .init(color: Color.black, location: animationOffset),
                                .init(color: Color.clear, location: min(1, animationOffset + 0.3))
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    animationOffset = 2
                }
            }
    }
}

// MARK: - Glass Background Component
// Enhanced glass morphism background

struct GlassBackground: View {
    var body: some View {
        ZStack {
            // Base background
            ModernDesignSystem.Colors.backgroundPrimary
            
            // Glass effect layers
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: ModernDesignSystem.Colors.backgroundSecondary.opacity(0.8), location: 0.0),
                            .init(color: ModernDesignSystem.Colors.backgroundPrimary.opacity(0.6), location: 0.5),
                            .init(color: ModernDesignSystem.Colors.backgroundSecondary.opacity(0.8), location: 1.0)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Subtle pattern overlay
            PatternOverlay()
                .opacity(0.02)
        }
    }
}

// MARK: - Floating Action Button Component
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    let size: Size
    let style: Style
    
    enum Size {
        case small, medium, large
        
        var dimension: CGFloat {
            switch self {
            case .small: return 44
            case .medium: return 56
            case .large: return 64
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 20
            case .medium: return 24
            case .large: return 28
            }
        }
    }
    
    enum Style {
        case primary, secondary, accent
        
        var backgroundColor: Color {
            switch self {
            case .primary: return ModernDesignSystem.Colors.primary
            case .secondary: return ModernDesignSystem.Colors.secondary
            case .accent: return ModernDesignSystem.Colors.accent
            }
        }
    }
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticManager.shared.mediumImpact()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: size.iconSize, weight: .medium))
                .foregroundColor(.white)
                .frame(width: size.dimension, height: size.dimension)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    style.backgroundColor,
                                    style.backgroundColor.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(
                    color: style.backgroundColor.opacity(0.3),
                    radius: isPressed ? 5 : 10,
                    x: 0,
                    y: isPressed ? 2 : 5
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0) { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        } perform: {}
    }
}

// MARK: - Enhanced Loading Spinner
struct ModernProgressView: View {
    let style: Style
    let size: Size
    
    enum Style {
        case circular, linear
    }
    
    enum Size {
        case small, medium, large
        
        var dimension: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 24
            case .large: return 32
            }
        }
    }
    
    @State private var isAnimating = false
    
    var body: some View {
        Group {
            if style == .circular {
                Circle()
                    .trim(from: 0, to: 0.8)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                ModernDesignSystem.Colors.primary.opacity(0.2),
                                ModernDesignSystem.Colors.primary
                            ]),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: size.dimension, height: size.dimension)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 1)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                    .onAppear {
                        isAnimating = true
                    }
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .fill(ModernDesignSystem.Colors.neutral300.opacity(0.3))
                    .frame(height: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        ModernDesignSystem.Colors.primary.opacity(0.5),
                                        ModernDesignSystem.Colors.primary,
                                        ModernDesignSystem.Colors.primary.opacity(0.5)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 60)
                            .offset(x: isAnimating ? 200 : -200)
                            .animation(
                                Animation.linear(duration: 1.5)
                                    .repeatForever(autoreverses: false),
                                value: isAnimating
                            )
                    )
                    .clipped()
                    .onAppear {
                        isAnimating = true
                    }
            }
        }
    }
}

// MARK: - Enhanced Card Component
struct ModernCard<Content: View>: View {
    let content: Content
    let style: Style
    let padding: EdgeInsets
    
    enum Style {
        case elevated, outlined, filled
    }
    
    init(
        style: Style = .elevated,
        padding: EdgeInsets = EdgeInsets(
            top: ModernDesignSystem.Spacing.lg,
            leading: ModernDesignSystem.Spacing.lg,
            bottom: ModernDesignSystem.Spacing.lg,
            trailing: ModernDesignSystem.Spacing.lg
        ),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.style = style
        self.padding = padding
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg))
            .overlay(
                Group {
                    if style == .outlined {
                        RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg)
                            .stroke(ModernDesignSystem.Colors.neutral300.opacity(0.3), lineWidth: 1)
                    }
                }
            )
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0,
                y: shadowOffset
            )
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        switch style {
        case .elevated:
            ModernDesignSystem.Colors.backgroundSecondary
        case .outlined:
            Color.clear
        case .filled:
            ModernDesignSystem.Colors.backgroundSecondary.opacity(0.8)
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .elevated:
            return ModernDesignSystem.Colors.backgroundPrimary.opacity(0.3)
        case .outlined, .filled:
            return Color.clear
        }
    }
    
    private var shadowRadius: CGFloat {
        style == .elevated ? 10 : 0
    }
    
    private var shadowOffset: CGFloat {
        style == .elevated ? 4 : 0
    }
}

#Preview {
    VStack(spacing: 20) {
        PatternOverlay()
            .frame(height: 100)
        
        ShimmerView()
            .frame(height: 20)
        
        HStack {
            FloatingActionButton(
                icon: "plus",
                action: {},
                size: .medium,
                style: .primary
            )
            
            ModernProgressView(style: .circular, size: .medium)
        }
        
        ModernCard(style: .elevated) {
            Text("Sample Card Content")
                .font(ModernDesignSystem.Typography.bodyMedium)
        }
    }
    .padding()
    .background(ModernDesignSystem.Colors.backgroundPrimary)
    .preferredColorScheme(.dark)
}
