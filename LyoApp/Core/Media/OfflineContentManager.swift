import Foundation
import Network
import Combine

// MARK: - Offline Content Manager
@MainActor
public class OfflineContentManager: ObservableObject {
    // MARK: - Properties
    @Published public var downloadProgress: [String: Double] = [:]
    @Published public var downloadedContent: [String: OfflineContent] = [:]
    @Published public var availableStorage: Int64 = 0
    @Published public var usedStorage: Int64 = 0
    @Published public var isDownloading = false
    @Published public var downloadQueue: [DownloadTask] = []
    @Published public var error: OfflineContentError?
    
    private let fileManager = FileManager.default
    private let downloadSession: URLSession
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "OfflineContentNetworkMonitor")
    private var cancellables = Set<AnyCancellable>()
    private var activeDownloads: [String: URLSessionDownloadTask] = [:]
    
    // Storage paths
    private let documentsDirectory: URL
    private let offlineContentDirectory: URL
    private let metadataFile: URL
    
    // MARK: - Initialization
    public init() {
        // Setup directories
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Documents directory not found.")
        }
        offlineContentDirectory = documentsDirectory.appendingPathComponent("OfflineContent")
        metadataFile = offlineContentDirectory.appendingPathComponent("metadata.plist")
        
        // Create download session
        let config = URLSessionConfiguration.background(withIdentifier: "com.lyoapp.offline.downloads")
        config.allowsCellularAccess = false // Only download on WiFi by default
        config.isDiscretionary = true
        downloadSession = URLSession(configuration: config, delegate: DownloadDelegate(manager: self), delegateQueue: nil)
        
        setupDirectories()
        loadMetadata()
        updateStorageInfo()
        setupNetworkMonitoring()
    }
    
    deinit {
        networkMonitor.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Download content for offline access
    public func downloadContent(_ content: ContentToDownload) async throws {
        // Check storage availability
        try await checkStorageAvailability(for: content.estimatedSize)
        
        // Check if already downloaded
        if downloadedContent[content.id] != nil {
            throw OfflineContentError.alreadyDownloaded
        }
        
        // Check if already downloading
        if downloadProgress[content.id] != nil {
            throw OfflineContentError.alreadyInProgress
        }
        
        // Create download task
        let task = DownloadTask(
            id: content.id,
            url: content.url,
            title: content.title,
            estimatedSize: content.estimatedSize,
            priority: content.priority,
            createdAt: Date()
        )
        
        // Add to queue
        downloadQueue.append(task)
        downloadProgress[content.id] = 0.0
        
        // Start download
        try await startDownload(task)
    }
    
    /// Cancel download
    public func cancelDownload(_ contentId: String) {
        activeDownloads[contentId]?.cancel()
        activeDownloads.removeValue(forKey: contentId)
        downloadProgress.removeValue(forKey: contentId)
        downloadQueue.removeAll { $0.id == contentId }
    }
    
    /// Delete downloaded content
    public func deleteContent(_ contentId: String) throws {
        guard let content = downloadedContent[contentId] else {
            throw OfflineContentError.contentNotFound
        }
        
        // Delete files
        try fileManager.removeItem(at: content.localURL)
        
        // Update metadata
        downloadedContent.removeValue(forKey: contentId)
        try saveMetadata()
        
        // Update storage info
        updateStorageInfo()
    }
    
    /// Get local URL for downloaded content
    public func getLocalURL(for contentId: String) -> URL? {
        return downloadedContent[contentId]?.localURL
    }
    
    /// Check if content is available offline
    public func isAvailableOffline(_ contentId: String) -> Bool {
        guard let content = downloadedContent[contentId] else { return false }
        return fileManager.fileExists(atPath: content.localURL.path)
    }
    
    /// Get all downloaded content
    public func getAllDownloadedContent() -> [OfflineContent] {
        return Array(downloadedContent.values).sorted { $0.downloadedAt > $1.downloadedAt }
    }
    
    /// Clear all downloaded content
    public func clearAllContent() throws {
        // Cancel active downloads
        for (_, task) in activeDownloads {
            task.cancel()
        }
        activeDownloads.removeAll()
        downloadProgress.removeAll()
        downloadQueue.removeAll()
        
        // Delete content directory
        try fileManager.removeItem(at: offlineContentDirectory)
        
        // Recreate directory
        setupDirectories()
        
        // Clear metadata
        downloadedContent.removeAll()
        try saveMetadata()
        
        // Update storage info
        updateStorageInfo()
    }
    
    /// Pause all downloads
    public func pauseAllDownloads() {
        for (_, task) in activeDownloads {
            task.suspend()
        }
    }
    
    /// Resume all downloads
    public func resumeAllDownloads() {
        for (_, task) in activeDownloads {
            task.resume()
        }
    }
    
    /// Enable/disable cellular downloads
    public func setCellularDownloadsEnabled(_ enabled: Bool) {
        downloadSession.configuration.allowsCellularAccess = enabled
    }
    
    /// Set download quality preference
    public func setDownloadQuality(_ quality: DownloadQuality) {
        UserDefaults.standard.set(quality.rawValue, forKey: "offline_download_quality")
    }
    
    /// Get download quality preference
    public func getDownloadQuality() -> DownloadQuality {
        let rawValue = UserDefaults.standard.string(forKey: "offline_download_quality") ?? DownloadQuality.medium.rawValue
        return DownloadQuality(rawValue: rawValue) ?? .medium
    }
    
    // MARK: - Private Methods
    
    private func setupDirectories() {
        do {
            try fileManager.createDirectory(at: offlineContentDirectory, withIntermediateDirectories: true)
        } catch {
            print("Failed to create offline content directory: \(error)")
        }
    }
    
    private func loadMetadata() {
        guard fileManager.fileExists(atPath: metadataFile.path) else { return }
        
        do {
            let data = try Data(contentsOf: metadataFile)
            let metadata = try PropertyListDecoder().decode([String: OfflineContent].self, from: data)
            downloadedContent = metadata
        } catch {
            print("Failed to load offline content metadata: \(error)")
        }
    }
    
    private func saveMetadata() throws {
        let data = try PropertyListEncoder().encode(downloadedContent)
        try data.write(to: metadataFile)
    }
    
    private func updateStorageInfo() {
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: documentsDirectory.path)
            availableStorage = attributes[.systemFreeSize] as? Int64 ?? 0
            
            let contentSize = try calculateDirectorySize(offlineContentDirectory)
            usedStorage = contentSize
        } catch {
            print("Failed to update storage info: \(error)")
        }
    }
    
    private func calculateDirectorySize(_ directory: URL) throws -> Int64 {
        let urls = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey], options: .skipsHiddenFiles)
        return try urls.reduce(0) { total, url in
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            let size = attributes[.size] as? Int64 ?? 0
            return total + size
        }
    }
    
    private func checkStorageAvailability(for size: Int64) async throws {
        updateStorageInfo()
        
        let requiredSpace = size + (100 * 1024 * 1024) // Add 100MB buffer
        if availableStorage < requiredSpace {
            throw OfflineContentError.insufficientStorage(available: availableStorage, required: requiredSpace)
        }
    }
    
    private func startDownload(_ task: DownloadTask) async throws {
        isDownloading = true
        
        let downloadTask = downloadSession.downloadTask(with: task.url)
        activeDownloads[task.id] = downloadTask
        downloadTask.resume()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                await self?.handleNetworkChange(path)
            }
        }
        networkMonitor.start(queue: networkQueue)
    }
    
    private func handleNetworkChange(_ path: NWPath) async {
        if path.status == .satisfied {
            // Network available - resume downloads if on WiFi or cellular allowed
            let isWiFi = path.usesInterfaceType(.wifi)
            let cellularAllowed = downloadSession.configuration.allowsCellularAccess
            
            if isWiFi || cellularAllowed {
                resumeAllDownloads()
            } else {
                pauseAllDownloads()
            }
        } else {
            // Network unavailable - pause downloads
            pauseAllDownloads()
        }
    }
    
    fileprivate func handleDownloadCompletion(_ downloadTask: URLSessionDownloadTask, location: URL) {
        guard let originalURL = downloadTask.originalRequest?.url,
              let taskId = findTaskId(for: originalURL) else { return }
        
        do {
            // Move downloaded file to permanent location
            let filename = originalURL.lastPathComponent.isEmpty ? UUID().uuidString : originalURL.lastPathComponent
            let destinationURL = offlineContentDirectory.appendingPathComponent(filename)
            
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            try fileManager.moveItem(at: location, to: destinationURL)
            
            // Get file size
            let attributes = try fileManager.attributesOfItem(atPath: destinationURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            
            // Create offline content record
            let content = OfflineContent(
                id: taskId,
                localURL: destinationURL,
                originalURL: originalURL,
                fileSize: fileSize,
                downloadedAt: Date(),
                lastAccessedAt: Date()
            )
            
            // Update metadata
            downloadedContent[taskId] = content
            try saveMetadata()
            
            // Clean up
            activeDownloads.removeValue(forKey: taskId)
            downloadProgress.removeValue(forKey: taskId)
            downloadQueue.removeAll { $0.id == taskId }
            
            // Update storage info
            updateStorageInfo()
            
            if activeDownloads.isEmpty {
                isDownloading = false
            }
            
        } catch {
            error = OfflineContentError.downloadFailed(error.localizedDescription)
        }
    }
    
    fileprivate func handleDownloadProgress(_ downloadTask: URLSessionDownloadTask, bytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let originalURL = downloadTask.originalRequest?.url,
              let taskId = findTaskId(for: originalURL) else { return }
        
        let progress = Double(bytesWritten) / Double(totalBytesExpectedToWrite)
        downloadProgress[taskId] = progress
    }
    
    fileprivate func handleDownloadError(_ downloadTask: URLSessionDownloadTask, error: Error) {
        guard let originalURL = downloadTask.originalRequest?.url,
              let taskId = findTaskId(for: originalURL) else { return }
        
        // Remove from active downloads
        activeDownloads.removeValue(forKey: taskId)
        downloadProgress.removeValue(forKey: taskId)
        downloadQueue.removeAll { $0.id == taskId }
        
        if activeDownloads.isEmpty {
            isDownloading = false
        }
        
        self.error = OfflineContentError.downloadFailed(error.localizedDescription)
    }
    
    private func findTaskId(for url: URL) -> String? {
        return downloadQueue.first { $0.url == url }?.id
    }
}

// MARK: - Supporting Types

public struct ContentToDownload {
    public let id: String
    public let url: URL
    public let title: String
    public let estimatedSize: Int64
    public let priority: DownloadPriority
    
    public init(id: String, url: URL, title: String, estimatedSize: Int64, priority: DownloadPriority = .normal) {
        self.id = id
        self.url = url
        self.title = title
        self.estimatedSize = estimatedSize
        self.priority = priority
    }
}

public struct DownloadTask: Codable {
    public let id: String
    public let url: URL
    public let title: String
    public let estimatedSize: Int64
    public let priority: DownloadPriority
    public let createdAt: Date
}

public struct OfflineContent: Codable {
    public let id: String
    public let localURL: URL
    public let originalURL: URL
    public let fileSize: Int64
    public let downloadedAt: Date
    public var lastAccessedAt: Date
}

public enum DownloadPriority: String, Codable, CaseIterable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case urgent = "urgent"
}

public enum DownloadQuality: String, CaseIterable {
    case low = "360p"
    case medium = "720p"
    case high = "1080p"
    case ultra = "4K"
    
    var bitrate: Int {
        switch self {
        case .low: return 800_000
        case .medium: return 2_500_000
        case .high: return 5_000_000
        case .ultra: return 15_000_000
        }
    }
}

public enum OfflineContentError: LocalizedError {
    case alreadyDownloaded
    case alreadyInProgress
    case contentNotFound
    case insufficientStorage(available: Int64, required: Int64)
    case downloadFailed(String)
    case networkUnavailable
    
    public var errorDescription: String? {
        switch self {
        case .alreadyDownloaded:
            return "Content is already downloaded"
        case .alreadyInProgress:
            return "Download is already in progress"
        case .contentNotFound:
            return "Content not found"
        case .insufficientStorage(let available, let required):
            let availableMB = available / (1024 * 1024)
            let requiredMB = required / (1024 * 1024)
            return "Insufficient storage. Available: \(availableMB)MB, Required: \(requiredMB)MB"
        case .downloadFailed(let message):
            return "Download failed: \(message)"
        case .networkUnavailable:
            return "Network is not available"
        }
    }
}

// MARK: - Download Delegate

private class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    weak var manager: OfflineContentManager?
    
    init(manager: OfflineContentManager) {
        self.manager = manager
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        Task { @MainActor in
            manager?.handleDownloadCompletion(downloadTask, location: location)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        Task { @MainActor in
            manager?.handleDownloadProgress(downloadTask, bytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error, let downloadTask = task as? URLSessionDownloadTask {
            Task { @MainActor in
                manager?.handleDownloadError(downloadTask, error: error)
            }
        }
    }
}
