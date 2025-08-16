import Foundation

/// A namespace for creating API endpoints related to the "Tutor" feature.
enum TutorEndpoint {

    /// Creates an endpoint to send a user's turn (a message or an answer) to the tutor.
    /// - Parameters:
    ///   - text: The text message from the user.
    ///   - selectedOptionId: The ID of the option selected by the user, if they are answering a question.
    /// - Returns: An `Endpoint` configured to fetch the tutor's response.
    static func postTurn(text: String, selectedOptionId: String?) -> Endpoint<TutorTurnResponse> {
        let requestBody = TutorTurnRequest(text: text, selectedOptionId: selectedOptionId)
        return try! Endpoint(
            path: "/v1/tutor/turn",
            method: .post,
            encodableBody: requestBody
        )
    }

    /// Creates an endpoint to fetch the tutor state for a specific learner.
    /// - Parameter learnerId: The ID of the learner.
    /// - Returns: An `Endpoint` configured to fetch the `TutorState`.
    static func getState(for learnerId: String) -> Endpoint<TutorState> {
        return Endpoint(path: "/v1/tutor/state/\(learnerId)", method: .get)
    }

    /// Creates an endpoint to save (or update) the tutor state for a learner.
    /// - Parameters:
    ///   - learnerId: The ID of the learner.
    ///   - state: The `TutorState` object to save.
    /// - Returns: An `Endpoint` that expects an empty response on success.
    static func saveState(for learnerId: String, state: TutorState) -> Endpoint<EmptyResponse> {
        return try! Endpoint(
            path: "/v1/tutor/state/\(learnerId)",
            method: .put,
            encodableBody: state
        )
    }
}
