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
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            messageView(for: message).id(message.id)
                        }
                    }
                    .padding(.vertical)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation { scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom) }
                    }
                }
            }
            if viewModel.isSending { ProgressView().padding(8) }
            inputBar
        }
        .navigationTitle("AI Tutor")
        .background(Color(.systemBackground))
        .onAppear {
            if viewModel.messages.isEmpty { viewModel.loadInitialState() }
        }
        .onChange(of: viewModel.liveTranscript) { newTranscript in
            inputText = newTranscript
        }
    }

    @ViewBuilder
    private func messageView(for message: TutorMessage) -> some View {
        switch message.type {
        case .question:
            if let question = message.question {
                QuestionBubbleView(question: question) { selectedOption in
                    viewModel.answerQuestion(questionId: question.id, option: selectedOption)
                }
            }
        case .tutorial:
            if let tutorial = message.tutorial { TutorialBubbleView(tutorial: tutorial) }
        case .stepByStepGuide:
            if let guide = message.stepByStepGuide { StepByStepGuideBubbleView(guide: guide) }
        default:
            let senderType: SenderType = message.sender == .user ? .user : .other
            let senderName: String? = senderType == .other ? "AI Tutor" : nil
            TextMessageBubble(text: message.text, sender: senderType, senderName: senderName)
        }
    }

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask a question...", text: $inputText, axis: .vertical)
                .padding(10).background(Color(.secondarySystemBackground)).cornerRadius(20).lineLimit(5)
                .disabled(viewModel.isListening)

            if viewModel.isListening {
                ProgressView().progressViewStyle(.circular).tint(.red)
                Button(action: viewModel.toggleListening) {
                    Image(systemName: "stop.circle.fill").font(.title).foregroundColor(.red)
                }
                .accessibilityLabel("Stop listening")
            } else {
                Button(action: {
                    if viewModel.permissionManager.canUseSpeech { viewModel.toggleListening() }
                    else { viewModel.permissionManager.requestPermissions() }
                }) {
                    Image(systemName: "mic.circle.fill").font(.title)
                }
                .disabled(!viewModel.permissionManager.canUseSpeech)
                .accessibilityLabel("Start listening")

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill").font(.title)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel("Send message")
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
            onDeviceAIService: nil, // On-device not available in preview
            router: router,
            aiCoordinator: coordinator
        )
        NavigationStack { TutorView(viewModel: viewModel) }
    }
}
#endif
