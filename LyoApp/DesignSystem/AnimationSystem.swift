import SwiftUI

// MARK: - Modern Animation System
// Phase 2C: Smooth animations and micro-interactions

struct TransitionPresets {
    // MARK: - Basic Transitions
    static let fadeInOut = AnyTransition.opacity
    static let slideUp = AnyTransition.slideFromBottom
    static let slideDown = AnyTransition.move(edge: .top)
    static let slideFromLeading = AnyTransition.slideFromLeading
    static let scaleAndFade = AnyTransition.scaleAndFade
}

struct AnimationSystem {
    struct Presets {
        // Basic animations
        static let spring = AnimationPresets.springBouncy
        static let easeInOut = AnimationPresets.easeInOut
        static let easeIn = AnimationPresets.easeIn
        static let easeOut = AnimationPresets.easeOut
        
        // Transitions
        static let fadeInOut = TransitionPresets.fadeInOut
        static let slideUp = TransitionPresets.slideUp
        static let slideDown = TransitionPresets.slideDown
        static let slideFromLeft = TransitionPresets.slideFromLeading
        static let scaleIn = TransitionPresets.scaleAndFade
    }
}

struct AnimationPresets {
    
    // MARK: - Basic Animations
    static let springBouncy = Animation.spring(
        response: 0.6,
        dampingFraction: 0.8,
        blendDuration: 0
    )
    
    static let springSmooth = Animation.spring(
        response: 0.4,
        dampingFraction: 0.9,
        blendDuration: 0
    )
    
    static let easeInOut = Animation.easeInOut(duration: DesignTokens.Duration.normal)
    static let easeIn = Animation.easeIn(duration: DesignTokens.Duration.normal)
    static let easeOut = Animation.easeOut(duration: DesignTokens.Duration.normal)
    
    // MARK: - Interactive Animations
    static let buttonPress = Animation.easeInOut(duration: DesignTokens.Duration.buttonPress)
    static let cardHover = Animation.easeOut(duration: DesignTokens.Duration.fast)
    static let modalPresent = Animation.spring(response: 0.5, dampingFraction: 0.8)
    
    // MARK: - Loading Animations
    static let pulse = Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
    static let rotate = Animation.linear(duration: 1.0).repeatForever(autoreverses: false)
    static let shimmer = Animation.linear(duration: 1.2).repeatForever(autoreverses: false)
    
    // MARK: - Transition Animations
    static let slideIn = Animation.easeOut(duration: DesignTokens.Duration.normal)
    static let fadeIn = Animation.easeInOut(duration: DesignTokens.Duration.slow)
    static let scaleIn = Animation.spring(response: 0.3, dampingFraction: 0.7)
}

// MARK: - Custom Transitions
extension AnyTransition {
    
    // Slide from bottom with bounce
    static let slideFromBottom = AnyTransition.move(edge: .bottom)
        .combined(with: .scale(scale: 0.8))
        .animation(AnimationPresets.springBouncy)
    
    // Slide from leading with fade
    static let slideFromLeading = AnyTransition.move(edge: .leading)
        .combined(with: .opacity)
        .animation(AnimationPresets.easeInOut)
    
    // Scale with opacity
    static let scaleAndFade = AnyTransition.scale(scale: 0.8)
        .combined(with: .opacity)
        .animation(AnimationPresets.springSmooth)
    
    // Blur transition
    static let blur = AnyTransition.asymmetric(
        insertion: .scale(scale: 1.1).combined(with: .opacity),
        removal: .scale(scale: 0.9).combined(with: .opacity)
    )
    
    // Rotate and fade
    static let rotateAndFade = AnyTransition.asymmetric(
        insertion: .scale(scale: 0.1).combined(with: .opacity),
        removal: .scale(scale: 2.0).combined(with: .opacity)
    )
}

// MARK: - Interactive Button Component
struct InteractiveButton<Content: View>: View {
    let content: Content
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var isHovered = false
    
    init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: action) {
            content
                .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.02 : 1.0))
                .brightness(isPressed ? -0.1 : (isHovered ? 0.05 : 0))
                .animation(AnimationPresets.buttonPress, value: isPressed)
                .animation(AnimationPresets.cardHover, value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Animated Card Component
struct AnimatedCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    
    @State private var isVisible = false
    @State private var isHovered = false
    
    init(
        cornerRadius: CGFloat = DesignTokens.BorderRadius.card,
        shadowRadius: CGFloat = 8,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .background(DesignTokens.Colors.surface)
            .cornerRadius(cornerRadius)
            .shadow(
                color: .black.opacity(isHovered ? 0.2 : 0.1),
                radius: isHovered ? shadowRadius * 1.5 : shadowRadius,
                x: 0,
                y: isHovered ? 8 : 4
            )
            .scaleEffect(isVisible ? 1.0 : 0.9)
            .opacity(isVisible ? 1.0 : 0.0)
            .offset(y: isVisible ? 0 : 20)
            .animation(AnimationPresets.springSmooth, value: isVisible)
            .animation(AnimationPresets.cardHover, value: isHovered)
            .onAppear {
                isVisible = true
            }
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Pulsing View Modifier
struct PulsingModifier: ViewModifier {
    @State private var isPulsing = false
    
    let minOpacity: Double
    let maxOpacity: Double
    let duration: Double
    
    init(minOpacity: Double = 0.4, maxOpacity: Double = 1.0, duration: Double = 1.0) {
        self.minOpacity = minOpacity
        self.maxOpacity = maxOpacity
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? minOpacity : maxOpacity)
            .animation(
                .easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

// MARK: - Shimmer Effect Modifier
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        .white.opacity(0.4),
                        .clear
                    ]),
                    startPoint: UnitPoint(x: phase - 0.3, y: 0.5),
                    endPoint: UnitPoint(x: phase + 0.3, y: 0.5)
                )
                .animation(
                    .linear(duration: 1.5).repeatForever(autoreverses: false),
                    value: phase
                )
            )
            .onAppear {
                phase = 1.3
            }
    }
}

// MARK: - Floating Animation Modifier
struct FloatingModifier: ViewModifier {
    @State private var isFloating = false
    
    let amplitude: CGFloat
    let duration: Double
    
    init(amplitude: CGFloat = 10, duration: Double = 2.0) {
        self.amplitude = amplitude
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -amplitude : amplitude)
            .animation(
                .easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: isFloating
            )
            .onAppear {
                isFloating = true
            }
    }
}

// MARK: - Staggered Animation Container
struct StaggeredAnimationContainer<Content: View>: View {
    let content: Content
    let staggerDelay: Double
    
    @State private var isVisible = false
    
    init(staggerDelay: Double = 0.1, @ViewBuilder content: () -> Content) {
        self.staggerDelay = staggerDelay
        self.content = content()
    }
    
    var body: some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .animation(AnimationPresets.springSmooth, value: isVisible)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + staggerDelay) {
                    isVisible = true
                }
            }
    }
}

// MARK: - View Extensions
extension View {
    
    /// Add pulsing animation
    func pulsing(
        minOpacity: Double = 0.4,
        maxOpacity: Double = 1.0,
        duration: Double = 1.0
    ) -> some View {
        modifier(PulsingModifier(minOpacity: minOpacity, maxOpacity: maxOpacity, duration: duration))
    }
    
    /// Add shimmer effect
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
    
    /// Add floating animation
    func floating(amplitude: CGFloat = 10, duration: Double = 2.0) -> some View {
        modifier(FloatingModifier(amplitude: amplitude, duration: duration))
    }
    
    /// Add staggered animation
    func staggered(delay: Double = 0.1) -> some View {
        StaggeredAnimationContainer(staggerDelay: delay) {
            self
        }
    }
    
    /// Interactive scaling on tap
    func interactiveScale(scale: CGFloat = 0.95) -> some View {
        scaleEffect(1.0)
        .onTapGesture {
            withAnimation(AnimationPresets.buttonPress) {
                // Scale effect is handled by the button's pressed state
            }
        }
    }
    
    /// Smooth appearance animation
    func smoothAppear(delay: Double = 0) -> some View {
        modifier(SmoothAppearModifier(delay: delay))
    }
}

// MARK: - Smooth Appear Modifier
struct SmoothAppearModifier: ViewModifier {
    @State private var isVisible = false
    let delay: Double
    
    init(delay: Double) {
        self.delay = delay
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.9)
            .offset(y: isVisible ? 0 : 10)
            .animation(AnimationPresets.springSmooth, value: isVisible)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Loading Spinner Component
struct ModernLoadingSpinner: View {
    @State private var isRotating = false
    
    let size: CGFloat
    let lineWidth: CGFloat
    let color: Color
    
    init(
        size: CGFloat = 24,
        lineWidth: CGFloat = 3,
        color: Color = DesignTokens.Colors.primary
    ) {
        self.size = size
        self.lineWidth = lineWidth
        self.color = color
    }
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.8)
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: [color.opacity(0.2), color]),
                    center: .center
                ),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .animation(AnimationPresets.rotate, value: isRotating)
            .onAppear {
                isRotating = true
            }
    }
}

// MARK: - Preview Provider
struct AnimationSystem_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Interactive button example
            InteractiveButton(action: {}) {
                Text("Interactive Button")
                    .padding()
                    .background(DesignTokens.Colors.primary)
                    .foregroundColor(DesignTokens.Colors.onPrimary)
                    .cornerRadius(DesignTokens.BorderRadius.button)
            }
            
            // Animated card example
            AnimatedCard {
                VStack {
                    Text("Animated Card")
                        .font(DesignTokens.Typography.titleMedium)
                    Text("With smooth animations")
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                .padding()
            }
            
            // Loading spinner
            ModernLoadingSpinner()
            
            // Pulsing text
            Text("Pulsing Text")
                .pulsing()
            
            // Floating element
            Text("Floating Element")
                .floating()
        }
        .padding()
        .background(DesignTokens.Colors.background)
        .preferredColorScheme(.dark)
    }
}
