import SwiftUI

/// A view that can display any type of `SearchResultItem`.
/// It switches its appearance based on the item's type (user, post, or course).
struct SearchResultRowView: View {
    let result: SearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // The main content view, which changes based on the result type
            contentView

            // The "Why matched" text, if it exists
            if let whyMatched = result.whyMatched {
                Text(whyMatched)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 16) // Indent to align with content text
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var contentView: some View {
        switch result.item {
        case .user(let user):
            userRow(for: user)
        case .post(let post):
            postRow(for: post)
        case .course(let course):
            // We can reuse the CourseRowView we already built!
            CourseRowView(course: course)
        }
    }

    // MARK: - Sub-row Views

    @ViewBuilder
    private func userRow(for user: User) -> some View {
        HStack {
            AsyncImage(url: user.profileImageURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill").resizable().foregroundColor(.secondary)
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            Text(user.username).font(.headline)
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func postRow(for post: Post) -> some View {
        // A simplified row for a post, as the full FeedPostView is too large here.
        HStack {
            // Using a placeholder for the video thumbnail
            Image(systemName: "video.fill")
                .frame(width: 60, height: 60)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(4)

            VStack(alignment: .leading) {
                Text(post.caption).lineLimit(1)
                Text("@\(post.user.username)").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}
