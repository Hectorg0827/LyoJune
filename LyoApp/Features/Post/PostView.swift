import SwiftUI

struct PostView: View {
    @State private var selectedType: ContentType = .video
    @State private var isRecording = false
    @State private var showingMediaPicker = false
    
    enum ContentType: String, CaseIterable {
        case video = "Video"
        case text = "Text"
        case quiz = "Quiz"
        case tutorial = "Tutorial"
        
        var icon: String {
            switch self {
            case .video: return "video"
            case .text: return "text.alignleft"
            case .quiz: return "questionmark.circle"
            case .tutorial: return "play.rectangle.on.rectangle"
            }
        }
        
        var color: Color {
            switch self {
            case .video: return .red
            case .text: return .blue
            case .quiz: return .green
            case .tutorial: return .purple
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.1), Color.gray.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Create Content")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Share your knowledge with the learning community")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Content type selector
                    ContentTypeSelector(selectedType: $selectedType)
                    
                    // Create button
                    CreateContentButton(
                        type: selectedType,
                        isRecording: $isRecording,
                        showingMediaPicker: $showingMediaPicker
                    )
                    
                    Spacer()
                    
                    // Quick actions
                    QuickActionsSection()
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationBarHidden(true)
        }
    }
}

struct ContentTypeSelector: View {
    @Binding var selectedType: PostView.ContentType
    
    var body: some View {
        VStack(spacing: 16) {
            Text("What would you like to create?")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(PostView.ContentType.allCases, id: \.self) { type in
                    ContentTypeCard(
                        type: type,
                        isSelected: selectedType == type,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedType = type
                            }
                        }
                    )
                }
            }
        }
    }
}

struct ContentTypeCard: View {
    let type: PostView.ContentType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Circle()
                    .fill(type.color.opacity(isSelected ? 0.8 : 0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: type.icon)
                            .font(.title2)
                            .foregroundColor(.white)
                    )
                    .overlay(
                        Circle()
                            .stroke(type.color, lineWidth: isSelected ? 2 : 0)
                    )
                
                Text(type.rawValue)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Material.ultraThin)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? type.color : Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct CreateContentButton: View {
    let type: PostView.ContentType
    @Binding var isRecording: Bool
    @Binding var showingMediaPicker: Bool
    
    var body: some View {
        Button(action: handleCreateAction) {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.title2)
                
                Text("Create \(type.rawValue)")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [type.color, type.color.opacity(0.7)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: type.color.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .scaleEffect(isRecording ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isRecording)
    }
    
    private func handleCreateAction() {
        switch type {
        case .video:
            isRecording = true
            // Navigate to video recorder
        case .text:
            // Navigate to text editor
            break
        case .quiz:
            // Navigate to quiz creator
            break
        case .tutorial:
            // Navigate to tutorial builder
            break
        }
    }
}

struct QuickActionsSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                CircularActionButton(
                    title: "Drafts",
                    icon: "doc.text",
                    color: .orange,
                    action: {}
                )
                
                CircularActionButton(
                    title: "Templates",
                    icon: "rectangle.stack",
                    color: .purple,
                    action: {}
                )
                
                CircularActionButton(
                    title: "Collaborate",
                    icon: "person.2",
                    color: .green,
                    action: {}
                )
            }
        }
    }
}

struct CircularActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(color)
                    )
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    PostView()
}