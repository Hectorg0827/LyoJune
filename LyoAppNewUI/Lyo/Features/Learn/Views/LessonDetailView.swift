import SwiftUI

/// The main "AI Classroom" view, responsible for rendering the content of a single lesson.
struct LessonDetailView: View {

    let lesson: Lesson

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Lesson Title
                Text(lesson.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom)

                // Render each content block
                ForEach(lesson.contentBlocks, id: \.self) { block in
                    lessonBlockView(for: block)
                }
            }
            .padding()
        }
        .navigationTitle(lesson.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    /// A view builder that returns the correct view for a given `LessonBlock`.
    @ViewBuilder
    private func lessonBlockView(for block: LessonBlock) -> some View {
        switch block {
        case .heading(let text):
            HeadingBlockView(text: text)
        case .paragraph(let text):
            ParagraphBlockView(text: text)
        case .youtubeVideo(let videoId):
            YouTubeBlockView(videoId: videoId)
        case .link(let title, let url):
            LinkBlockView(title: title, url: url)
        }
    }
}

#if DEBUG
struct LessonDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleLesson = Lesson(
            id: UUID(),
            title: "The Basics of SwiftUI",
            contentBlocks: [
                .heading("Introduction"),
                .paragraph("SwiftUI is a modern way to declare user interfaces for any Apple platform. Create beautiful, dynamic apps faster than ever before."),
                .heading("Key Concepts"),
                .paragraph("Understanding Views, State, and Bindings is crucial for success."),
                .youtubeVideo(videoId: "dQw4w9WgXcQ"),
                .link(title: "Official SwiftUI Documentation", url: URL(string: "https://developer.apple.com/xcode/swiftui/")!)
            ]
        )

        return NavigationStack {
            LessonDetailView(lesson: sampleLesson)
        }
    }
}
#endif
