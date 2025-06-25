import SwiftUI

struct AITranscriptBubble: View {
    let message: AIMessage
    let isVisible: Bool
    @State private var animationOffset: CGFloat = 20
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.sender == .user {
                Spacer()
                userMessageBubble
            } else {
                aiMessageBubble
                Spacer()
            }
        }
        .padding(.horizontal)
        .offset(y: animationOffset)
        .opacity(opacity)
        .scaleEffect(scale)
        .onAppear {
            animateAppearance()
        }
        .onChange(of: isVisible) { _, visible in
            if visible {
                animateAppearance()
            } else {
                animateDisappearance()
            }
        }
    }
    
    private var userMessageBubble: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(message.content)
                .font(.body)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            
            messageMetadata
        }
        .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .trailing)
    }
    
    private var aiMessageBubble: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                // AI Avatar indicator
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [.purple, .blue]),
                            center: .center,
                            startRadius: 5,
                            endRadius: 15
                        )
                    )
                    .frame(width: 30, height: 30)
                    .overlay(
                        Image(systemName: "brain.head.profile")
                            .font(.caption)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                    // Message content
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Material.ultraThin)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.purple.opacity(0.5), .blue.opacity(0.5)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                    
                    // AI suggestions if available
                    if let suggestions = getSuggestions() {
                        SuggestionsView(suggestions: suggestions)
                    }
                    
                    // Emotion indicator
                    if let emotion = getEmotion() {
                        EmotionIndicator(emotion: emotion)
                    }
                }
            }
            
            messageMetadata
        }
        .frame(maxWidth: UIScreen.main.bounds.width * 0.8, alignment: .leading)
    }
    
    private var messageMetadata: some View {
        HStack(spacing: 8) {
            // Timestamp
            Text(formatTimestamp(message.timestamp))
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
            
            // Confidence indicator for AI messages
            if message.sender == .ai, let confidence = message.confidence {
                HStack(spacing: 2) {
                    Image(systemName: "brain.head.profile")
                        .font(.caption2)
                        .foregroundColor(confidenceColor(confidence))
                    
                    Text("\(Int(confidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(confidenceColor(confidence))
                }
            }
            
            // Audio indicator
            if message.audioURL != nil {
                Button(action: {
                    // Play audio
                }) {
                    Image(systemName: "speaker.wave.2")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            
            // Message type indicator
            messageTypeIcon
        }
        .padding(.horizontal, 4)
    }
    
    private var messageTypeIcon: some View {
        Group {
            switch message.messageType {
            case .voice:
                Image(systemName: "waveform")
                    .foregroundColor(.green)
            case .suggestion:
                Image(systemName: "lightbulb")
                    .foregroundColor(.yellow)
            case .emotion:
                Image(systemName: "heart")
                    .foregroundColor(.pink)
            case .error:
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.red)
            default:
                Image(systemName: "text.bubble")
                    .foregroundColor(.blue)
            }
        }
        .font(.caption2)
    }
    
    private func getSuggestions() -> [String]? {
        // In a real implementation, this would extract suggestions from the message
        // For now, return mock suggestions for AI messages
        if message.sender == .ai && message.content.contains("suggest") {
            return ["Try a practice quiz", "Review the lesson", "Ask for clarification"]
        }
        return nil
    }
    
    private func getEmotion() -> GemmaAPIResponse.EmotionState? {
        // In a real implementation, this would extract emotion from the message
        // For now, return a random emotion for demonstration
        if message.sender == .ai {
            return .encouraging
        }
        return nil
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        switch confidence {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return .yellow
        default:
            return .orange
        }
    }
    
    private func animateAppearance() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
            animationOffset = 0
            opacity = 1
            scale = 1.0
        }
    }
    
    private func animateDisappearance() {
        withAnimation(.easeInOut(duration: 0.3)) {
            animationOffset = -20
            opacity = 0
            scale = 0.9
        }
    }
}

struct SuggestionsView: View {
    let suggestions: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Suggestions:")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.8))
            
            ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                Button(action: {
                    // Handle suggestion tap
                }) {
                    HStack {
                        Text("• \(suggestion)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.top, 4)
    }
}

struct EmotionIndicator: View {
    let emotion: GemmaAPIResponse.EmotionState
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: emotionIcon)
                .font(.caption)
                .foregroundColor(emotionColor)
            
            Text(emotion.rawValue.capitalized)
                .font(.caption2)
                .foregroundColor(emotionColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(emotionColor.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(emotionColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var emotionIcon: String {
        switch emotion {
        case .neutral:
            return "face.dashed"
        case .encouraging:
            return "hand.thumbsup"
        case .explaining:
            return "book"
        case .questioning:
            return "questionmark.circle"
        case .celebrating:
            return "party.popper"
        case .concerned:
            return "exclamationmark.circle"
        }
    }
    
    private var emotionColor: Color {
        switch emotion {
        case .neutral:
            return .gray
        case .encouraging:
            return .green
        case .explaining:
            return .blue
        case .questioning:
            return .orange
        case .celebrating:
            return .yellow
        case .concerned:
            return .red
        }
    }
}

struct AITranscriptBubble_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // User message
            AITranscriptBubble(
                message: AIMessage(
                    content: "How do I implement a for loop in Swift?",
                    sender: .user,
                    timestamp: Date(),
                    messageType: .text,
                    confidence: nil,
                    audioURL: nil
                ),
                isVisible: true
            )
            
            // AI response with suggestions
            AITranscriptBubble(
                message: AIMessage(
                    content: "Great question! A for loop in Swift allows you to iterate over sequences. Here's how you can use it: `for item in collection { /* code */ }`. Let me suggest some practice exercises to help you master this concept.",
                    sender: .ai,
                    timestamp: Date(),
                    messageType: .text,
                    confidence: 0.95,
                    audioURL: nil
                ),
                isVisible: true
            )
            
            // Voice message
            AITranscriptBubble(
                message: AIMessage(
                    content: "I heard you say 'help with arrays'. Let me explain arrays in Swift...",
                    sender: .ai,
                    timestamp: Date(),
                    messageType: .voice,
                    confidence: 0.87,
                    audioURL: URL(string: "example.mp3")
                ),
                isVisible: true
            )
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.black, .purple.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}