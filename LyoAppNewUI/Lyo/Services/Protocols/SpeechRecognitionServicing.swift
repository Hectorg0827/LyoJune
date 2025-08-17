import Foundation

/// A protocol that defines the contract for a service that performs live speech recognition.
public protocol SpeechRecognitionServicing {

    /// An asynchronous stream that yields transcription results as they are recognized.
    var transcriptions: AsyncThrowingStream<String, Error> { get }

    /// Starts the audio engine and begins listening for speech.
    /// Transcribed text will be published to the `transcriptions` stream.
    /// - Throws: An error if the audio engine or speech recognizer fails to start.
    func startListening() throws

    /// Stops the audio engine and ends the current recognition task.
    func stopListening()
}
