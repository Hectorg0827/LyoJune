import SwiftUI
import Speech

struct StudyBuddyFAB: View {
    @StateObject private var voiceManager = GemmaVoiceManager()
    @StateObject private var audioPlayer = AIAudioPlayer()
    @StateObject private var conversationSession = ConversationSession()
    @StateObject private var proactiveManager = ProactiveAIManager(config: .default)
    @State private var config = StudyBuddyConfig.default
    
    @State private var isExpanded = false
    @State private var showingTranscript = false
    @State private var animationState: AvatarAnimationState = .idle
    @State private var mouthIntensity: Double = 0.0
    @State private var textInput = ""
    @State private var isKeyboardVisible = false
    
    // FAB position and drag state
    @State private var fabPosition = CGPoint(x: UIScreen.main.bounds.width - 80, y: UIScreen.main.bounds.height - 200)
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    
    let screenContext: String
    
    init(screenContext: String = "home") {
        self.screenContext = screenContext
    }
    
    var body: some View {
        ZStack {
            // Full-screen overlay when expanded
            if isExpanded {
                fullScreenOverlay
                    .transition(.opacity.combined(with: .scale))
            } else {
                // Floating Action Button
                floatingActionButton
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            setupStudyBuddy()
        }
        .onReceive(proactiveManager.$shouldShowProactiveMessage) { shouldShow in
            if shouldShow && !isExpanded {
                showProactiveMessage()
            }
        }
        .onChange(of: voiceManager.isListening) { _, isListening in
            animationState = isListening ? .listening : .idle
        }
        .onChange(of: audioPlayer.isSpeaking) { _, isSpeaking in
            animationState = isSpeaking ? .speaking : .idle
        }
        .onChange(of: audioPlayer.mouthMovementIntensity) { _, intensity in
            mouthIntensity = intensity
            if intensity > 0 {
                animationState = .mouthMoving(intensity: intensity)
            }
        }
    }
    
    private var floatingActionButton: some View {
        Button(action: {
            expandStudyBuddy()
        }) {
            ZStack {
                // FAB background with glassmorphism
                Circle()
                    .fill(Material.ultraThin)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue.opacity(0.8), .purple.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .background(
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [.blue.opacity(0.4), .purple.opacity(0.2)]),
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 40
                                )
                            )
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                
                // Avatar or activity indicator
                if voiceManager.isListening || audioPlayer.isSpeaking {
                    EnhancedLyoAvatarView(
                        animationState: $animationState,
                        mouthIntensity: $mouthIntensity,
                        size: 50,
                        enableAdvancedFeatures: false,
                        enableParticles: false,
                        enableThoughts: false
                    )
                } else {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundColor(.white)
                        .scaleEffect(voiceManager.isProcessing ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: voiceManager.isProcessing)
                }
                
                // Activity pulse indicator
                if voiceManager.isListening {
                    Circle()
                        .stroke(Color.green.opacity(0.6), lineWidth: 2)
                        .scaleEffect(1.5)
                        .opacity(0.7)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: voiceManager.isListening)
                }
                
                if audioPlayer.isSpeaking {
                    Circle()
                        .stroke(Color.blue.opacity(0.6), lineWidth: 2)
                        .scaleEffect(1.3)
                        .opacity(0.5)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: audioPlayer.isSpeaking)
                }
            }
        }
        .frame(width: 60, height: 60)
        .accessibilityLabel("Study Buddy AI Assistant")
        .accessibilityHint("Tap to open AI study assistant. Double-tap to start voice interaction.")
        .accessibilityAddTraits(voiceManager.isListening ? .isSelected : [])
        .position(
            x: fabPosition.x + dragOffset.width,
            y: fabPosition.y + dragOffset.height
        )
        .scaleEffect(isDragging ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                    }
                    dragOffset = value.translation
                }
                .onEnded { value in
                    isDragging = false
                    
                    // Snap to edges
                    let newPosition = CGPoint(
                        x: fabPosition.x + value.translation.width,
                        y: fabPosition.y + value.translation.height
                    )
                    
                    fabPosition = snapToEdge(position: newPosition)
                    dragOffset = .zero
                }
        )
    }
    
    private var fullScreenOverlay: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    collapseStudyBuddy()
                }
            
            VStack(spacing: 0) {
                // Header
                studyBuddyHeader
                
                // Main content
                GeometryReader { geometry in
                    VStack(spacing: 20) {
                        // Enhanced Avatar
                        EnhancedLyoAvatarView(
                            animationState: $animationState,
                            mouthIntensity: $mouthIntensity,
                            size: 120,
                            enableAdvancedFeatures: true,
                            enableParticles: true,
                            enableThoughts: true
                        )
                        .padding(.top, 20)
                        
                        // Conversation area
                        if showingTranscript && !conversationSession.messages.isEmpty {
                            conversationView
                        } else {
                            welcomeView
                        }
                        
                        Spacer()
                        
                        // Input area
                        inputSection
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.8),
                            Color.purple.opacity(0.3),
                            Color.blue.opacity(0.2)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .cornerRadius(20)
                .padding()
            }
        }
    }
    
    private var studyBuddyHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Study Buddy")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(getStatusText())
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                // Transcript toggle
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showingTranscript.toggle()
                    }
                }) {
                    Image(systemName: showingTranscript ? "text.bubble.fill" : "text.bubble")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
                
                // Settings
                Button(action: {
                    // Show settings
                }) {
                    Image(systemName: "gearshape")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.title3)
                }
                
                // Close button
                Button(action: {
                    collapseStudyBuddy()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.title2)
                }
            }
        }
        .padding()
        .background(Material.ultraThin)
    }
    
    private var welcomeView: some View {
        VStack(spacing: 20) {
            Text("Hi! I'm your Study Buddy")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("I'm here to help you learn, practice, and grow. You can speak to me or type your questions!")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(
                    icon: "questionmark.circle",
                    title: "Ask Question",
                    color: .blue
                ) {
                    startVoiceInput()
                }
                
                QuickActionButton(
                    icon: "book",
                    title: "Explain Topic",
                    color: .green
                ) {
                    // Handle explain topic
                }
                
                QuickActionButton(
                    icon: "quiz",
                    title: "Practice Quiz",
                    color: .orange
                ) {
                    // Handle practice quiz
                }
                
                QuickActionButton(
                    icon: "lightbulb",
                    title: "Study Tips",
                    color: .purple
                ) {
                    // Handle study tips
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    private var conversationView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(conversationSession.messages) { message in
                        AITranscriptBubble(
                            message: message,
                            isVisible: true
                        )
                        .id(message.id)
                    }
                }
                .padding(.vertical)
            }
            .onChange(of: conversationSession.messages.count) { _, _ in
                if let lastMessage = conversationSession.messages.last {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var inputSection: some View {
        VStack(spacing: 12) {
            // Voice/Text input toggle
            HStack {
                // Voice input button
                Button(action: {
                    toggleVoiceInput()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: voiceManager.isListening ? "mic.fill" : "mic")
                            .foregroundColor(voiceManager.isListening ? .red : .white)
                            .font(.title3)
                        
                        Text(voiceManager.isListening ? "Listening..." : "Voice")
                            .foregroundColor(.white)
                            .font(.body)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Material.ultraThin)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(voiceManager.isListening ? Color.red : Color.blue, lineWidth: 1)
                            )
                    )
                }
                .disabled(!voiceManager.voiceEnabled)
                
                Spacer()
                
                // Text input field
                HStack {
                    TextField("Type your message...", text: $textInput)
                        .foregroundColor(.white)
                        .textFieldStyle(PlainTextFieldStyle())
                        .accessibilityLabel("Message input field")
                        .accessibilityHint("Type your question or message for the AI assistant")
                    
                    if !textInput.isEmpty {
                        Button(action: {
                            sendTextMessage()
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Material.ultraThin)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    private func setupStudyBuddy() {
        conversationSession.startSession(context: screenContext)
        
        // Setup audio player callbacks for avatar animation
        audioPlayer.onSpeechStart = {
            animationState = .speaking
        }
        
        audioPlayer.onSpeechEnd = {
            animationState = .idle
        }
        
        audioPlayer.onWordSpoken = { word, intensity in
            mouthIntensity = intensity
        }
        
        // Setup proactive manager
        proactiveManager.updateCurrentScreen(screenContext)
    }
    
    private func expandStudyBuddy() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isExpanded = true
        }
        
        // Record user interaction for proactive manager
        proactiveManager.recordUserInteraction()
        
        // Start session if not active
        if !conversationSession.isActive {
            conversationSession.startSession(context: screenContext)
        }
    }
    
    private func showProactiveMessage() {
        guard let message = proactiveManager.currentProactiveMessage else { return }
        
        // Add proactive message to conversation
        conversationSession.addAIMessage(message, emotion: proactiveManager.proactiveMessageEmotion.toGemmaEmotion)
        
        // Speak the proactive message
        audioPlayer.speak(message, emotion: proactiveManager.proactiveMessageEmotion.toGemmaEmotion)
        
        // Show expanded view briefly or use a popup
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isExpanded = true
            showingTranscript = true
        }
        
        // Update animation based on emotion
        switch proactiveManager.proactiveMessageEmotion {
        case .celebrating:
            animationState = .celebrating
        case .concerned:
            animationState = .concerned
        case .encouraging:
            animationState = .speaking
        default:
            animationState = .speaking
        }
        
        // Mark proactive message as handled
        proactiveManager.dismissProactiveMessage()
    }
    
    private func collapseStudyBuddy() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isExpanded = false
            showingTranscript = false
        }
        
        // Stop any active voice input
        if voiceManager.isListening {
            voiceManager.stopListening()
        }
    }
    
    private func toggleVoiceInput() {
        proactiveManager.recordUserInteraction()
        
        if voiceManager.isListening {
            voiceManager.stopListening()
        } else {
            startVoiceInput()
        }
    }
    
    private func startVoiceInput() {
        guard voiceManager.voiceEnabled else { return }
        proactiveManager.recordUserInteraction()
        voiceManager.startListening()
        showingTranscript = true
    }
    
    private func sendTextMessage() {
        guard !textInput.isEmpty else { return }
        
        let userMessage = textInput
        
        // Record user interaction
        proactiveManager.recordUserInteraction()
        
        // Add user message
        conversationSession.addUserMessage(userMessage)
        showingTranscript = true
        
        textInput = ""
        
        // Process with AI
        Task {
            do {
                let response = try await voiceManager.processText(userMessage)
                await MainActor.run {
                    handleAIResponse(response)
                }
            } catch {
                print("Error processing text with AI: \(error)")
                await MainActor.run {
                    // Fallback response only if AI service fails
                    let fallbackResponse = GemmaAPIResponse(
                        response: "I'm having trouble processing your request right now. Please try again.",
                        confidence: 0.5,
                        suggestions: ["Try again", "Check your connection"],
                        emotion: .neutral,
                        actions: nil
                    )
                    handleAIResponse(fallbackResponse)
                }
            }
        }
    }
    
    @MainActor
    private func handleAIResponse(_ response: GemmaAPIResponse) {
        // Add AI message to conversation
        conversationSession.addAIMessage(response.response, emotion: response.emotion ?? .neutral)
        
        // Speak the response
        audioPlayer.speak(response.response, emotion: response.emotion ?? .neutral)
        
        // Update animation state based on emotion
        if let emotion = response.emotion {
            switch emotion {
            case .celebrating:
                animationState = .celebrating
            case .concerned:
                animationState = .concerned
            default:
                break
            }
        }
    }
    
    private func snapToEdge(position: CGPoint) -> CGPoint {
        let screenBounds = UIScreen.main.bounds
        let margin: CGFloat = 30
        
        let x: CGFloat
        if position.x < screenBounds.midX {
            x = margin + 30 // Left edge
        } else {
            x = screenBounds.width - margin - 30 // Right edge
        }
        
        let y = max(margin + 50, min(screenBounds.height - margin - 50, position.y))
        
        return CGPoint(x: x, y: y)
    }
    
    private func getStatusText() -> String {
        if voiceManager.isListening {
            return "Listening..."
        } else if voiceManager.isProcessing {
            return "Thinking..."
        } else if audioPlayer.isSpeaking {
            return "Speaking..."
        } else if conversationSession.isActive {
            return "Ready to help"
        } else {
            return "Tap to start"
        }
    }
}


struct StudyBuddyFAB_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // Mock app background
            LinearGradient(
                gradient: Gradient(colors: [.black, .purple.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            StudyBuddyFAB(screenContext: "home")
        }
    }
}