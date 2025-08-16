import Foundation
@testable import LyoApp

/// A mock implementation of the `TutorServicing` protocol for use in unit tests.
final class MockTutorService: TutorServicing {

    // MARK: - Post Turn

    /// The result to return when `postTurn` is called.
    var postTurnResult: Result<TutorTurnResponse, APIError> = .success([])

    /// The number of times `postTurn` has been called.
    private(set) var postTurnCallCount = 0

    /// The last text passed to the `postTurn` method.
    private(set) var lastPostTurnText: String?

    /// The last option ID passed to the `postTurn` method.
    private(set) var lastPostTurnOptionId: String?

    func postTurn(text: String, selectedOptionId: String?) async throws -> TutorTurnResponse {
        postTurnCallCount += 1
        lastPostTurnText = text
        lastPostTurnOptionId = selectedOptionId

        switch postTurnResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }

    // MARK: - Get State

    /// The result to return when `getState` is called.
    var getStateResult: Result<TutorState, APIError> = .success(.init(learnerId: "test", history: []))

    /// The number of times `getState` has been called.
    private(set) var getStateCallCount = 0

    func getState(for learnerId: String) async throws -> TutorState {
        getStateCallCount += 1
        switch getStateResult {
        case .success(let state):
            return state
        case .failure(let error):
            throw error
        }
    }

    // MARK: - Save State

    /// An optional error to throw when `saveState` is called.
    var saveStateError: APIError?

    /// The number of times `saveState` has been called.
    private(set) var saveStateCallCount = 0

    func saveState(for learnerId: String, state: TutorState) async throws {
        saveStateCallCount += 1
        if let error = saveStateError {
            throw error
        }
    }

    /// A convenience method to reset all call counts and tracked properties.
    func reset() {
        postTurnCallCount = 0
        lastPostTurnText = nil
        lastPostTurnOptionId = nil
        getStateCallCount = 0
        saveStateCallCount = 0
    }
}
