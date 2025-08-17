import SwiftUI

/// A view that displays a multiple-choice question from the tutor.
struct QuestionBubbleView: View {

    let question: Question
    let onOptionSelected: (Question.Option) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Question Text
            Text(question.text)
                .padding(.horizontal, 16)
                .padding(.top, 12)

            // Options
            ForEach(question.options) { option in
                Button(action: {
                    onOptionSelected(option)
                }) {
                    Text(option.text)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(12)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain) // Use plain style to allow custom background
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(Color(.secondarySystemBackground))
        .foregroundColor(.primary)
        .cornerRadius(20)
        .frame(maxWidth: 300, alignment: .leading)
        .padding(.horizontal)
    }
}


#if DEBUG
struct QuestionBubbleView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleQuestion = Question(
            id: UUID(),
            text: "Which of these is a value type in Swift?",
            options: [
                .init(id: "A", text: "Class"),
                .init(id: "B", text: "Struct"),
                .init(id: "C", text: "Actor")
            ]
        )

        QuestionBubbleView(question: sampleQuestion) { option in
            print("User selected option \(option.id): \(option.text)")
        }
        .padding()
    }
}
#endif
