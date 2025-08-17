import SwiftUI

/// A view that displays a horizontal, scrollable tray of stories.
struct StoriesTrayView: View {

    @Binding var stories: [Story]
    let isLoading: Bool

    var onStoryTapped: (Story) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                if isLoading {
                    // Show skeleton placeholders while loading
                    ForEach(0..<4) { _ in
                        StoryCircleView(story: .placeholder)
                            .redacted(reason: .placeholder)
                    }
                } else {
                    // Show the actual story circles
                    ForEach(stories) { story in
                        Button(action: {
                            onStoryTapped(story)
                        }) {
                            StoryCircleView(story: story)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .frame(height: 100) // Set a fixed height for the tray
    }
}

extension Story {
    /// A placeholder story for use in redacted views and previews.
    static var placeholder: Story {
        .init(
            id: UUID(),
            user: .init(id: UUID(), username: "username", profileImageURL: nil),
            items: []
        )
    }
}


#if DEBUG
struct StoriesTrayView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleStories: [Story] = [
            .init(id: UUID(), user: .init(id: UUID(), username: "jules_ai", profileImageURL: nil), items: []),
            .init(id: UUID(), user: .init(id: UUID(), username: "swiftui_dev", profileImageURL: nil), items: []),
            .init(id: UUID(), user: .init(id: UUID(), username: "ios_fan", profileImageURL: nil), items: [])
        ]

        VStack {
            // Loading state
            StoriesTrayView(stories: .constant([]), isLoading: true) { _ in }
                .previewDisplayName("Loading State")

            // Loaded state
            StoriesTrayView(stories: .constant(sampleStories), isLoading: false) { story in
                print("Tapped on story by \(story.user.username)")
            }
            .previewDisplayName("Loaded State")
        }
    }
}
#endif
