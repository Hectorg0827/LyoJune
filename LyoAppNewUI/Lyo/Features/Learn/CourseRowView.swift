import SwiftUI

/// A view that displays a single course as a row in a list.
struct CourseRowView: View {
    let course: Course

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Thumbnail Image
            AsyncImage(url: course.thumbnailURL) { phase in
                switch phase {
                case .empty:
                    // Placeholder while loading
                    LoadingSkeleton()
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    // Placeholder for a failed image load
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.gray.opacity(0.3))
                @unknown default:
                    EmptyView()
                }
            }
            .accessibilityLabel(Text("Thumbnail for \(course.title)"))
            .frame(width: 100, height: 100)
            .cornerRadius(12)
            .clipped()

            // Course Details
            VStack(alignment: .leading, spacing: 6) {
                Text(course.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(2)

                Text(course.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            // Add a spacer to push content to the left
            Spacer()
        }
        .padding(.vertical, 12)
    }
}

#if DEBUG
struct CourseRowView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleCourse = Course(
            id: UUID(),
            title: "Introduction to Modern SwiftUI",
            description: "Learn the latest techniques and best practices for building beautiful and responsive apps with SwiftUI.",
            thumbnailURL: URL(string: "https://example.com/image.png")
        )

        CourseRowView(course: sampleCourse)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif
