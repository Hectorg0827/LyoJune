import SwiftUI

struct CourseOverviewView: View {

    @StateObject private var viewModel: CourseOverviewViewModel

    private let course: Course

    init(course: Course, viewModel: CourseOverviewViewModel) {
        self.course = course
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                courseHeader
                lessonsSection
            }
            .padding(.horizontal)
        }
        .navigationTitle(course.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchLessons()
        }
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    private var courseHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Placeholder for a larger course image if available
            AsyncImage(url: course.thumbnailURL) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Rectangle().fill(Color.gray.opacity(0.3)).aspectRatio(16/9, contentMode: .fit)
                }
            }
            .frame(height: 200)
            .cornerRadius(16)

            Text(course.title)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(course.description)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var lessonsSection: some View {
        VStack(alignment: .leading) {
            Text("Lessons")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 8)

            switch viewModel.viewState {
            case .loading:
                VStack {
                    ForEach(0..<3) { _ in
                        Text("Placeholder Lesson Title").redacted(reason: .placeholder)
                            .padding(.vertical, 8)
                        Divider()
                    }
                }
            case .loaded:
                ForEach(viewModel.lessons) { lesson in
                    VStack(alignment: .leading) {
                        NavigationLink(destination: Text("Lesson Details for \(lesson.title)")) {
                            HStack {
                                Text(lesson.title)
                                Spacer()
                                Text("\(lesson.durationMinutes) min")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                        Divider()
                    }
                }
            case .empty:
                Text("No lessons available for this course yet.")
                    .foregroundColor(.secondary)
                    .padding()
            case .error:
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Failed to load lessons.")
                }
                .padding()
            }
        }
    }
}

#if DEBUG
struct CourseOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        let course = Course(
            id: UUID(),
            title: "Intro to SwiftUI",
            description: "Learn the basics of building apps with SwiftUI.",
            thumbnailURL: nil
        )
        let service = MockLearnService_ForPreview()
        let viewModel = CourseOverviewViewModel(course: course, learnService: service)

        NavigationStack {
            CourseOverviewView(course: course, viewModel: viewModel)
        }
    }

    private class MockLearnService_ForPreview: LearnServicing {
        func fetchAllCourses() async throws -> [Course] { [] }
        func fetchLessons(for courseId: UUID) async throws -> [Lesson] {
            try await Task.sleep(nanoseconds: 1_500_000_000)
            return [
                .init(id: UUID(), title: "Building Your First View", content: "", durationMinutes: 10),
                .init(id: UUID(), title: "State and Bindings", content: "", durationMinutes: 15)
            ]
        }
        func fetchAllResources() async throws -> [Resource] { [] }
    }
}
#endif
