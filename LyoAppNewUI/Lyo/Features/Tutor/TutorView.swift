import SwiftUI

struct TutorView: View {

    @StateObject private var viewModel: TutorViewModel
    @State private var inputText: String = ""

    // Custom initializer for dependency injection
    init(viewModel: TutorViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            messageView(for: message)
                                .id(message.id)
                        }
                    }
                    .padding(.vertical)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    // Auto-scroll to the bottom when a new message arrives
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            if viewModel.isSending {
                ProgressView()
                    .padding(8)
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
            if let tutorial = message.tutorial {
                TutorialBubbleView(tutorial: tutorial)
            }
        case .stepByStepGuide:
            if let guide = message.stepByStepGuide {
                StepByStepGuideBubbleView(guide: guide)
            }
        default:
            let senderType: SenderType = message.sender == .user ? .user : .other
            TextMessageBubble(text: message.text, sender: senderType)
        }
    }

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask a question...", text: $inputText, axis: .vertical)
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(20)
                .lineLimit(5)

            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .background(.thinMaterial)
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        viewModel.sendMessage(text)
        inputText = ""
    }
}

#if DEBUG
struct TutorView_Previews: PreviewProvider {
    static var previews: some View {
        // You would need a more robust mock service to preview a full conversation.
        let service = MockTutorService()
        let viewModel = TutorViewModel(tutorService: service)

        NavigationStack {
            TutorView(viewModel: viewModel)
        }
    }
}
#endif
