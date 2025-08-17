import Foundation

@MainActor
final class CourseOverviewViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var lessons: [Lesson] = []
    @Published private(set) var viewState: ViewState = .loading

    // MARK: - Private Properties

    private let course: Course
    private let learnService: LearnServicing

    // MARK: - Initialization

    init(course: Course, learnService: LearnServicing) {
        self.course = course
        self.learnService = learnService
    }

    // MARK: - Public Intent Methods

    /// Fetches the list of lessons for the current course.
    func fetchLessons() {
        viewState = .loading

        Task {
            do {
                let fetchedLessons = try await learnService.fetchLessons(for: course.id)
                self.lessons = fetchedLessons
                self.viewState = fetchedLessons.isEmpty ? .empty : .loaded
            } catch {
                self.viewState = .error
                // Errors will be displayed by the view based on this state.
            }
        }
    }
}

// MARK: - View State Enum

extension CourseOverviewViewModel {
    /// An enum to represent the different states of the lesson list.
    enum ViewState {
        case loading
        case loaded
        case empty
        case error
    }
}
