import Foundation
import AVFoundation
import Speech
import Combine

@MainActor
class AIAudioPlayer: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isSpeaking = false
    @Published var speechProgress: Double = 0.0
    @Published var currentText = ""
    @Published var speechRate: Float = 0.5
    @Published var speechPitch: Float = 1.0
    @Published var speechVolume: Float = 1.0
    @Published var voiceIdentifier: String?
    
    // MARK: - Private Properties
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var currentUtterance: AVSpeechUtterance?
    private var speechTimer: Timer?
    private var wordRanges: [NSRange] = []
    private var currentWordIndex = 0
    
    // Speech timing for mouth animation sync
    @Published var mouthMovementIntensity: Double = 0.0
    @Published var isProducingVowelSound = false
    
    // Available voices
    @Published var availableVoices: [AVSpeechSynthesisVoice] = []
    @Published var selectedVoice: AVSpeechSynthesisVoice?
    
    // Callbacks for avatar animation
    var onSpeechStart: (() -> Void)?
    var onSpeechEnd: (() -> Void)?
    var onWordSpoken: ((String, Double) -> Void)?
    var onPhonemeSpoken: ((String) -> Void)?
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupSpeechSynthesizer()
        loadAvailableVoices()
        setupAudioSession()
    }
    
    private func setupSpeechSynthesizer() {
        speechSynthesizer.delegate = self
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }
    
    private func loadAvailableVoices() {
        availableVoices = AVSpeechSynthesisVoice.speechVoices()
        
        // Try to find a pleasant, clear voice for the AI
        let preferredVoiceIdentifiers = [
            "com.apple.voice.compact.en-US.Samantha",
            "com.apple.voice.enhanced.en-US.Nicky",
            "com.apple.voice.enhanced.en-US.Samantha",
            "com.apple.ttsbundle.Samantha-compact"
        ]
        
        for identifier in preferredVoiceIdentifiers {
            if let voice = AVSpeechSynthesisVoice(identifier: identifier) {
                selectedVoice = voice
                voiceIdentifier = identifier
                break
            }
        }
        
        // Fallback to default English voice
        if selectedVoice == nil {
            selectedVoice = AVSpeechSynthesisVoice(language: "en-US")
            voiceIdentifier = selectedVoice?.identifier
        }
    }
    
    // MARK: - Speech Control
    func speak(_ text: String, emotion: GemmaAPIResponse.EmotionState = .neutral) {
        guard !text.isEmpty else { return }
        
        // Stop any current speech
        stop()
        
        currentText = text
        
        // Create utterance with emotion-based settings
        let utterance = createUtterance(for: text, emotion: emotion)
        currentUtterance = utterance
        
        // Analyze text for mouth animation timing
        analyzeTextForAnimation(text)
        
        // Start speaking
        speechSynthesizer.speak(utterance)
        isSpeaking = true
        onSpeechStart?()
        
        // Start mouth animation timer
        startMouthAnimationTimer()
    }
    
    func pause() {
        speechSynthesizer.pauseSpeaking(at: .immediate)
    }
    
    func resume() {
        speechSynthesizer.continueSpeaking()
    }
    
    func stop() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        stopMouthAnimationTimer()
        isSpeaking = false
        speechProgress = 0.0
        mouthMovementIntensity = 0.0
        currentWordIndex = 0
        onSpeechEnd?()
    }
    
    // MARK: - Voice Customization
    func setVoice(identifier: String) {
        if let voice = AVSpeechSynthesisVoice(identifier: identifier) {
            selectedVoice = voice
            voiceIdentifier = identifier
        }
    }
    
    func adjustSpeechSettings(rate: Float, pitch: Float, volume: Float) {
        speechRate = max(0.1, min(1.0, rate))
        speechPitch = max(0.5, min(2.0, pitch))
        speechVolume = max(0.1, min(1.0, volume))
    }
    
    // MARK: - Utterance Creation
    private func createUtterance(for text: String, emotion: GemmaAPIResponse.EmotionState) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        
        if let voice = selectedVoice {
            utterance.voice = voice
        }
        
        // Adjust speech parameters based on emotion
        let (rate, pitch, volume) = speechParametersForEmotion(emotion)
        utterance.rate = rate
        utterance.pitchMultiplier = pitch
        utterance.volume = volume
        
        return utterance
    }
    
    private func speechParametersForEmotion(_ emotion: GemmaAPIResponse.EmotionState) -> (Float, Float, Float) {
        switch emotion {
        case .neutral:
            return (speechRate, speechPitch, speechVolume)
        case .encouraging:
            return (speechRate * 1.1, speechPitch * 1.1, speechVolume)
        case .explaining:
            return (speechRate * 0.9, speechPitch, speechVolume)
        case .questioning:
            return (speechRate, speechPitch * 1.2, speechVolume)
        case .celebrating:
            return (speechRate * 1.2, speechPitch * 1.3, speechVolume)
        case .concerned:
            return (speechRate * 0.8, speechPitch * 0.9, speechVolume * 0.9)
        }
    }
    
    // MARK: - Animation Support
    private func analyzeTextForAnimation(_ text: String) {
        // Split text into words for timing
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        wordRanges = []
        
        var location = 0
        for word in words {
            let range = NSRange(location: location, length: word.count)
            wordRanges.append(range)
            location += word.count + 1 // +1 for space
        }
    }
    
    private func startMouthAnimationTimer() {
        speechTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateMouthAnimation()
        }
    }
    
    private func stopMouthAnimationTimer() {
        speechTimer?.invalidate()
        speechTimer = nil
        mouthMovementIntensity = 0.0
        isProducingVowelSound = false
    }
    
    private func updateMouthAnimation() {
        guard isSpeaking else {
            stopMouthAnimationTimer()
            return
        }
        
        // Simulate mouth movement based on speech characteristics
        let baseIntensity = 0.3
        let variationIntensity = Double.random(in: 0.0...0.7)
        mouthMovementIntensity = baseIntensity + variationIntensity
        
        // Simulate vowel detection for mouth shape
        isProducingVowelSound = Bool.random() // In real implementation, this would analyze phonemes
        
        // Notify avatar of mouth movement
        onWordSpoken?("", mouthMovementIntensity)
    }
    
    // MARK: - Phoneme Analysis (Advanced Feature)
    private func analyzePhonemes(in text: String) -> [PhonemeInfo] {
        // This would require more advanced speech analysis
        // For now, return mock phoneme data
        return text.map { char in
            PhonemeInfo(
                phoneme: String(char),
                isVowel: "aeiouAEIOU".contains(char),
                duration: 0.1,
                intensity: Double.random(in: 0.3...0.8)
            )
        }
    }
    
    // MARK: - Speech Queue Management
    private var speechQueue: [String] = []
    private var isProcessingQueue = false
    
    func queueSpeech(_ text: String, emotion: GemmaAPIResponse.EmotionState = .neutral) {
        speechQueue.append(text)
        if !isProcessingQueue {
            processNextInQueue()
        }
    }
    
    private func processNextInQueue() {
        guard !speechQueue.isEmpty, !isSpeaking else {
            isProcessingQueue = false
            return
        }
        
        isProcessingQueue = true
        let nextText = speechQueue.removeFirst()
        speak(nextText)
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension AIAudioPlayer: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
            self.onSpeechStart?()
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.speechProgress = 1.0
            self.stopMouthAnimationTimer()
            self.onSpeechEnd?()
            
            // Process next item in queue if any
            if self.isProcessingQueue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.processNextInQueue()
                }
            }
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.stopMouthAnimationTimer()
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.startMouthAnimationTimer()
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            // Update progress based on character range
            let totalLength = utterance.speechString.count
            if totalLength > 0 {
                self.speechProgress = Double(characterRange.location + characterRange.length) / Double(totalLength)
            }
            
            // Extract current word being spoken
            let speechString = utterance.speechString as NSString
            let currentWord = speechString.substring(with: characterRange)
            
            // Analyze current word for mouth animation
            let intensity = self.calculateMouthIntensity(for: currentWord)
            self.onWordSpoken?(currentWord, intensity)
        }
    }
    
    private func calculateMouthIntensity(for word: String) -> Double {
        // Calculate mouth movement intensity based on word characteristics
        let vowelCount = word.lowercased().filter { "aeiou".contains($0) }.count
        let consonantCount = word.count - vowelCount
        
        // More vowels = more mouth movement
        let vowelFactor = Double(vowelCount) * 0.3
        let consonantFactor = Double(consonantCount) * 0.1
        
        return min(1.0, max(0.2, vowelFactor + consonantFactor))
    }
}

// MARK: - Supporting Types
struct PhonemeInfo {
    let phoneme: String
    let isVowel: Bool
    let duration: TimeInterval
    let intensity: Double
}

// MARK: - Speech Settings
struct SpeechSettings {
    var rate: Float = 0.5
    var pitch: Float = 1.0
    var volume: Float = 1.0
    var voiceIdentifier: String?
    
    static let `default` = SpeechSettings()
    
    static let emotional: [GemmaAPIResponse.EmotionState: SpeechSettings] = [
        .neutral: SpeechSettings(rate: 0.5, pitch: 1.0, volume: 1.0),
        .encouraging: SpeechSettings(rate: 0.55, pitch: 1.1, volume: 1.0),
        .explaining: SpeechSettings(rate: 0.45, pitch: 1.0, volume: 1.0),
        .questioning: SpeechSettings(rate: 0.5, pitch: 1.2, volume: 1.0),
        .celebrating: SpeechSettings(rate: 0.6, pitch: 1.3, volume: 1.0),
        .concerned: SpeechSettings(rate: 0.4, pitch: 0.9, volume: 0.9)
    ]
}