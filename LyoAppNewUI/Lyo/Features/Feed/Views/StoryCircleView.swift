import SwiftUI

/// A view that displays a user's profile picture in a circle, typically used to represent a story.
/// It features a unique, animated gradient border to distinguish it from standard story circles.
struct StoryCircleView: View {

    let story: Story

    @State private var rotation: Double = 0

    private let gradientColors: [Color] = [.blue, .purple, .pink, .red, .orange]

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Animated Gradient Border
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: gradientColors),
                            center: .center,
                            angle: .degrees(rotation)
                        ),
                        lineWidth: 3
                    )

                // Profile Image
                AsyncImage(url: story.user.profileImageURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .padding(12)
                        .foregroundColor(.secondary)
                }
                .padding(5) // Padding to keep image inside the border
                .background(Color(.systemBackground))
                .clipShape(Circle())
            }
            .frame(width: 70, height: 70)
            .onAppear {
                withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }

            Text(story.user.username)
                .font(.caption)
                .lineLimit(1)
        }
        .frame(width: 80) // Give the VStack a consistent frame
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(story.user.username)'s story")
        .accessibilityHint("Tap to view")
    }
}

#if DEBUG
struct StoryCircleView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleUser = User(id: UUID(), username: "jules_ai", profileImageURL: nil)
        let sampleStory = Story(id: UUID(), user: sampleUser, items: [])

        StoryCircleView(story: sampleStory)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif
