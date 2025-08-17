import Foundation
import Speech
import AVFoundation

/// A utility to manage permissions for speech recognition and microphone access.
@MainActor
final class SpeechPermissionManager: ObservableObject {

    @Published private(set) var canUseSpeech: Bool = false

    init() {
        // Check initial status
        self.canUseSpeech = SFSpeechRecognizer.authorizationStatus() == .authorized && AVAudioSession.sharedInstance().recordPermission == .granted
    }

    /// Requests speech recognition and microphone permissions from the user.
    /// This method should be called in response to a user action, like tapping a "Enable Voice" button.
    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            // Handle speech recognition permission
            if authStatus == .authorized {
                // Now request microphone permission
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    // Update the state on the main thread
                    DispatchQueue.main.async {
                        self.canUseSpeech = granted
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.canUseSpeech = false
                }
            }
        }
    }
}
