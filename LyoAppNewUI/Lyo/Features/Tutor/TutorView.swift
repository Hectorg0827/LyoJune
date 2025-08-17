import SwiftUI

struct TutorView: View {

    @StateObject private var viewModel: TutorViewModel
    @State private var inputText: String = ""

    init(viewModel: TutorViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { scrollViewProxy in
                // ... (ScrollView content is the same)
            }

            if viewModel.isSending {
                ProgressView().padding(8)
            }

            inputBar
        }
        .navigationTitle("AI Tutor")
        .background(Color(.systemBackground))
        .onAppear {
            if viewModel.messages.isEmpty {
                viewModel.loadInitialState()
            }
        }
        // Update the text field with the live transcript
        .onChange(of: viewModel.liveTranscript) { newTranscript in
            inputText = newTranscript
        }
    }

    @ViewBuilder
    private func messageView(for message: TutorMessage) -> some View {
        // ... (same as before)
    }

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask a question...", text: $inputText, axis: .vertical)
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(20)
                .lineLimit(5)
                .disabled(viewModel.isListening) // Disable while listening

            if viewModel.isListening {
                // Show a listening indicator
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.red)

                Button(action: viewModel.toggleListening) {
                    Image(systemName: "stop.circle.fill")
                        .font(.title)
                        .foregroundColor(.red)
                }
            } else {
                // Show the microphone button
                Button(action: {
                    if viewModel.permissionManager.canUseSpeech {
                        viewModel.toggleListening()
                    } else {
                        viewModel.permissionManager.requestPermissions()
                    }
                }) {
                    Image(systemName: "mic.circle.fill")
                        .font(.title)
                }
                .disabled(!viewModel.permissionManager.canUseSpeech) // Disabled until permission granted

                // Show the send button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .background(.thinMaterial)
        .animation(.default, value: viewModel.isListening)
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        HapticManager.impact(style: .light)
        viewModel.sendMessage(text)
        inputText = ""
    }
}

#if DEBUG
struct TutorView_Previews: PreviewProvider {
    static var previews: some View {
        let tutorService = MockTutorService()
        let aiService = MockAIGeneratorService()
        let speechService = MockSpeechRecognitionService()
        let router = Router()
        let coordinator = AICoordinator()
        let viewModel = TutorViewModel(
            tutorService: tutorService,
            aiGeneratorService: aiService,
            speechService: speechService,
            router: router,
            aiCoordinator: coordinator
        )

        NavigationStack {
            TutorView(viewModel: viewModel)
        }
    }

    // A mock for previewing purposes
    private class MockSpeechRecognitionService: SpeechRecognitionServicing {
        var transcriptions: AsyncThrowingStream<String, Error> { .init { _ in } }
        func startListening() throws {}
        func stopListening() {}
    }
}
#endif
