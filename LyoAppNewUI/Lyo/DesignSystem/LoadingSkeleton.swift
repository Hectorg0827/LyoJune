import SwiftUI

/// A view that displays a shimmering placeholder for content that is loading.
/// It uses a subtle, animated gradient to create a "shimmer" effect.
public struct LoadingSkeleton: View {

    @State private var phase: CGFloat = 0

    public init() {}

    public var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                ShimmerEffect()
                    .blendMode(.screen)
            )
            .mask(Rectangle()) // The shape of the skeleton can be changed by the caller using .mask()
    }
}

/// The animated effect that creates the shimmer.
private struct ShimmerEffect: View {

    @State private var isAnimating = false

    private let animation = Animation.linear(duration: 1.5).repeatForever(autoreverses: false)

    var body: some View {
        let gradient = Gradient(colors: [
            .white.opacity(0.5),
            .white.opacity(0.1),
            .white.opacity(0.5)
        ])

        let startPoint = isAnimating ? UnitPoint(x: -0.2, y: 0.5) : UnitPoint(x: 1.2, y: 0.5)
        let endPoint = isAnimating ? UnitPoint(x: 1.2, y: 0.5) : UnitPoint(x: -0.2, y: 0.5)

        return LinearGradient(gradient: gradient, startPoint: startPoint, endPoint: endPoint)
            .onAppear {
                withAnimation(animation) {
                    isAnimating = true
                }
            }
    }
}


#if DEBUG
struct LoadingSkeleton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Loading Post...")
                .font(.headline)

            // Example of a typical list item skeleton
            HStack(spacing: 16) {
                LoadingSkeleton()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 8) {
                    LoadingSkeleton().frame(height: 20)
                    LoadingSkeleton().frame(height: 20)
                        .frame(width: 150)
                }
            }

            // Example of a larger content block skeleton
            LoadingSkeleton()
                .frame(height: 200)
                .cornerRadius(12)
        }
        .padding()
        .preferredColorScheme(.dark)
    }
}
#endif
