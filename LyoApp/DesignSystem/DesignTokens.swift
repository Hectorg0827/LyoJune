import SwiftUI

// MARK: - Modern Design Tokens
// Enhanced design system for LyoApp Phase 2

public struct DesignTokens {
    
    // MARK: - Spacing System
    /// Consistent spacing scale based on 8pt grid
    public struct Spacing {
        public static let extraSmall: CGFloat = 2   // 0.125rem
        public static let xs: CGFloat = 4      // 0.25rem
        public static let small: CGFloat = 8   // 0.5rem (alias for sm)
        public static let sm: CGFloat = 8      // 0.5rem  
        public static let medium: CGFloat = 16 // 1rem (alias for md)
        public static let md: CGFloat = 16     // 1rem
        public static let lg: CGFloat = 24     // 1.5rem
        public static let xl: CGFloat = 32     // 2rem
        public static let xxl: CGFloat = 48    // 3rem
        public static let xxxl: CGFloat = 64   // 4rem
        
        // Semantic spacing
        public static let componentPadding = md
        public static let sectionSpacing = lg
        public static let screenMargin = md
        public static let cardPadding = md
        public static let buttonPadding = sm
    }
    
    // MARK: - Typography Scale
    /// Modern typography system with accessibility support
    public struct Typography {
        
        // Display text (largest)
        public static let displayLarge = Font.system(size: 57, weight: .regular, design: .default)
        public static let displayMedium = Font.system(size: 45, weight: .regular, design: .default)
        public static let displaySmall = Font.system(size: 36, weight: .regular, design: .default)
        
        // Headlines
        public static let headlineLarge = Font.system(size: 32, weight: .regular, design: .default)
        public static let headlineMedium = Font.system(size: 28, weight: .regular, design: .default)
        public static let headlineSmall = Font.system(size: 24, weight: .regular, design: .default)
        
        // Titles
        public static let titleLarge = Font.system(size: 22, weight: .medium, design: .default)
        public static let titleMedium = Font.system(size: 16, weight: .medium, design: .default)
        public static let titleSmall = Font.system(size: 14, weight: .medium, design: .default)
        
        // Body text
        public static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
        public static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
        public static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
        
        // Labels
        public static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
        public static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
        public static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)
        
        // Caption
        public static let caption = Font.system(size: 10, weight: .regular, design: .default)
    }
    
    // MARK: - Color Palette
    /// Accessible color system with semantic naming
    public struct Colors {
        
        // Primary Brand Colors
        public static let primary = Color("Primary")
        public static let primaryVariant = Color("PrimaryVariant")
        public static let secondary = Color("Secondary")
        public static let secondaryVariant = Color("SecondaryVariant")
        
        // Surface Colors
        public static let surface = Color("Surface")
        public static let surfaceVariant = Color("SurfaceVariant")
        public static let background = Color("Background")
        public static let backgroundVariant = Color("BackgroundVariant")
        
        // Content Colors
        public static let onPrimary = Color("OnPrimary")
        public static let onSecondary = Color("OnSecondary")
        public static let onSurface = Color("OnSurface")
        public static let onBackground = Color("OnBackground")
        
        // State Colors
        public static let success = Color("Success")
        public static let warning = Color("Warning")
        public static let error = Color("Error")
        public static let info = Color("Info")
        
        // Neutral Colors
        public static let neutral100 = Color("Neutral100")
        public static let neutral200 = Color("Neutral200")
        public static let neutral300 = Color("Neutral300")
        public static let neutral400 = Color("Neutral400")
        public static let neutral500 = Color("Neutral500")
        public static let neutral600 = Color("Neutral600")
        public static let neutral700 = Color("Neutral700")
        public static let neutral800 = Color("Neutral800")
        public static let neutral900 = Color("Neutral900")
        
        // Text Colors (semantic)
        public static let textPrimary = Color("TextPrimary")
        public static let textSecondary = Color("TextSecondary")
        public static let textTertiary = Color("TextTertiary")
        public static let textDisabled = Color("TextDisabled")
        
        // Interactive Colors
        public static let interactive = Color("Interactive")
        public static let interactiveHover = Color("InteractiveHover")
        public static let interactivePressed = Color("InteractivePressed")
        public static let interactiveDisabled = Color("InteractiveDisabled")
        
        // Border and Outline Colors
        public static let border = neutral300
        public static let borderHover = neutral400
        public static let borderFocus = primary
        
        // Additional colors for compatibility
        public static let accent = primary
        public static let backgroundPrimary = background
        public static let backgroundSecondary = backgroundVariant
    }
    
    // MARK: - Border Radius
    /// Consistent border radius scale
    public struct BorderRadius {
        public static let none: CGFloat = 0
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 24
        public static let full: CGFloat = 999
        
        // Semantic radius
        public static let button = md
        public static let card = lg
        public static let modal = xl
        public static let avatar = full
        public static let medium = md  // Alias for md
        public static let large = lg   // Alias for lg
        public static let small = xs   // Alias for xs
    }
    
    // MARK: - Corner Radius (alias for BorderRadius)
    public struct CornerRadius {
        public static let none: CGFloat = BorderRadius.none
        public static let xs: CGFloat = BorderRadius.xs
        public static let sm: CGFloat = BorderRadius.sm
        public static let md: CGFloat = BorderRadius.md
        public static let lg: CGFloat = BorderRadius.lg
        public static let xl: CGFloat = BorderRadius.xl
        public static let full: CGFloat = BorderRadius.full
        
        // Semantic radius
        public static let button = BorderRadius.button
        public static let card = BorderRadius.card
        public static let modal = BorderRadius.modal
        public static let avatar = BorderRadius.avatar
        public static let medium = BorderRadius.medium
    }
    
    // MARK: - Shadows
    /// Elevation-based shadow system
    public struct Shadow {
        public static let none = ShadowStyle.none
        public static let sm = ShadowStyle.sm
        public static let md = ShadowStyle.md
        public static let lg = ShadowStyle.lg
        public static let xl = ShadowStyle.xl
    }
    
    // MARK: - Animation Durations
    /// Consistent animation timing
    public struct Duration {
        public static let instant: Double = 0
        public static let fast: Double = 0.15
        public static let normal: Double = 0.25
        public static let slow: Double = 0.4
        public static let slower: Double = 0.6
        
        // Semantic durations
        public static let buttonPress = fast
        public static let screenTransition = normal
        public static let modalPresentation = slow
        public static let loadingState = normal
    }
    
    // MARK: - Animation System
    /// Consistent animation timing and easing
    public struct Animations {
        // Standard durations
        public static let instant = Animation.linear(duration: 0)
        public static let fast = Animation.easeInOut(duration: 0.15)
        public static let standard = Animation.easeInOut(duration: 0.25)
        public static let slow = Animation.easeInOut(duration: 0.4)
        
        // Spring animations
        public static let spring = Animation.spring(response: 0.5, dampingFraction: 0.8)
        public static let springBouncy = Animation.spring(response: 0.6, dampingFraction: 0.7)
        public static let springSnappy = Animation.spring(response: 0.3, dampingFraction: 1.0)
        
        // Micro-interactions
        public static let buttonPress = Animation.easeInOut(duration: 0.1)
        public static let cardHover = Animation.easeOut(duration: 0.2)
        public static let pageTransition = Animation.easeInOut(duration: 0.4)
        
        // Loading states
        public static let shimmer = Animation.linear(duration: 1.5).repeatForever(autoreverses: false)
        public static let pulse = Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
        
        // Aliases for compatibility
        public static let easeInOut = standard
        public static let easeOut = Animation.easeOut(duration: 0.25)
    }

}

// MARK: - Shadow Style Extension
extension ShadowStyle {
    static let sm = ShadowStyle(
        color: .black.opacity(0.05),
        radius: 2,
        x: 0,
        y: 1
    )
    
    static let md = ShadowStyle(
        color: .black.opacity(0.1),
        radius: 4,
        x: 0,
        y: 2
    )
    
    static let lg = ShadowStyle(
        color: .black.opacity(0.15),
        radius: 8,
        x: 0,
        y: 4
    )
    
    static let xl = ShadowStyle(
        color: .black.opacity(0.2),
        radius: 16,
        x: 0,
        y: 8
    )
    
    static let none = ShadowStyle(
        color: .clear,
        radius: 0,
        x: 0,
        y: 0
    )
}

// MARK: - ShadowStyle Convenience Init
extension ShadowStyle {
    init(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        // Note: This is a simplified version. In practice, you'd use appropriate SwiftUI shadow modifiers
        self = .drop(color: color, radius: radius, x: x, y: y)
    }
}
