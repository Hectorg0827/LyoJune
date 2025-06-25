import SwiftUI

struct LyoAvatarView: View {
    @Binding var animationState: AvatarAnimationState
    @Binding var mouthIntensity: Double
    @State private var isBlinking = false
    @State private var eyeScale: CGFloat = 1.0
    @State private var mouthScale: CGFloat = 1.0
    @State private var headRotation: Double = 0
    @State private var idleOffset: CGSize = .zero
    @State private var pulseScale: CGFloat = 1.0
    
    let size: CGFloat
    
    init(animationState: Binding<AvatarAnimationState>, mouthIntensity: Binding<Double>, size: CGFloat = 120) {
        self._animationState = animationState
        self._mouthIntensity = mouthIntensity
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Avatar base with glassmorphism effect
            Circle()
                .fill(Material.ultraThin)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.6)]),
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
                                gradient: Gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.1)]),
                                center: .center,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                )
                .scaleEffect(pulseScale)
            
            // Avatar face
            VStack(spacing: size * 0.05) {
                // Eyes
                HStack(spacing: size * 0.15) {
                    EyeView(isBlinking: isBlinking, scale: eyeScale, size: size * 0.12)
                    EyeView(isBlinking: isBlinking, scale: eyeScale, size: size * 0.12)
                }
                .padding(.top, size * 0.1)
                
                // Mouth
                MouthView(
                    intensity: mouthIntensity,
                    scale: mouthScale,
                    animationState: animationState,
                    size: size * 0.2
                )
                .padding(.bottom, size * 0.05)
            }
            .rotationEffect(.degrees(headRotation))
            .offset(idleOffset)
        }
        .frame(width: size, height: size)
        .onAppear {
            startIdleAnimation()
            startBlinkingAnimation()
        }
        .onChange(of: animationState) { _, newState in
            updateAnimationForState(newState)
        }
    }
    
    private func startIdleAnimation() {
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            idleOffset = CGSize(width: 2, height: 1)
            headRotation = 1
        }
        
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.02
        }
    }
    
    private func startBlinkingAnimation() {
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 2.0...4.0), repeats: true) { _ in
            performBlink()
        }
    }
    
    private func performBlink() {
        withAnimation(.easeInOut(duration: 0.15)) {
            isBlinking = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.15)) {
                isBlinking = false
            }
        }
    }
    
    private func updateAnimationForState(_ state: AvatarAnimationState) {
        switch state {
        case .idle:
            resetToIdleState()
            
        case .listening:
            animateListening()
            
        case .speaking:
            animateSpeaking()
            
        case .thinking:
            animateThinking()
            
        case .celebrating:
            animateCelebrating()
            
        case .concerned:
            animateConcerned()
            
        case .blinking:
            performBlink()
            
        case .mouthMoving(let intensity):
            animateMouthMovement(intensity: intensity)
        }
    }
    
    private func resetToIdleState() {
        withAnimation(.easeInOut(duration: 0.5)) {
            eyeScale = 1.0
            mouthScale = 1.0
            headRotation = 0
            pulseScale = 1.0
        }
        startIdleAnimation()
    }
    
    private func animateListening() {
        withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
            eyeScale = 1.1
            pulseScale = 1.05
        }
        
        withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: true)) {
            headRotation = 3
        }
    }
    
    private func animateSpeaking() {
        withAnimation(.easeInOut(duration: 0.2)) {
            mouthScale = 1.2
            eyeScale = 1.05
        }
    }
    
    private func animateThinking() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            headRotation = -5
            eyeScale = 0.9
        }
        
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.03
        }
    }
    
    private func animateCelebrating() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).repeatCount(3, autoreverses: true)) {
            pulseScale = 1.2
            eyeScale = 1.3
            mouthScale = 1.4
        }
        
        withAnimation(.easeInOut(duration: 0.2).repeatCount(6, autoreverses: true)) {
            headRotation = 10
        }
    }
    
    private func animateConcerned() {
        withAnimation(.easeInOut(duration: 0.8)) {
            headRotation = -3
            eyeScale = 0.8
            mouthScale = 0.9
            pulseScale = 0.95
        }
    }
    
    private func animateMouthMovement(intensity: Double) {
        let targetScale = 1.0 + (intensity * 0.5)
        withAnimation(.easeInOut(duration: 0.1)) {
            mouthScale = targetScale
        }
    }
}

struct EyeView: View {
    let isBlinking: Bool
    let scale: CGFloat
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Eye white
            Ellipse()
                .fill(Color.white.opacity(0.9))
                .frame(width: size, height: isBlinking ? 2 : size)
                .overlay(
                    Ellipse()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        .frame(width: size, height: isBlinking ? 2 : size)
                )
            
            // Pupil
            if !isBlinking {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            center: .center,
                            startRadius: 2,
                            endRadius: size * 0.3
                        )
                    )
                    .frame(width: size * 0.6, height: size * 0.6)
                
                // Eye shine
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: size * 0.2, height: size * 0.2)
                    .offset(x: -size * 0.1, y: -size * 0.1)
            }
        }
        .scaleEffect(scale)
    }
}

struct MouthView: View {
    let intensity: Double
    let scale: CGFloat
    let animationState: AvatarAnimationState
    let size: CGFloat
    
    private var mouthShape: some View {
        Group {
            switch animationState {
            case .speaking, .mouthMoving:
                // Open mouth for speaking
                Ellipse()
                    .fill(Color.black.opacity(0.7))
                    .frame(width: size * (0.8 + intensity * 0.4), height: size * (0.4 + intensity * 0.3))
                    .overlay(
                        Ellipse()
                            .stroke(Color.purple.opacity(0.5), lineWidth: 1)
                            .frame(width: size * (0.8 + intensity * 0.4), height: size * (0.4 + intensity * 0.3))
                    )
                
            case .celebrating:
                // Happy smile
                Arc(startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                    .stroke(Color.yellow, lineWidth: 3)
                    .frame(width: size, height: size * 0.5)
                
            case .concerned:
                // Concerned frown
                Arc(startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
                    .stroke(Color.orange, lineWidth: 3)
                    .frame(width: size, height: size * 0.3)
                
            default:
                // Neutral mouth
                Ellipse()
                    .fill(Color.pink.opacity(0.6))
                    .frame(width: size * 0.6, height: size * 0.2)
                    .overlay(
                        Ellipse()
                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                            .frame(width: size * 0.6, height: size * 0.2)
                    )
            }
        }
    }
    
    var body: some View {
        mouthShape
            .scaleEffect(scale)
            .animation(.easeInOut(duration: 0.1), value: intensity)
    }
}


struct LyoAvatarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            LyoAvatarView(
                animationState: .constant(.idle),
                mouthIntensity: .constant(0.0)
            )
            
            LyoAvatarView(
                animationState: .constant(.speaking),
                mouthIntensity: .constant(0.7)
            )
            
            LyoAvatarView(
                animationState: .constant(.celebrating),
                mouthIntensity: .constant(0.0)
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