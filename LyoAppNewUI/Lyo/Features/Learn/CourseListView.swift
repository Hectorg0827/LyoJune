import SwiftUI

struct CourseListView: View {

    @StateObject private var viewModel: CourseListViewModel
    @EnvironmentObject private var router: Router

    init(viewModel: CourseListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        // The NavigationStack is now provided by the RootView
        content
            .navigationTitle("Courses")
            .toast(toast: $viewModel.errorToast)
            .onAppear {
                if viewModel.courses.isEmpty {
                    viewModel.fetchCourses()
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .loading:
            List {
                ForEach(0..<5) { _ in
                    CourseRowView(course: .placeholder)
                        .redacted(reason: .placeholder)
                }
            }
            .listStyle(.plain)

        case .loaded:
            List(viewModel.courses) { course in
                Button(action: {
                    router.navigate(to: .courseOverview(courseId: course.id.uuidString))
                }) {
                    CourseRowView(course: course)
                }
                .buttonStyle(.plain) // Use plain style to remove default button chrome
            }
            .listStyle(.plain)

        case .empty:
            EmptyStateView(
                image: Image(systemName: "books.vertical.fill"),
                title: "No Courses Available",
                description: "We couldn't find any courses at the moment. Please check back later."
            )

        case .error:
            EmptyStateView(
                image: Image(systemName: "wifi.slash"),
                title: "An Error Occurred",
                description: "We couldn't load the courses. Please check your connection and try again.",
                actionView: {
                    Button("Retry", action: viewModel.fetchCourses)
                        .buttonStyle(.borderedProminent)
                }
            )
        }
    }
}

// MARK: - Placeholder Data for Skeleton

extension Course {
    static var placeholder: Course {
        .init(
            id: UUID(),
            title: "A Very Long Course Title to Test Redaction",
            description: "This is some placeholder description text that will be redacted.",
            thumbnailURL: nil
        )
    }
}

#if DEBUG
// A mock service for previews
private class MockLearnService_ForPreview: LearnServicing {
    func fetchAllCourses() async throws -> [Course] {
        try await Task.sleep(nanoseconds: 1_500_000_000)
        return [
            .init(id: UUID(), title: "Intro to SwiftUI", description: "Learn the basics.", thumbnailURL: nil),
            .init(id: UUID(), title: "Advanced Concurrency", description: "Go deep on async/await.", thumbnailURL: nil)
        ]
    }
    func fetchLessons(for courseId: UUID) async throws -> [Lesson] { [] }
    func fetchAllResources() async throws -> [Resource] { [] }
}

struct CourseListView_Previews: PreviewProvider {
    static var previews: some View {
        let loadedViewModel = CourseListViewModel(learnService: MockLearnService_ForPreview())

        NavigationStack { // Add a NavStack for previewing purposes
            CourseListView(viewModel: loadedViewModel)
        }
        .environmentObject(Router()) // Add a dummy router for the preview
        .previewDisplayName("Loaded State")
    }
}
#endif
