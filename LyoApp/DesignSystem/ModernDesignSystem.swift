import SwiftUI

// MARK: - Phase 2 Enhanced Design System
// Modern, accessible, and comprehensive design system for LyoApp

public struct ModernDesignSystem {
    
    // MARK: - Enhanced Animation System
    public struct Animations {
        // Timing curves
        public static let easeInOut = Animation.easeInOut(duration: 0.3)
        public static let easeOut = Animation.easeOut(duration: 0.25)
        public static let spring = Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)
        public static let springBouncy = Animation.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0)
        public static let springSnappy = Animation.spring(response: 0.3, dampingFraction: 1.0, blendDuration: 0)
        
        // Micro-interactions
        public static let buttonPress = Animation.easeInOut(duration: 0.1)
        public static let cardHover = Animation.easeOut(duration: 0.2)
        public static let pageTransition = Animation.easeInOut(duration: 0.4)
        
        // Loading states
        public static let shimmer = Animation.linear(duration: 1.5).repeatForever(autoreverses: false)
        public static let pulse = Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
    }
    
    // MARK: - Enhanced Color System
    public struct Colors {
        // Primary palette with accessibility support
        public static let primary = Color(hex: "#007AFF")
        public static let primaryLight = Color(hex: "#4DA6FF")
        public static let primaryDark = Color(hex: "#0056CC")
        
        // Secondary palette
        public static let secondary = Color(hex: "#5856D6")
        public static let secondaryLight = Color(hex: "#8B89E3")
        public static let secondaryDark = Color(hex: "#3634A3")
        
        // Accent colors
        public static let accent = Color(hex: "#00D4AA")
        public static let accentLight = Color(hex: "#4DFFE6")
        public static let accentDark = Color(hex: "#00A085")
        
        // Semantic colors
        public static let success = Color(hex: "#34C759")
        public static let warning = Color(hex: "#FF9500")
        public static let error = Color(hex: "#FF3B30")
        public static let info = Color(hex: "#007AFF")
        
        // Neutral palette
        public static let neutral50 = Color(hex: "#F9FAFB")
        public static let neutral100 = Color(hex: "#F3F4F6")
        public static let neutral200 = Color(hex: "#E5E7EB")
        public static let neutral300 = Color(hex: "#D1D5DB")
        public static let neutral400 = Color(hex: "#9CA3AF")
        public static let neutral500 = Color(hex: "#6B7280")
        public static let neutral600 = Color(hex: "#4B5563")
        public static let neutral700 = Color(hex: "#374151")
        public static let neutral800 = Color(hex: "#1F2937")
        public static let neutral900 = Color(hex: "#111827")
        
        // Glass effect colors
        public static let glassLight = Color.white.opacity(0.1)
        public static let glassMedium = Color.white.opacity(0.15)
        public static let glassDark = Color.black.opacity(0.3)
        public static let glassBorder = Color.white.opacity(0.2)
        
        // Background gradients
        public static let backgroundPrimary = LinearGradient(
            gradient: Gradient(colors: [
                Color.black,
                Color(hex: "#1a1a2e"),
                Color.black
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        public static let backgroundSecondary = LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "#1a1a2e"),
                Color.black.opacity(0.9)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        public static let backgroundCard = LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.1),
                Color.white.opacity(0.05)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        public static let backgroundButton = LinearGradient(
            gradient: Gradient(colors: [
                primary,
                primaryDark
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Text colors (semantic)
        public static let textPrimary = Color.white
        public static let textSecondary = Color.white.opacity(0.7)
        public static let textTertiary = Color.white.opacity(0.5)
    }
    
    // MARK: - Enhanced Typography
    public struct Typography {
        // Display typography
        public static let displayLarge = Font.system(size: 57, weight: .regular, design: .default)
        public static let displayMedium = Font.system(size: 45, weight: .regular, design: .default)
        public static let displaySmall = Font.system(size: 36, weight: .regular, design: .default)
        
        // Headline typography
        public static let headlineLarge = Font.system(size: 32, weight: .bold, design: .default)
        public static let headlineMedium = Font.system(size: 28, weight: .bold, design: .default)
        public static let headlineSmall = Font.system(size: 24, weight: .semibold, design: .default)
        
        // Title typography
        public static let titleLarge = Font.system(size: 22, weight: .semibold, design: .default)
        public static let titleMedium = Font.system(size: 16, weight: .semibold, design: .default)
        public static let titleSmall = Font.system(size: 14, weight: .medium, design: .default)
        
        // Body typography
        public static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
        public static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
        public static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
        
        // Caption typography
        public static let caption = Font.system(size: 11, weight: .medium, design: .default)
        public static let captionSmall = Font.system(size: 10, weight: .medium, design: .default)
    }
    
    // MARK: - Enhanced Spacing
    public struct Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let xxl: CGFloat = 48
        public static let xxxl: CGFloat = 64
        
        // Semantic spacing
        public static let cardPadding: CGFloat = 16
        public static let buttonPadding: CGFloat = 12
        public static let sectionSpacing: CGFloat = 24
        public static let screenMargin: CGFloat = 16
    }
    
    // MARK: - Enhanced Shadows
    public struct Shadows {
        public static let small = (color: Color.black.opacity(0.1), radius: CGFloat(2), x: CGFloat(0), y: CGFloat(1))
        public static let medium = (color: Color.black.opacity(0.15), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        public static let large = (color: Color.black.opacity(0.2), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
        public static let floating = (color: Color.black.opacity(0.25), radius: CGFloat(24), x: CGFloat(0), y: CGFloat(12))
    }
    
    // MARK: - Corner Radius
    public struct CornerRadius {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 20
        public static let xxl: CGFloat = 24
        public static let full: CGFloat = 999
    }
    
    // MARK: - Enhanced Interaction States
    public struct InteractionStates {
        public static let scalePressed: CGFloat = 0.96
        public static let scaleHover: CGFloat = 1.02
        public static let opacityPressed: Double = 0.8
        public static let opacityDisabled: Double = 0.6
    }
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
