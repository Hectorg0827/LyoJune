import Foundation
import AVKit
import AVFoundation
import Combine
import Network

// MARK: - Video Streaming Manager
@MainActor
public class VideoStreamManager: ObservableObject {
    // MARK: - Properties
    @Published public var currentPlayer: AVPlayer?
    @Published public var isLoading = false
    @Published public var bufferProgress: Double = 0.0
    @Published public var playbackProgress: Double = 0.0
    @Published public var isPlaying = false
    @Published public var streamQuality: StreamQuality = .auto
    @Published public var availableQualities: [StreamQuality] = []
    @Published public var playbackSpeed: Float = 1.0
    @Published public var volume: Float = 1.0
    @Published public var isMuted = false
    @Published public var error: VideoStreamError?
    
    private var cancellables = Set<AnyCancellable>()
    private var timeObserver: Any?
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "NetworkMonitor")
    private var currentPlayerItem: AVPlayerItem?
    private let adaptiveManager: AdaptiveStreamingManager
    
    // MARK: - Stream Quality
    public enum StreamQuality: String, CaseIterable {
        case auto = "auto"
        case low = "360p"
        case medium = "720p"
        case high = "1080p"
        case ultra = "4K"
        
        var bitrate: Int {
            switch self {
            case .auto: return 0
            case .low: return 800_000
            case .medium: return 2_500_000
            case .high: return 5_000_000
            case .ultra: return 15_000_000
            }
        }
    }
    
    // MARK: - Initialization
    public init() {
        self.adaptiveManager = AdaptiveStreamingManager()
        setupNetworkMonitoring()
        setupAudioSession()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods
    
    /// Load and prepare video for streaming
    public func loadVideo(from url: URL, quality: StreamQuality = .auto) async {
        isLoading = true
        error = nil
        
        do {
            // Stop current playback
            await stopPlayback()
            
            // Create player item with adaptive streaming
            let playerItem = try await createPlayerItem(from: url, quality: quality)
            currentPlayerItem = playerItem
            
            // Create player
            let player = AVPlayer(playerItem: playerItem)
            currentPlayer = player
            
            // Setup player observers
            setupPlayerObservers(for: player)
            
            // Prepare for playback
            await prepareForPlayback()
            
            isLoading = false
            
        } catch {
            self.error = VideoStreamError.loadingFailed(error.localizedDescription)
            isLoading = false
        }
    }
    
    /// Start playback
    public func play() async {
        guard let player = currentPlayer else { return }
        
        // Ensure player is ready
        if player.currentItem?.status == .readyToPlay {
            await MainActor.run {
                player.play()
                isPlaying = true
            }
        } else {
            // Wait for player to be ready
            try? await waitForPlayerReady()
            await MainActor.run {
                player.play()
                isPlaying = true
            }
        }
    }
    
    /// Pause playback
    public func pause() {
        currentPlayer?.pause()
        isPlaying = false
    }
    
    /// Stop playback and cleanup
    public func stopPlayback() async {
        await MainActor.run {
            currentPlayer?.pause()
            currentPlayer = nil
            currentPlayerItem = nil
            isPlaying = false
            playbackProgress = 0.0
            bufferProgress = 0.0
        }
        
        removeTimeObserver()
    }
    
    /// Seek to specific time
    public func seek(to time: CMTime) async {
        guard let player = currentPlayer else { return }
        
        await player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        updatePlaybackProgress()
    }
    
    /// Seek to percentage
    public func seek(to percentage: Double) async {
        guard let duration = currentPlayer?.currentItem?.duration,
              duration.isValid && !duration.isIndefinite else { return }
        
        let targetTime = CMTime(seconds: duration.seconds * percentage, preferredTimescale: duration.timescale)
        await seek(to: targetTime)
    }
    
    /// Change playback speed
    public func setPlaybackSpeed(_ speed: Float) {
        currentPlayer?.rate = speed
        playbackSpeed = speed
    }
    
    /// Set volume
    public func setVolume(_ volume: Float) {
        currentPlayer?.volume = volume
        self.volume = volume
    }
    
    /// Toggle mute
    public func toggleMute() {
        isMuted.toggle()
        currentPlayer?.isMuted = isMuted
    }
    
    /// Change stream quality
    public func setStreamQuality(_ quality: StreamQuality) async {
        guard let currentURL = currentPlayerItem?.asset as? AVURLAsset else { return }
        
        let currentTime = currentPlayer?.currentTime() ?? .zero
        let wasPlaying = isPlaying
        
        streamQuality = quality
        
        // Reload with new quality
        await loadVideo(from: currentURL.url, quality: quality)
        
        // Restore playback position
        if currentTime.isValid && currentTime.seconds > 0 {
            await seek(to: currentTime)
        }
        
        // Resume playback if it was playing
        if wasPlaying {
            await play()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                await self?.handleNetworkChange(path)
            }
        }
        networkMonitor.start(queue: networkQueue)
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func createPlayerItem(from url: URL, quality: StreamQuality) async throws -> AVPlayerItem {
        // Check if it's an HLS stream
        if url.pathExtension.lowercased() == "m3u8" {
            return try await adaptiveManager.createHLSPlayerItem(from: url, preferredQuality: quality)
        } else {
            // Regular video file
            let asset = AVURLAsset(url: url)
            return AVPlayerItem(asset: asset)
        }
    }
    
    private func setupPlayerObservers(for player: AVPlayer) {
        // Time observer for progress updates
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] _ in
            self?.updatePlaybackProgress()
            self?.updateBufferProgress()
        }
        
        // Player status observer
        player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.handleTimeControlStatusChange(status)
            }
            .store(in: &cancellables)
        
        // Player item observers
        if let playerItem = player.currentItem {
            setupPlayerItemObservers(for: playerItem)
        }
    }
    
    private func setupPlayerItemObservers(for item: AVPlayerItem) {
        // Status observer
        item.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.handlePlayerItemStatusChange(status)
            }
            .store(in: &cancellables)
        
        // Buffer observer
        item.publisher(for: \.loadedTimeRanges)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateBufferProgress()
            }
            .store(in: &cancellables)
        
        // Playback stall observer
        item.publisher(for: \.isPlaybackBufferEmpty)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEmpty in
                if isEmpty {
                    self?.isLoading = true
                }
            }
            .store(in: &cancellables)
        
        item.publisher(for: \.isPlaybackLikelyToKeepUp)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLikelyToKeepUp in
                if isLikelyToKeepUp {
                    self?.isLoading = false
                }
            }
            .store(in: &cancellables)
    }
    
    private func prepareForPlayback() async {
        guard let player = currentPlayer else { return }
        
        // Preroll to improve startup performance
        await player.preroll(atRate: 0.0)
        
        // Update available qualities
        updateAvailableQualities()
    }
    
    private func waitForPlayerReady() async throws {
        guard let player = currentPlayer else { return }
        
        return try await withCheckedThrowingContinuation { continuation in
            let observer = player.observe(\.currentItem?.status) { player, _ in
                guard let item = player.currentItem else { return }
                
                switch item.status {
                case .readyToPlay:
                    continuation.resume()
                case .failed:
                    if let error = item.error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: VideoStreamError.unknownError)
                    }
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
            
            // Clean up observer after 10 seconds timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                observer.invalidate()
                continuation.resume(throwing: VideoStreamError.timeout)
            }
        }
    }
    
    private func updatePlaybackProgress() {
        guard let player = currentPlayer,
              let duration = player.currentItem?.duration,
              duration.isValid && !duration.isIndefinite else { return }
        
        let currentTime = player.currentTime()
        playbackProgress = currentTime.seconds / duration.seconds
    }
    
    private func updateBufferProgress() {
        guard let player = currentPlayer,
              let duration = player.currentItem?.duration,
              let timeRanges = player.currentItem?.loadedTimeRanges,
              duration.isValid && !duration.isIndefinite else { return }
        
        let currentTime = player.currentTime()
        
        for value in timeRanges {
            let timeRange = value.timeRangeValue
            let startTime = timeRange.start
            let endTime = CMTimeAdd(startTime, timeRange.duration)
            
            if CMTimeRangeContainsTime(timeRange, time: currentTime) {
                bufferProgress = endTime.seconds / duration.seconds
                break
            }
        }
    }
    
    private func updateAvailableQualities() {
        // For HLS streams, qualities are automatically detected
        // For regular videos, provide standard quality options
        availableQualities = StreamQuality.allCases
    }
    
    private func handleTimeControlStatusChange(_ status: AVPlayer.TimeControlStatus) {
        switch status {
        case .playing:
            isPlaying = true
            isLoading = false
        case .paused:
            isPlaying = false
            isLoading = false
        case .waitingToPlayAtSpecifiedRate:
            isLoading = true
        @unknown default:
            break
        }
    }
    
    private func handlePlayerItemStatusChange(_ status: AVPlayerItem.Status) {
        switch status {
        case .readyToPlay:
            isLoading = false
            error = nil
        case .failed:
            if let playerError = currentPlayerItem?.error {
                error = VideoStreamError.playbackFailed(playerError.localizedDescription)
            } else {
                error = VideoStreamError.unknownError
            }
            isLoading = false
        case .unknown:
            isLoading = true
        @unknown default:
            break
        }
    }
    
    private func handleNetworkChange(_ path: NWPath) async {
        // Adapt streaming quality based on network conditions
        let networkQuality = assessNetworkQuality(path)
        
        if streamQuality == .auto {
            let recommendedQuality = adaptiveManager.getRecommendedQuality(for: networkQuality)
            if recommendedQuality != streamQuality {
                await setStreamQuality(recommendedQuality)
            }
        }
    }
    
    private func assessNetworkQuality(_ path: NWPath) -> NetworkQuality {
        if !path.isExpensive && path.availableInterfaces.contains(where: { $0.type == .wifi }) {
            return .high
        } else if path.availableInterfaces.contains(where: { $0.type == .cellular }) {
            return .medium
        } else {
            return .low
        }
    }
    
    private func removeTimeObserver() {
        if let observer = timeObserver {
            currentPlayer?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
    
    private func cleanup() {
        networkMonitor.cancel()
        removeTimeObserver()
        cancellables.removeAll()
        
        Task { @MainActor in
            await stopPlayback()
        }
    }
}

// MARK: - Supporting Types

public enum VideoStreamError: LocalizedError {
    case loadingFailed(String)
    case playbackFailed(String)
    case networkError(String)
    case timeout
    case unknownError
    
    public var errorDescription: String? {
        switch self {
        case .loadingFailed(let message):
            return "Failed to load video: \(message)"
        case .playbackFailed(let message):
            return "Playback failed: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .timeout:
            return "Request timed out"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}

public enum NetworkQuality {
    case low, medium, high
}

// MARK: - Adaptive Streaming Manager

public class AdaptiveStreamingManager {
    
    public func createHLSPlayerItem(from url: URL, preferredQuality: VideoStreamManager.StreamQuality) async throws -> AVPlayerItem {
        let asset = AVURLAsset(url: url)
        
        // Configure preferred peak bit rate for adaptive streaming
        let playerItem = AVPlayerItem(asset: asset)
        
        if preferredQuality != .auto {
            playerItem.preferredPeakBitRate = Double(preferredQuality.bitrate)
        }
        
        return playerItem
    }
    
    public func getRecommendedQuality(for networkQuality: NetworkQuality) -> VideoStreamManager.StreamQuality {
        switch networkQuality {
        case .low:
            return .low
        case .medium:
            return .medium
        case .high:
            return .high
        }
    }
}
