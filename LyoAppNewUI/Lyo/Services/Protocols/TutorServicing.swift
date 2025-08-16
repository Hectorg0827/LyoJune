import Foundation

/// A protocol that defines the contract for a service that interacts with the Tutor API.
public protocol TutorServicing {

    /// Sends the user's turn (a message or an answer) to the tutor and receives the tutor's response.
    /// - Parameters:
    ///   - text: The text message from the user.
    ///   - selectedOptionId: The ID of the option selected by the user, if they are answering a question.
    /// - Returns: An array of `TutorMessage` objects representing the tutor's response.
    /// - Throws: An `APIError` if the network request fails.
    func postTurn(text: String, selectedOptionId: String?) async throws -> TutorTurnResponse

    /// Fetches the current state of the tutor session for a given learner.
    /// - Parameter learnerId: The ID of the learner.
    /// - Returns: The `TutorState` for the session.
    /// - Throws: An `APIError` if the network request fails.
    func getState(for learnerId: String) async throws -> TutorState

    /// Saves the current state of the tutor session.
    /// - Parameters:
    ///   - learnerId: The ID of the learner.
    ///   - state: The `TutorState` to save.
    /// - Throws: An `APIError` if the network request fails.
    func saveState(for learnerId: String, state: TutorState) async throws
}
