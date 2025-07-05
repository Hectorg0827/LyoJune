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

public struct GlassBackground: View {
    public init() {}
    
    public var body: some View {
        ZStack {
            // Base background
            ModernDesignSystem.Colors.backgroundPrimary
            
            // Glass effect layers
            Rectangle()
                .fill(.ultraThinMaterial)
            
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
            
            // Progress indicator placeholder
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
        }
        
        VStack {
            Text("Sample Card Content")
                .font(ModernDesignSystem.Typography.bodyMedium)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg)
                .fill(ModernDesignSystem.Colors.backgroundSecondary)
        )
    }
    .padding()
    .background(ModernDesignSystem.Colors.backgroundPrimary)
    .preferredColorScheme(.dark)
}
