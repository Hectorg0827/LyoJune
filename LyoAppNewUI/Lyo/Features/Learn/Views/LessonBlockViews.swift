import SwiftUI

// MARK: - Heading View

struct HeadingBlockView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.title2)
            .fontWeight(.bold)
            .padding(.top)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Paragraph View

struct ParagraphBlockView: View {
    // In a real app, this would be an AttributedString to handle Markdown.
    let text: String

    var body: some View {
        Text(text)
            .font(.body)
            .lineSpacing(5)
    }
}

// MARK: - YouTube Video View

struct YouTubeBlockView: View {
    let videoId: String

    private var embedURL: URL? {
        URL(string: "https://www.youtube.com/embed/\(videoId)")
    }

    var body: some View {
        if let url = embedURL {
            WebView(url: url)
                .aspectRatio(16/9, contentMode: .fit)
                .cornerRadius(12)
                .accessibilityLabel("Embedded YouTube video player")
        } else {
            EmptyView()
        }
    }
}

// MARK: - Link View

struct LinkBlockView: View {
    let title: String
    let url: URL

    var body: some View {
        Link(destination: url) {
            HStack {
                VStack(alignment: .leading) {
                    Text("External Resource")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(title)
                        .bold()
                }
                Spacer()
                Image(systemName: "arrow.up.right.square")
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}
