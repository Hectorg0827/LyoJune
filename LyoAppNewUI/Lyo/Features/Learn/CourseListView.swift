import SwiftUI

struct CourseListView: View {

    // In a real app, the ViewModel would be injected by a DI container or parent view.
    // For simplicity here, we initialize it directly. A factory would be a good pattern.
    @StateObject private var viewModel: CourseListViewModel

    // Custom initializer for dependency injection
    init(viewModel: CourseListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Courses")
                .toast(toast: $viewModel.errorToast)
                .onAppear {
                    // Fetch courses only if the list is empty, to avoid re-fetching on every view appearance.
                    if viewModel.courses.isEmpty {
                        viewModel.fetchCourses()
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .loading:
            // Show skeleton placeholders while loading
            List {
                ForEach(0..<5) { _ in
                    CourseRowView(course: .placeholder)
                        .redacted(reason: .placeholder)
                }
            }
            .listStyle(.plain)

        case .loaded:
            // Show the list of courses
            List(viewModel.courses) { course in
                let overviewViewModel = CourseOverviewViewModel(
                    course: course,
                    learnService: viewModel.learnService
                )
                NavigationLink(destination: CourseOverviewView(course: course, viewModel: overviewViewModel)) {
                    CourseRowView(course: course)
                }
            }
            .listStyle(.plain)

        case .empty:
            // Show empty state view
            EmptyStateView(
                image: Image(systemName: "books.vertical.fill"),
                title: "No Courses Available",
                description: "We couldn't find any courses at the moment. Please check back later."
            )

        case .error:
            // Show error state with a retry button
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
        // Simulate a delay
        try await Task.sleep(nanoseconds: 1_500_000_000)

        // Return sample data
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
        // Preview for the loaded state
        let loadedViewModel = CourseListViewModel(learnService: MockLearnService_ForPreview())
        CourseListView(viewModel: loadedViewModel)
            .previewDisplayName("Loaded State")

        // Preview for the empty state
        let emptyService = MockLearnService_ForPreview()
        // How to make it return empty? We need a more robust mock for previews.
        // For now, we can just show the view with an empty array manually.

        // Preview for the loading state
        let loadingViewModel = CourseListViewModel(learnService: MockLearnService_ForPreview())
        // Manually set the state for preview
        // This is tricky. Let's just rely on the delay in the mock.
        CourseListView(viewModel: loadingViewModel)
            .previewDisplayName("Loading State")
    }
}
#endif
