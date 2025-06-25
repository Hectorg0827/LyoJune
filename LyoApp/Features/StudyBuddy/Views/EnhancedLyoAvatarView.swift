import SwiftUI

struct EnhancedLyoAvatarView: View {
    @Binding var animationState: AvatarAnimationState
    @Binding var mouthIntensity: Double
    @State private var isBlinking = false
    @State private var eyeScale: CGFloat = 1.0
    @State private var mouthScale: CGFloat = 1.0
    @State private var headRotation: Double = 0
    @State private var idleOffset: CGSize = .zero
    @State private var pulseScale: CGFloat = 1.0
    @State private var expressionIntensity: Double = 0.0
    @State private var particleOpacity: Double = 0.0
    @State private var energyRings: [EnergyRing] = []
    @State private var thoughtBubbles: [ThoughtBubble] = []
    @State private var currentMood: AvatarMood = .neutral
    @State private var breathingScale: CGFloat = 1.0
    @State private var eyebrowOffset: CGFloat = 0
    @State private var cheekGlow: Double = 0.0
    
    // Timers for safe animation management
    @State private var blinkTimer: Timer?
    @State private var idleTimer: Timer?
    @State private var particleTimer: Timer?
    @State private var breathingTimer: Timer?
    
    let size: CGFloat
    let enableAdvancedFeatures: Bool
    let enableParticles: Bool
    let enableThoughts: Bool
    
    init(
        animationState: Binding<AvatarAnimationState>,
        mouthIntensity: Binding<Double>,
        size: CGFloat = 120,
        enableAdvancedFeatures: Bool = true,
        enableParticles: Bool = true,
        enableThoughts: Bool = true
    ) {
        self._animationState = animationState
        self._mouthIntensity = mouthIntensity
        self.size = size
        self.enableAdvancedFeatures = enableAdvancedFeatures
        self.enableParticles = enableParticles
        self.enableThoughts = enableThoughts
    }
    
    var body: some View {
        ZStack {
            // Particle effects background
            if enableParticles {
                ParticleEffectView(opacity: particleOpacity, size: size)
            }
            
            // Energy rings for thinking/processing
            ForEach(energyRings, id: \.id) { ring in
                EnergyRingView(ring: ring, size: size)
            }
            
            // Main avatar container
            ZStack {
                // Avatar base with enhanced glassmorphism
                avatarBase
                
                // Avatar face with expressions
                avatarFace
                
                // Thought bubbles
                if enableThoughts {
                    ForEach(thoughtBubbles, id: \.id) { bubble in
                        ThoughtBubbleView(bubble: bubble, size: size)
                    }
                }
            }
            .scaleEffect(breathingScale)
            .rotationEffect(.degrees(headRotation))
            .offset(idleOffset)
        }
        .frame(width: size, height: size)
        .onAppear {
            setupSafeAnimations()
        }
        .onDisappear {
            cleanupTimers()
        }
        .onChange(of: animationState) { _, newState in
            updateAnimationForState(newState)
        }
        .onChange(of: mouthIntensity) { _, intensity in
            updateMouthAnimation(intensity: intensity)
        }
    }
    
    private var avatarBase: some View {
        Circle()
            .fill(Material.ultraThin)
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                currentMood.primaryColor.opacity(0.8),
                                currentMood.secondaryColor.opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2 + (expressionIntensity * 2)
                    )
            )
            .background(
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                currentMood.primaryColor.opacity(0.4),
                                currentMood.secondaryColor.opacity(0.1)
                            ]),
                            center: .center,
                            startRadius: 20,
                            endRadius: size * 0.6
                        )
                    )
            )
            .overlay(
                // Cheek glow effect
                HStack(spacing: size * 0.3) {
                    Circle()
                        .fill(currentMood.primaryColor.opacity(cheekGlow * 0.3))
                        .frame(width: size * 0.2, height: size * 0.2)
                        .blur(radius: 8)
                    
                    Circle()
                        .fill(currentMood.primaryColor.opacity(cheekGlow * 0.3))
                        .frame(width: size * 0.2, height: size * 0.2)
                        .blur(radius: 8)
                }
                .offset(y: size * 0.1)
            )
            .scaleEffect(pulseScale)
    }
    
    private var avatarFace: some View {
        VStack(spacing: size * 0.08) {
            // Eyebrows
            HStack(spacing: size * 0.15) {
                EyebrowView(offset: eyebrowOffset, mood: currentMood, size: size * 0.15)
                EyebrowView(offset: eyebrowOffset, mood: currentMood, size: size * 0.15)
            }
            .offset(y: -size * 0.05 + eyebrowOffset)
            
            // Eyes with enhanced expressions
            HStack(spacing: size * 0.15) {
                EnhancedEyeView(
                    isBlinking: isBlinking,
                    scale: eyeScale,
                    size: size * 0.12,
                    mood: currentMood,
                    expressionIntensity: expressionIntensity
                )
                EnhancedEyeView(
                    isBlinking: isBlinking,
                    scale: eyeScale,
                    size: size * 0.12,
                    mood: currentMood,
                    expressionIntensity: expressionIntensity
                )
            }
            .padding(.top, size * 0.05)
            
            // Enhanced mouth with emotions
            EnhancedMouthView(
                intensity: mouthIntensity,
                scale: mouthScale,
                animationState: animationState,
                size: size * 0.25,
                mood: currentMood,
                expressionIntensity: expressionIntensity
            )
            .padding(.bottom, size * 0.05)
        }
    }
    
    // MARK: - Animation Management
    
    private func setupSafeAnimations() {
        startSafeIdleAnimation()
        startSafeBlinkingAnimation()
        startSafeBreathingAnimation()
        
        if enableParticles {
            startSafeParticleAnimation()
        }
    }
    
    private func startSafeIdleAnimation() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            guard !isBlinking else { return }
            
            withAnimation(.easeInOut(duration: 2.0)) {
                idleOffset = CGSize(
                    width: Double.random(in: -2...2),
                    height: Double.random(in: -1...1)
                )
                headRotation = Double.random(in: -1...1)
            }
        }
    }
    
    private func startSafeBlinkingAnimation() {
        blinkTimer?.invalidate()
        blinkTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 2.0...5.0), repeats: true) { _ in
            performSafeBlink()
        }
    }
    
    private func startSafeBreathingAnimation() {
        breathingTimer?.invalidate()
        breathingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            let breathingCycle = sin(Date().timeIntervalSinceReferenceDate * 0.5) * 0.02 + 1.0
            withAnimation(.linear(duration: 0.1)) {
                breathingScale = breathingCycle
            }
        }
    }
    
    private func startSafeParticleAnimation() {
        guard enableParticles else { return }
        
        particleTimer?.invalidate()
        particleTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            updateParticleEffects()
        }
    }
    
    private func performSafeBlink() {
        guard !isBlinking else { return }
        
        withAnimation(.easeInOut(duration: 0.1)) {
            isBlinking = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.1)) {
                isBlinking = false
            }
        }
        
        // Schedule next blink
        blinkTimer?.invalidate()
        blinkTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 2.0...5.0), repeats: false) { _ in
            performSafeBlink()
        }
    }
    
    private func updateAnimationForState(_ state: AvatarAnimationState) {
        switch state {
        case .idle:
            currentMood = .neutral
            resetToIdleState()
            
        case .listening:
            currentMood = .focused
            animateListening()
            
        case .speaking:
            currentMood = .excited
            animateSpeaking()
            
        case .thinking:
            currentMood = .thoughtful
            animateThinking()
            
        case .celebrating:
            currentMood = .joyful
            animateCelebrating()
            
        case .concerned:
            currentMood = .worried
            animateConcerned()
            
        case .blinking:
            performSafeBlink()
            
        case .mouthMoving(let intensity):
            updateMouthAnimation(intensity: intensity)
        }
    }
    
    private func resetToIdleState() {
        withAnimation(.easeInOut(duration: 0.5)) {
            eyeScale = 1.0
            mouthScale = 1.0
            headRotation = 0
            expressionIntensity = 0.0
            eyebrowOffset = 0
            cheekGlow = 0.0
        }
        clearEffects()
    }
    
    private func animateListening() {
        withAnimation(.easeInOut(duration: 0.3).repeatCount(3, autoreverses: true)) {
            eyeScale = 1.1
            expressionIntensity = 0.6
            pulseScale = 1.05
        }
        
        if enableParticles {
            withAnimation(.easeInOut(duration: 0.5)) {
                particleOpacity = 0.7
            }
        }
    }
    
    private func animateSpeaking() {
        withAnimation(.easeInOut(duration: 0.2)) {
            mouthScale = 1.2
            eyeScale = 1.05
            expressionIntensity = 0.8
            cheekGlow = 0.6
        }
    }
    
    private func animateThinking() {
        currentMood = .thoughtful
        
        withAnimation(.easeInOut(duration: 1.0).repeatCount(2, autoreverses: true)) {
            headRotation = -3
            eyeScale = 0.9
            eyebrowOffset = -2
            expressionIntensity = 0.7
        }
        
        if enableThoughts {
            generateThoughtBubbles()
        }
        
        generateEnergyRings()
    }
    
    private func animateCelebrating() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).repeatCount(3, autoreverses: true)) {
            pulseScale = 1.3
            eyeScale = 1.4
            mouthScale = 1.5
            expressionIntensity = 1.0
            cheekGlow = 1.0
        }
        
        withAnimation(.easeInOut(duration: 0.2).repeatCount(6, autoreverses: true)) {
            headRotation = 8
        }
        
        if enableParticles {
            generateCelebrationParticles()
        }
    }
    
    private func animateConcerned() {
        withAnimation(.easeInOut(duration: 0.8)) {
            headRotation = -2
            eyeScale = 0.8
            mouthScale = 0.85
            expressionIntensity = 0.6
            eyebrowOffset = -3
        }
    }
    
    private func updateMouthAnimation(intensity: Double) {
        let targetScale = 1.0 + (intensity * 0.6)
        withAnimation(.easeInOut(duration: 0.1)) {
            mouthScale = targetScale
        }
    }
    
    // MARK: - Effect Generation
    
    private func generateThoughtBubbles() {
        guard enableThoughts else { return }
        
        for i in 0..<3 {
            let bubble = ThoughtBubble(
                id: UUID(),
                position: CGPoint(
                    x: Double.random(in: -size/3...size/3),
                    y: Double.random(in: -size/2...0)
                ),
                scale: Double.random(in: 0.5...1.0),
                opacity: 0.0
            )
            
            thoughtBubbles.append(bubble)
            
            withAnimation(.easeInOut(duration: 0.5).delay(Double(i) * 0.2)) {
                if let index = thoughtBubbles.firstIndex(where: { $0.id == bubble.id }) {
                    thoughtBubbles[index].opacity = 1.0
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 + Double(i) * 0.2) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    if let index = thoughtBubbles.firstIndex(where: { $0.id == bubble.id }) {
                        thoughtBubbles[index].opacity = 0.0
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    thoughtBubbles.removeAll { $0.id == bubble.id }
                }
            }
        }
    }
    
    private func generateEnergyRings() {
        for i in 0..<2 {
            let ring = EnergyRing(
                id: UUID(),
                scale: 0.5,
                opacity: 0.0,
                rotation: 0
            )
            
            energyRings.append(ring)
            
            withAnimation(.easeInOut(duration: 1.0).delay(Double(i) * 0.3)) {
                if let index = energyRings.firstIndex(where: { $0.id == ring.id }) {
                    energyRings[index].scale = 1.5
                    energyRings[index].opacity = 0.8
                    energyRings[index].rotation = 360
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                energyRings.removeAll { $0.id == ring.id }
            }
        }
    }
    
    private func generateCelebrationParticles() {
        guard enableParticles else { return }
        
        withAnimation(.easeInOut(duration: 1.0)) {
            particleOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                particleOpacity = 0.0
            }
        }
    }
    
    private func updateParticleEffects() {
        switch animationState {
        case .listening:
            withAnimation(.easeInOut(duration: 0.5)) {
                particleOpacity = 0.6
            }
        case .thinking:
            withAnimation(.easeInOut(duration: 0.5)) {
                particleOpacity = 0.4
            }
        default:
            withAnimation(.easeInOut(duration: 0.5)) {
                particleOpacity = max(0.0, particleOpacity - 0.1)
            }
        }
    }
    
    private func clearEffects() {
        thoughtBubbles.removeAll()
        energyRings.removeAll()
        withAnimation(.easeInOut(duration: 0.5)) {
            particleOpacity = 0.0
        }
    }
    
    private func cleanupTimers() {
        blinkTimer?.invalidate()
        idleTimer?.invalidate()
        particleTimer?.invalidate()
        breathingTimer?.invalidate()
        
        blinkTimer = nil
        idleTimer = nil
        particleTimer = nil
        breathingTimer = nil
    }
}

// MARK: - Supporting Views

struct EnhancedEyeView: View {
    let isBlinking: Bool
    let scale: CGFloat
    let size: CGFloat
    let mood: AvatarMood
    let expressionIntensity: Double
    
    var body: some View {
        ZStack {
            // Eye white
            Ellipse()
                .fill(Color.white.opacity(0.95))
                .frame(width: size, height: isBlinking ? 2 : size)
                .overlay(
                    Ellipse()
                        .stroke(mood.primaryColor.opacity(0.3), lineWidth: 1)
                        .frame(width: size, height: isBlinking ? 2 : size)
                )
            
            if !isBlinking {
                // Iris
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                mood.primaryColor.opacity(0.8),
                                mood.secondaryColor.opacity(0.9),
                                .black
                            ]),
                            center: .center,
                            startRadius: 2,
                            endRadius: size * 0.4
                        )
                    )
                    .frame(width: size * 0.7, height: size * 0.7)
                
                // Pupil
                Circle()
                    .fill(.black)
                    .frame(width: size * 0.3, height: size * 0.3)
                
                // Eye shine
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: size * 0.15, height: size * 0.15)
                    .offset(x: -size * 0.08, y: -size * 0.08)
                
                // Expression sparkle
                if expressionIntensity > 0.5 {
                    Circle()
                        .fill(mood.primaryColor.opacity(expressionIntensity))
                        .frame(width: size * 0.1, height: size * 0.1)
                        .offset(x: size * 0.1, y: -size * 0.1)
                }
            }
        }
        .scaleEffect(scale)
    }
}

struct EyebrowView: View {
    let offset: CGFloat
    let mood: AvatarMood
    let size: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.2)
            .fill(mood.primaryColor.opacity(0.7))
            .frame(width: size, height: size * 0.3)
            .rotationEffect(.degrees(mood.eyebrowAngle))
            .offset(y: offset)
    }
}

struct EnhancedMouthView: View {
    let intensity: Double
    let scale: CGFloat
    let animationState: AvatarAnimationState
    let size: CGFloat
    let mood: AvatarMood
    let expressionIntensity: Double
    
    var body: some View {
        Group {
            switch animationState {
            case .speaking, .mouthMoving:
                // Animated speaking mouth
                Ellipse()
                    .fill(Color.black.opacity(0.8))
                    .frame(
                        width: size * (0.6 + intensity * 0.4),
                        height: size * (0.3 + intensity * 0.3)
                    )
                    .overlay(
                        // Teeth highlight
                        Rectangle()
                            .fill(Color.white.opacity(0.6))
                            .frame(
                                width: size * (0.4 + intensity * 0.2),
                                height: size * 0.1
                            )
                            .offset(y: -size * 0.05)
                    )
                    .overlay(
                        Ellipse()
                            .stroke(mood.primaryColor.opacity(0.5), lineWidth: 1)
                            .frame(
                                width: size * (0.6 + intensity * 0.4),
                                height: size * (0.3 + intensity * 0.3)
                            )
                    )
                
            case .celebrating:
                // Happy smile with sparkles
                ZStack {
                    Arc(startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                        .stroke(mood.primaryColor, lineWidth: 4)
                        .frame(width: size, height: size * 0.6)
                    
                    // Smile sparkles
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: "sparkle")
                            .foregroundColor(.yellow)
                            .font(.caption)
                            .offset(
                                x: CGFloat(i - 1) * size * 0.3,
                                y: -size * 0.2
                            )
                            .scaleEffect(expressionIntensity)
                    }
                }
                
            case .concerned:
                // Concerned frown
                Arc(startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
                    .stroke(mood.primaryColor, lineWidth: 3)
                    .frame(width: size * 0.8, height: size * 0.4)
                
            case .thinking:
                // Thoughtful expression
                Ellipse()
                    .fill(mood.primaryColor.opacity(0.6))
                    .frame(width: size * 0.4, height: size * 0.15)
                    .overlay(
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: size * 0.2, height: size * 0.05)
                    )
                
            default:
                // Neutral mouth
                Ellipse()
                    .fill(mood.primaryColor.opacity(0.7))
                    .frame(width: size * 0.5, height: size * 0.2)
                    .overlay(
                        Ellipse()
                            .stroke(mood.secondaryColor.opacity(0.5), lineWidth: 1)
                            .frame(width: size * 0.5, height: size * 0.2)
                    )
            }
        }
        .scaleEffect(scale)
    }
}

// MARK: - Effect Views

struct ParticleEffectView: View {
    let opacity: Double
    let size: CGFloat
    @State private var particles: [Particle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                Circle()
                    .fill(particle.color.opacity(particle.opacity))
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .blur(radius: particle.blur)
            }
        }
        .opacity(opacity)
        .onAppear {
            generateParticles()
        }
        .onChange(of: opacity) { _, newOpacity in
            if newOpacity > 0.5 {
                generateParticles()
            }
        }
    }
    
    private func generateParticles() {
        particles.removeAll()
        
        for _ in 0..<15 {
            let particle = Particle(
                id: UUID(),
                position: CGPoint(
                    x: Double.random(in: 0...Double(size)),
                    y: Double.random(in: 0...Double(size))
                ),
                size: Double.random(in: 2...6),
                color: [.blue, .purple, .cyan, .white].randomElement() ?? .blue,
                opacity: Double.random(in: 0.3...0.8),
                blur: Double.random(in: 0...2)
            )
            particles.append(particle)
        }
    }
}

struct EnergyRingView: View {
    let ring: EnergyRing
    let size: CGFloat
    
    var body: some View {
        Circle()
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.8), .purple.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 2
            )
            .frame(width: size * ring.scale, height: size * ring.scale)
            .opacity(ring.opacity)
            .rotationEffect(.degrees(ring.rotation))
    }
}

struct ThoughtBubbleView: View {
    let bubble: ThoughtBubble
    let size: CGFloat
    
    var body: some View {
        Image(systemName: "thought.bubble")
            .foregroundColor(.blue.opacity(0.7))
            .font(.system(size: size * 0.15 * bubble.scale))
            .position(
                x: size/2 + bubble.position.x,
                y: size/2 + bubble.position.y
            )
            .opacity(bubble.opacity)
    }
}

// MARK: - Data Models

enum AvatarMood {
    case neutral, focused, excited, thoughtful, joyful, worried
    
    var primaryColor: Color {
        switch self {
        case .neutral: return .blue
        case .focused: return .green
        case .excited: return .orange
        case .thoughtful: return .purple
        case .joyful: return .yellow
        case .worried: return .red
        }
    }
    
    var secondaryColor: Color {
        switch self {
        case .neutral: return .purple
        case .focused: return .teal
        case .excited: return .pink
        case .thoughtful: return .indigo
        case .joyful: return .orange
        case .worried: return .orange
        }
    }
    
    var eyebrowAngle: Double {
        switch self {
        case .neutral: return 0
        case .focused: return -5
        case .excited: return 5
        case .thoughtful: return -10
        case .joyful: return 10
        case .worried: return -15
        }
    }
}

struct Particle {
    let id: UUID
    let position: CGPoint
    let size: Double
    let color: Color
    let opacity: Double
    let blur: Double
}

struct EnergyRing {
    let id: UUID
    var scale: Double
    var opacity: Double
    var rotation: Double
}

struct ThoughtBubble {
    let id: UUID
    let position: CGPoint
    let scale: Double
    var opacity: Double
}

struct Arc: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let clockwise: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: clockwise
        )
        return path
    }
}

// MARK: - Preview

struct EnhancedLyoAvatarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            EnhancedLyoAvatarView(
                animationState: .constant(.idle),
                mouthIntensity: .constant(0.0)
            )
            
            EnhancedLyoAvatarView(
                animationState: .constant(.celebrating),
                mouthIntensity: .constant(0.0)
            )
            
            EnhancedLyoAvatarView(
                animationState: .constant(.thinking),
                mouthIntensity: .constant(0.0)
            )
        }
        .padding()
        .background(.black)
    }
}