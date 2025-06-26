import SwiftUI
import UIKit

// MARK: - Haptic Feedback Manager
// Phase 2D: Enhanced haptic feedback system for better user experience

@MainActor
class HapticManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = HapticManager()
    
    // MARK: - Haptic Generators
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()
    
    // MARK: - Settings
    @Published var isHapticsEnabled: Bool = true
    
    private init() {
        prepareGenerators()
    }
    
    // MARK: - Preparation
    private func prepareGenerators() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notification.prepare()
        selection.prepare()
    }
    
    // MARK: - Public Interface
    
    /// Light impact for subtle interactions (button hover, selection changes)
    func lightImpact() {
        guard isHapticsEnabled else { return }
        impactLight.impactOccurred()
    }
    
    /// Medium impact for standard interactions (button taps, toggles)
    func mediumImpact() {
        guard isHapticsEnabled else { return }
        impactMedium.impactOccurred()
    }
    
    /// Heavy impact for significant interactions (major actions, completions)
    func heavyImpact() {
        guard isHapticsEnabled else { return }
        impactHeavy.impactOccurred()
    }
    
    /// Success notification (task completion, positive feedback)
    func success() {
        guard isHapticsEnabled else { return }
        notification.notificationOccurred(.success)
    }
    
    /// Warning notification (validation errors, cautions)
    func warning() {
        guard isHapticsEnabled else { return }
        notification.notificationOccurred(.warning)
    }
    
    /// Error notification (failures, critical issues)
    func error() {
        guard isHapticsEnabled else { return }
        notification.notificationOccurred(.error)
    }
    
    /// Selection feedback (picker changes, option selection)
    func selection() {
        guard isHapticsEnabled else { return }
        selection.selectionChanged()
    }
    
    // MARK: - Unified Interface Methods
    
    /// Impact feedback with style parameter
    func impactOccurred(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isHapticsEnabled else { return }
        switch style {
        case .light:
            lightImpact()
        case .medium:
            mediumImpact()
        case .heavy:
            heavyImpact()
        @unknown default:
            mediumImpact()
        }
    }
    
    /// Notification feedback with type parameter
    func notificationOccurred(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isHapticsEnabled else { return }
        switch type {
        case .success:
            success()
        case .warning:
            warning()
        case .error:
            error()
        @unknown default:
            break
        }
    }
    
    // MARK: - Complex Patterns
    
    /// Double tap pattern for special actions
    func doubleTap() {
        guard isHapticsEnabled else { return }
        lightImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.lightImpact()
        }
    }
    
    /// Triple tap pattern for advanced actions
    func tripleTap() {
        guard isHapticsEnabled else { return }
        lightImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.lightImpact()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.lightImpact()
            }
        }
    }
    
    /// Progressive impact for loading or progress
    func progressiveImpact(completion: @escaping () -> Void) {
        guard isHapticsEnabled else { 
            completion()
            return 
        }
        
        lightImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.mediumImpact()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.heavyImpact()
                completion()
            }
        }
    }
    
    /// Rhythmic pattern for notifications
    func rhythmicAlert() {
        guard isHapticsEnabled else { return }
        
        mediumImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.lightImpact()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.mediumImpact()
            }
        }
    }
}

// MARK: - Haptic Feedback Types
enum HapticFeedbackType {
    case lightImpact
    case mediumImpact
    case heavyImpact
    case success
    case warning
    case error
    case selection
    case doubleTap
    case tripleTap
    case rhythmicAlert
    
    func trigger() {
        switch self {
        case .lightImpact:
            HapticManager.shared.lightImpact()
        case .mediumImpact:
            HapticManager.shared.mediumImpact()
        case .heavyImpact:
            HapticManager.shared.heavyImpact()
        case .success:
            HapticManager.shared.success()
        case .warning:
            HapticManager.shared.warning()
        case .error:
            HapticManager.shared.error()
        case .selection:
            HapticManager.shared.selection()
        case .doubleTap:
            HapticManager.shared.doubleTap()
        case .tripleTap:
            HapticManager.shared.tripleTap()
        case .rhythmicAlert:
            HapticManager.shared.rhythmicAlert()
        }
    }
}

// MARK: - Haptic Button Component
struct HapticButton<Content: View>: View {
    let content: Content
    let action: () -> Void
    let hapticType: HapticFeedbackType
    
    @State private var isPressed = false
    
    init(
        hapticType: HapticFeedbackType = .mediumImpact,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.hapticType = hapticType
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: {
            hapticType.trigger()
            action()
        }) {
            content
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(AnimationPresets.buttonPress, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            if pressing {
                HapticManager.shared.lightImpact()
            }
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Haptic Toggle Component
struct HapticToggle: View {
    @Binding var isOn: Bool
    let label: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(DesignTokens.Typography.bodyMedium)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .onChange(of: isOn) { newValue in
                    if newValue {
                        HapticManager.shared.success()
                    } else {
                        HapticManager.shared.lightImpact()
                    }
                }
        }
    }
}

// MARK: - View Modifier for Haptic Feedback
struct HapticFeedbackModifier: ViewModifier {
    let hapticType: HapticFeedbackType
    let trigger: Bool
    
    func body(content: Content) -> some View {
        content
            .onChange(of: trigger) { _ in
                hapticType.trigger()
            }
    }
}

// MARK: - View Extensions
extension View {
    
    /// Add haptic feedback on tap
    func hapticFeedback(_ type: HapticFeedbackType = .mediumImpact) -> some View {
        onTapGesture {
            type.trigger()
        }
    }
    
    /// Add haptic feedback when a condition changes
    func hapticOnChange<T: Equatable>(
        of value: T,
        hapticType: HapticFeedbackType = .selection
    ) -> some View {
        onChange(of: value) { _ in
            hapticType.trigger()
        }
    }
    
    /// Add haptic feedback modifier
    func haptic(
        type: HapticFeedbackType,
        trigger: Bool
    ) -> some View {
        modifier(HapticFeedbackModifier(hapticType: type, trigger: trigger))
    }
}

// MARK: - Accessibility Enhancements
struct AccessibilityEnhancements {
    
    /// Check if haptics should be enabled based on accessibility settings
    static var shouldEnableHaptics: Bool {
        // Respect user's accessibility preferences
        return !UIAccessibility.isReduceMotionEnabled
    }
    
    /// Dynamic font size multiplier
    static var fontSizeMultiplier: CGFloat {
        let preferredSize = UIApplication.shared.preferredContentSizeCategory
        
        switch preferredSize {
        case .extraSmall:
            return 0.8
        case .small:
            return 0.9
        case .medium:
            return 1.0
        case .large:
            return 1.1
        case .extraLarge:
            return 1.2
        case .extraExtraLarge:
            return 1.3
        case .extraExtraExtraLarge:
            return 1.4
        case .accessibilityMedium:
            return 1.6
        case .accessibilityLarge:
            return 1.8
        case .accessibilityExtraLarge:
            return 2.0
        case .accessibilityExtraExtraLarge:
            return 2.2
        case .accessibilityExtraExtraExtraLarge:
            return 2.4
        default:
            return 1.0
        }
    }
    
    /// High contrast colors
    static var shouldUseHighContrast: Bool {
        return UIAccessibility.isDarkerSystemColorsEnabled
    }
    
    /// Reduced motion preference
    static var shouldReduceMotion: Bool {
        return UIAccessibility.isReduceMotionEnabled
    }
}

// MARK: - Accessibility-Aware Animation Modifier
struct AccessibleAnimationModifier: ViewModifier {
    let animation: Animation?
    
    func body(content: Content) -> some View {
        if AccessibilityEnhancements.shouldReduceMotion {
            content
        } else {
            content
                .animation(animation, value: UUID())
        }
    }
}

extension View {
    /// Apply animation only if reduce motion is disabled
    func accessibleAnimation(_ animation: Animation?) -> some View {
        modifier(AccessibleAnimationModifier(animation: animation))
    }
}

// MARK: - Modern Button with Full Enhancement
struct ModernEnhancedButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var isHovered = false
    
    enum ButtonStyle {
        case primary
        case secondary
        case tertiary
        case destructive
        
        var backgroundColor: Color {
            switch self {
            case .primary:
                return DesignTokens.Colors.primary
            case .secondary:
                return DesignTokens.Colors.secondary
            case .tertiary:
                return DesignTokens.Colors.surface
            case .destructive:
                return DesignTokens.Colors.error
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .secondary, .destructive:
                return DesignTokens.Colors.onPrimary
            case .tertiary:
                return DesignTokens.Colors.textPrimary
            }
        }
        
        var hapticType: HapticFeedbackType {
            switch self {
            case .primary:
                return .mediumImpact
            case .secondary:
                return .lightImpact
            case .tertiary:
                return .selection
            case .destructive:
                return .warning
            }
        }
    }
    
    init(
        title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            style.hapticType.trigger()
            action()
        }) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(DesignTokens.Typography.labelMedium)
                }
                
                Text(title)
                    .font(DesignTokens.Typography.labelLarge)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(style.backgroundColor)
            .foregroundColor(style.foregroundColor)
            .cornerRadius(DesignTokens.BorderRadius.button)
            .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.02 : 1.0))
            .brightness(isPressed ? -0.1 : (isHovered ? 0.05 : 0))
        }
        .buttonStyle(PlainButtonStyle())
        .accessibleAnimation(AnimationPresets.buttonPress)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            if pressing {
                HapticManager.shared.lightImpact()
            }
            isPressed = pressing
        }, perform: {})
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to activate")
    }
}

// MARK: - Preview Provider
struct HapticSystem_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Modern enhanced buttons
            ModernEnhancedButton(title: "Primary Action", icon: "star.fill", style: .primary) {
                print("Primary tapped")
            }
            
            ModernEnhancedButton(title: "Secondary", style: .secondary) {
                print("Secondary tapped")
            }
            
            ModernEnhancedButton(title: "Tertiary", style: .tertiary) {
                print("Tertiary tapped")
            }
            
            ModernEnhancedButton(title: "Destructive", icon: "trash", style: .destructive) {
                print("Destructive tapped")
            }
            
            // Haptic toggle
            HapticToggle(isOn: .constant(true), label: "Enable Haptics")
        }
        .padding()
        .background(DesignTokens.Colors.background)
        .preferredColorScheme(.dark)
    }
}
