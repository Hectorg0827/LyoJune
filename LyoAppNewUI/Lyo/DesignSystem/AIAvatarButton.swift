import SwiftUI

/// A "futuristic" button designed to summon the AI assistant.
/// It features a glowing icon and a subtle pulsing animation.
public struct AIAvatarButton: View {

    public var action: () -> Void

    @State private var isAnimating = false

    private func tapped() {
        HapticManager.impact(style: .light)
        action()
    }

    public var body: some View {
        Button(action: tapped) {
            ZStack {
                // Outer pulsing glow
                Circle()
                    .fill(Color.blue.opacity(0.5))
                    .scaleEffect(isAnimating ? 1.8 : 1.0)
                    .opacity(isAnimating ? 0.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 2.0).repeatForever(autoreverses: false),
                        value: isAnimating
                    )

                // Main button body
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .blue.opacity(0.5), radius: 10, x: 0, y: 5)

                // Inner glowing icon
                Image(systemName: "sparkles")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .white.opacity(0.8), radius: 5)
            }
        }
        .frame(width: 64, height: 64)
        .onAppear {
            isAnimating = true
        }
    }
}

#if DEBUG
struct AIAvatarButton_Previews: PreviewProvider {
    static var previews: some View {
        AIAvatarButton(action: { print("AI Button Tapped") })
            .preferredColorScheme(.dark)
    }
}
#endif
