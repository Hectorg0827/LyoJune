import SwiftUI

// MARK: - Phase 2 Enhanced UI Components
// Modern, accessible, and performant UI components

// MARK: - Enhanced Modern Button
struct ModernButton: View {
    enum Style {
        case primary
        case secondary
        case tertiary
        case ghost
        case destructive
    }
    
    enum Size {
        case small
        case medium
        case large
        
        var height: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 44
            case .large: return 56
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            case .medium: return EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
            case .large: return EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
            }
        }
        
        var font: Font {
            switch self {
            case .small: return ModernDesignSystem.Typography.bodySmall
            case .medium: return ModernDesignSystem.Typography.bodyMedium
            case .large: return ModernDesignSystem.Typography.bodyLarge
            }
        }
    }
    
    let title: String
    let style: Style
    let size: Size
    let isLoading: Bool
    let isDisabled: Bool
    let icon: String?
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var isHovered = false
    
    init(
        title: String,
        style: Style = .primary,
        size: Size = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            guard !isDisabled && !isLoading else { return }
            HapticManager.shared.lightImpact()
            action()
        }) {
            HStack(spacing: ModernDesignSystem.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(textColor)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(size.font.weight(.medium))
                }
                
                Text(title)
                    .font(size.font.weight(.semibold))
                    .foregroundColor(textColor)
            }
            .padding(size.padding)
            .frame(minHeight: size.height)
            .background(backgroundView)
            .overlay(borderView)
            .clipShape(RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md))
            .scaleEffect(isPressed ? ModernDesignSystem.InteractionStates.scalePressed : (isHovered ? ModernDesignSystem.InteractionStates.scaleHover : 1.0))
            .opacity(isDisabled ? ModernDesignSystem.InteractionStates.opacityDisabled : 1.0)
            .animation(ModernDesignSystem.Animations.buttonPress, value: isPressed)
            .animation(ModernDesignSystem.Animations.cardHover, value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled || isLoading)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            ModernDesignSystem.Colors.backgroundButton
        case .secondary:
            ModernDesignSystem.Colors.neutral100
        case .tertiary:
            ModernDesignSystem.Colors.backgroundCard
        case .ghost:
            Color.clear
        case .destructive:
            ModernDesignSystem.Colors.error
        }
    }
    
    @ViewBuilder
    private var borderView: some View {
        switch style {
        case .tertiary, .ghost:
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                .stroke(ModernDesignSystem.Colors.glassBorder, lineWidth: 1)
        default:
            EmptyView()
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return ModernDesignSystem.Colors.neutral900
        case .tertiary, .ghost:
            return ModernDesignSystem.Colors.primary
        }
    }
}

// MARK: - Enhanced Modern Card
struct ModernCard<Content: View>: View {
    let content: Content
    let padding: EdgeInsets
    let cornerRadius: CGFloat
    let shadowStyle: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)
    let borderWidth: CGFloat
    let borderColor: Color
    let isInteractive: Bool
    let onTap: (() -> Void)?
    
    @State private var isPressed = false
    @State private var isHovered = false
    
    init(
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.lg,
        shadowStyle: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = ModernDesignSystem.Shadows.medium,
        borderWidth: CGFloat = 1,
        borderColor: Color = ModernDesignSystem.Colors.glassBorder,
        isInteractive: Bool = false,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowStyle = shadowStyle
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        self.isInteractive = isInteractive
        self.onTap = onTap
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                ModernDesignSystem.Colors.backgroundCard
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(
                color: shadowStyle.color,
                radius: shadowStyle.radius,
                x: shadowStyle.x,
                y: shadowStyle.y
            )
            .scaleEffect(isPressed ? ModernDesignSystem.InteractionStates.scalePressed : (isHovered ? ModernDesignSystem.InteractionStates.scaleHover : 1.0))
            .animation(ModernDesignSystem.Animations.cardHover, value: isHovered)
            .animation(ModernDesignSystem.Animations.buttonPress, value: isPressed)
            .onTapGesture {
                guard isInteractive, let onTap = onTap else { return }
                HapticManager.shared.lightImpact()
                onTap()
            }
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                if isInteractive {
                    isPressed = pressing
                }
            }, perform: {})
            .onHover { hovering in
                if isInteractive {
                    isHovered = hovering
                }
            }
    }
}

// MARK: - Enhanced Input Field
struct ModernTextField: View {
    enum Style {
        case outlined
        case filled
        case underlined
    }
    
    let title: String
    let placeholder: String
    let style: Style
    let isSecure: Bool
    let isDisabled: Bool
    let errorMessage: String?
    let icon: String?
    @Binding var text: String
    
    @State private var isFocused = false
    @State private var isShowingPassword = false
    @FocusState private var textFieldFocused: Bool
    
    init(
        title: String = "",
        placeholder: String,
        text: Binding<String>,
        style: Style = .outlined,
        isSecure: Bool = false,
        isDisabled: Bool = false,
        errorMessage: String? = nil,
        icon: String? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.style = style
        self.isSecure = isSecure
        self.isDisabled = isDisabled
        self.errorMessage = errorMessage
        self.icon = icon
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.xs) {
            if !title.isEmpty {
                Text(title)
                    .font(ModernDesignSystem.Typography.titleSmall)
                    .foregroundColor(ModernDesignSystem.Colors.neutral700)
            }
            
            HStack(spacing: ModernDesignSystem.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(ModernDesignSystem.Colors.neutral500)
                        .font(ModernDesignSystem.Typography.bodyMedium)
                }
                
                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .foregroundColor(ModernDesignSystem.Colors.neutral400)
                            .font(ModernDesignSystem.Typography.bodyMedium)
                    }
                    
                    Group {
                        if isSecure && !isShowingPassword {
                            SecureField("", text: $text)
                        } else {
                            TextField("", text: $text)
                        }
                    }
                    .font(ModernDesignSystem.Typography.bodyMedium)
                    .foregroundColor(ModernDesignSystem.Colors.neutral900)
                    .focused($textFieldFocused)
                    .disabled(isDisabled)
                }
                
                if isSecure {
                    Button(action: {
                        isShowingPassword.toggle()
                        HapticManager.shared.lightImpact()
                    }) {
                        Image(systemName: isShowingPassword ? "eye.slash" : "eye")
                            .foregroundColor(ModernDesignSystem.Colors.neutral500)
                            .font(ModernDesignSystem.Typography.bodyMedium)
                    }
                }
            }
            .padding(ModernDesignSystem.Spacing.md)
            .background(backgroundView)
            .overlay(borderView)
            .clipShape(RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md))
            .opacity(isDisabled ? ModernDesignSystem.InteractionStates.opacityDisabled : 1.0)
            .onChange(of: textFieldFocused) { focused in
                withAnimation(ModernDesignSystem.Animations.easeInOut) {
                    isFocused = focused
                }
            }
            
            if let errorMessage = errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(ModernDesignSystem.Typography.caption)
                    .foregroundColor(ModernDesignSystem.Colors.error)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .animation(ModernDesignSystem.Animations.easeInOut, value: errorMessage)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .outlined:
            Color.clear
        case .filled:
            ModernDesignSystem.Colors.neutral100
        case .underlined:
            Color.clear
        }
    }
    
    @ViewBuilder
    private var borderView: some View {
        let borderColor = errorMessage != nil ? ModernDesignSystem.Colors.error :
                         isFocused ? ModernDesignSystem.Colors.primary :
                         ModernDesignSystem.Colors.neutral300
        
        switch style {
        case .outlined:
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                .stroke(borderColor, lineWidth: isFocused ? 2 : 1)
        case .filled:
            EmptyView()
        case .underlined:
            VStack {
                Spacer()
                Rectangle()
                    .fill(borderColor)
                    .frame(height: isFocused ? 2 : 1)
            }
        }
    }
}

// MARK: - Enhanced Progress Indicator
struct ModernProgressView: View {
    enum Style {
        case linear
        case circular
        case ring
    }
    
    let progress: Double // 0.0 to 1.0
    let style: Style
    let size: CGFloat
    let lineWidth: CGFloat
    let primaryColor: Color
    let secondaryColor: Color
    let isAnimated: Bool
    
    init(
        progress: Double,
        style: Style = .linear,
        size: CGFloat = 4,
        lineWidth: CGFloat = 4,
        primaryColor: Color = ModernDesignSystem.Colors.primary,
        secondaryColor: Color = ModernDesignSystem.Colors.neutral200,
        isAnimated: Bool = true
    ) {
        self.progress = max(0, min(1, progress))
        self.style = style
        self.size = size
        self.lineWidth = lineWidth
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.isAnimated = isAnimated
    }
    
    var body: some View {
        switch style {
        case .linear:
            linearProgress
        case .circular:
            circularProgress
        case .ring:
            ringProgress
        }
    }
    
    private var linearProgress: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(secondaryColor)
                    .frame(height: size)
                    .clipShape(Capsule())
                
                Rectangle()
                    .fill(primaryColor)
                    .frame(width: geometry.size.width * progress, height: size)
                    .clipShape(Capsule())
                    .animation(isAnimated ? ModernDesignSystem.Animations.easeOut : .none, value: progress)
            }
        }
        .frame(height: size)
    }
    
    private var circularProgress: some View {
        ZStack {
            Circle()
                .stroke(secondaryColor, lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    primaryColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(isAnimated ? ModernDesignSystem.Animations.easeOut : .none, value: progress)
        }
        .frame(width: size, height: size)
    }
    
    private var ringProgress: some View {
        ZStack {
            Circle()
                .stroke(secondaryColor, lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [primaryColor, primaryColor.opacity(0.6)]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(isAnimated ? ModernDesignSystem.Animations.easeOut : .none, value: progress)
        }
        .frame(width: size, height: size)
    }
}
