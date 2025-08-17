import SwiftUI

/// A view for displaying a `Tutorial` object in the chat.
struct TutorialBubbleView: View {
    let tutorial: Tutorial

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(tutorial.title)
                .font(.headline).bold()
            // In a real app, this would render Markdown content.
            Text(tutorial.content)
                .font(.body)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
        .frame(maxWidth: 300, alignment: .leading)
        .padding(.horizontal)
    }
}

/// A view for displaying a `StepByStepGuide` object in the chat.
struct StepByStepGuideBubbleView: View {
    let guide: StepByStepGuide

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(guide.title)
                .font(.headline).bold()

            ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top) {
                    Text("\(index + 1).")
                    Text(step)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
        .frame(maxWidth: 300, alignment: .leading)
        .padding(.horizontal)
    }
}
