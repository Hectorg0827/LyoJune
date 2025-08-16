import SwiftUI

/// A reusable view for displaying an empty state to the user.
/// This is used when a data-driven view has no content to show (e.g., an empty inbox, no search results).
public struct EmptyStateView<ActionView: View>: View {

    private let image: Image?
    private let title: String
    private let description: String
    private let actionView: ActionView?

    /// Creates a new `EmptyStateView`.
    /// - Parameters:
    ///   - image: An optional `Image` to display at the top. Use `nil` for no image.
    ///   - title: The main headline for the empty state.
    ///   - description: A more detailed message explaining the state.
    ///   - actionView: An optional closure that returns a view for a call to action, like a `Button`.
    public init(
        image: Image? = nil,
        title: String,
        description: String,
        @ViewBuilder actionView: () -> ActionView? = { nil }
    ) {
        self.image = image
        self.title = title
        self.description = description
        self.actionView = actionView()
    }

    public var body: some View {
        VStack(spacing: 24) {
            if let image = image {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let actionView = actionView {
                actionView
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Convenience Initializer without Action

extension EmptyStateView where ActionView == EmptyView {
    public init(image: Image?, title: String, description: String) {
        self.init(image: image, title: title, description: description, actionView: { nil })
    }
}


#if DEBUG
struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Example 1: With an SF Symbol and a retry button
            EmptyStateView(
                image: Image(systemName: "wifi.slash"),
                title: "No Connection",
                description: "We couldn't connect to the server. Please check your internet connection and try again.",
                actionView: {
                    Button(action: { print("Retry tapped") }) {
                        Text("Retry")
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            )
            .previewDisplayName("With Action")

            // Example 2: Simple text-only empty state
            EmptyStateView(
                title: "No Messages",
                description: "When you start a new conversation, it will appear here."
            )
            .previewDisplayName("Text Only")
        }
    }
}
#endif
