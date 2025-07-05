import SwiftUI

struct StoryViewerView: View {
    @Binding var story: Story?
    @Binding var isPresented: Bool
    @State private var currentProgress: Double = 0
    @State private var timer: Timer?
    
    private let storyDuration: TimeInterval = 5.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let story = story {
                VStack(spacing: 0) {
                    // Progress bars
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 2)
                            .overlay(
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: UIScreen.main.bounds.width * currentProgress, height: 2),
                                alignment: .leading
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 50)
                    
                    // Header
                    HStack {
                        // User info
                        HStack(spacing: 12) {
                            Circle()
                                .fill(LinearGradient(
                                    colors: story.avatarColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(story.initials)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(story.displayName)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text(story.timestamp, style: .relative)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        
                        Spacer()
                        
                        // Close button
                        Button(action: {
                            closeStory()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // Story content
                    Spacer()
                    
                    // Story content based on type
                    Group {
                        switch story.storyType {
                        case .image:
                            if let imageURL = story.previewImageURL {
                                AsyncImage(url: imageURL) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .aspectRatio(9/16, contentMode: .fit)
                                }
                            }
                        case .video:
                            // Video player would go here
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .aspectRatio(9/16, contentMode: .fit)
                                .overlay(
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white)
                                )
                        case .text:
                            Text("CDStory content would appear here")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            startProgress()
        }
        .onDisappear {
            stopProgress()
        }
        .onTapGesture {
            closeStory()
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.y > 100 {
                        closeStory()
                    }
                }
        )
    }
    
    private func startProgress() {
        currentProgress = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            currentProgress += 0.1 / storyDuration
            if currentProgress >= 1.0 {
                closeStory()
            }
        }
    }
    
    private func stopProgress() {
        timer?.invalidate()
        timer = nil
    }
    
    private func closeStory() {
        stopProgress()
        isPresented = false
        story = nil
    }
}

#Preview {
    StoryViewerView(
        story: .constant(Story(
            id: UUID(),
            username: "john_doe",
            displayName: "John Doe",
            initials: "JD",
            avatarColors: [.blue, .purple],
            hasUnwatchedStory: true,
            storyType: .image,
            timestamp: Date(),
            previewImageURL: nil
        )),
        isPresented: .constant(true)
    )
}
