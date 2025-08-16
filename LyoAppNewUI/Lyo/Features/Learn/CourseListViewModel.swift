import Foundation
import Combine

@MainActor
final class CourseListViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var courses: [Course] = []
    @Published private(set) var viewState: ViewState = .loading
    @Published var errorToast: Toast? = nil

    // MARK: - Private Properties

    let learnService: LearnServicing

    // MARK: - Initialization

    init(learnService: LearnServicing) {
        self.learnService = learnService
    }

    // MARK: - Public Intent Methods

    /// Fetches the list of courses from the backend.
    func fetchCourses() {
        // Only show full-screen skeleton on initial load.
        if courses.isEmpty {
            viewState = .loading
        }

        Task {
            do {
                let fetchedCourses = try await learnService.fetchAllCourses()
                self.courses = fetchedCourses
                self.viewState = fetchedCourses.isEmpty ? .empty : .loaded
            } catch {
                self.viewState = .error
                self.errorToast = Toast(message: "Failed to load courses. Please try again.", style: .error)
            }
        }
    }
}

// MARK: - View State Enum

extension CourseListViewModel {
    /// An enum to represent the different states of the view.
    enum ViewState {
        case loading
        case loaded
        case empty
        case error
    }
}
