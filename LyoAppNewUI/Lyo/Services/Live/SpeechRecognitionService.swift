import Foundation
import Speech
import AVFoundation

public final class SpeechRecognitionService: SpeechRecognitionServicing {

    // MARK: - Public Properties

    public let transcriptions: AsyncThrowingStream<String, Error>

    // MARK: - Private Properties

    private var transcriptionContinuation: AsyncThrowingStream<String, Error>.Continuation?

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    // MARK: - Initialization

    public init() {
        var continuation: AsyncThrowingStream<String, Error>.Continuation?
        self.transcriptions = AsyncThrowingStream { continuation = $0 }
        self.transcriptionContinuation = continuation
    }

    // MARK: - Public Methods

    public func startListening() throws {
        // Cancel any previous task.
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }

        // Setup audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Setup recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object.")
        }
        recognitionRequest.shouldReportPartialResults = true

        // Setup recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                // Publish the latest transcription string.
                self.transcriptionContinuation?.yield(result.bestTranscription.formattedString)

                // If it's the final result, finish the stream.
                if result.isFinal {
                    self.stopListening()
                    self.transcriptionContinuation?.finish()
                }
            } else if let error = error {
                self.stopListening()
                self.transcriptionContinuation?.finish(throwing: error)
            }
        }

        // Setup audio engine
        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    public func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil
    }

    deinit {
        stopListening()
    }
}
