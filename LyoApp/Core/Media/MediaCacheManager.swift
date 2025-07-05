import Foundation
import UIKit
import Combine

// MARK: - Media Cache Manager
@MainActor
public class MediaCacheManager: ObservableObject {
    // MARK: - Properties
    @Published public var cacheSize: Int64 = 0
    @Published public var cacheItems: [CacheItem] = []
    @Published public var isClearing = false
    @Published public var error: CacheError?
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let metadataFile: URL
    private let maxCacheSize: Int64
    private let maxItemAge: TimeInterval
    private var cancellables = Set<AnyCancellable>()
    
    // Cache policies
    private let imageCachePolicy: CachePolicy
    private let videoCachePolicy: CachePolicy
    private let audioCachePolicy: CachePolicy
    
    // MARK: - Initialization
    public init(maxCacheSize: Int64 = 500 * 1024 * 1024, // 500MB default
                maxItemAge: TimeInterval = 7 * 24 * 60 * 60) { // 7 days default
        
        // Setup cache directory
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Could not find documents directory.")
        }
        cacheDirectory = documentsDirectory.appendingPathComponent("MediaCache")
        metadataFile = cacheDirectory.appendingPathComponent("cache_metadata.plist")
        
        self.maxCacheSize = maxCacheSize
        self.maxItemAge = maxItemAge
        
        // Initialize cache policies
        self.imageCachePolicy = CachePolicy(
            maxSize: maxCacheSize / 4, // 25% for images
            compressionQuality: 0.8,
            allowedFormats: [.jpeg, .png, .webp]
        )
        
        self.videoCachePolicy = CachePolicy(
            maxSize: maxCacheSize / 2, // 50% for videos
            compressionQuality: 0.7,
            allowedFormats: [.mp4, .mov, .m4v]
        )
        
        self.audioCachePolicy = CachePolicy(
            maxSize: maxCacheSize / 4, // 25% for audio
            compressionQuality: 0.8,
            allowedFormats: [.mp3, .aac, .m4a]
        )
        
        setupCacheDirectory()
        loadMetadata()
        updateCacheSize()
        setupPeriodicCleanup()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Public Methods
    
    /// Cache image data
    public func cacheImage(_ data: Data, for key: String, originalURL: URL? = nil) async throws {
        let cacheItem = try await createCacheItem(
            key: key,
            data: data,
            type: .image,
            originalURL: originalURL,
            policy: imageCachePolicy
        )
        
        try await storeCacheItem(cacheItem)
    }
    
    /// Cache video data
    public func cacheVideo(_ url: URL, for key: String) async throws {
        let data = try Data(contentsOf: url)
        let cacheItem = try await createCacheItem(
            key: key,
            data: data,
            type: .video,
            originalURL: url,
            policy: videoCachePolicy
        )
        
        try await storeCacheItem(cacheItem)
    }
    
    /// Cache audio data
    public func cacheAudio(_ data: Data, for key: String, originalURL: URL? = nil) async throws {
        let cacheItem = try await createCacheItem(
            key: key,
            data: data,
            type: .audio,
            originalURL: originalURL,
            policy: audioCachePolicy
        )
        
        try await storeCacheItem(cacheItem)
    }
    
    /// Retrieve cached data
    public func getCachedData(for key: String) -> Data? {
        guard let item = findCacheItem(key: key) else { return nil }
        
        // Check if item is expired
        if isExpired(item) {
            Task {
                try? await removeCacheItem(key)
            }
            return nil
        }
        
        // Update access time
        updateAccessTime(for: key)
        
        // Read data from file
        do {
            return try Data(contentsOf: item.fileURL)
        } catch {
            print("Failed to read cached data: \(error)")
            return nil
        }
    }
    
    /// Get cached image
    public func getCachedImage(for key: String) -> UIImage? {
        guard let data = getCachedData(for: key) else { return nil }
        return UIImage(data: data)
    }
    
    /// Get cached file URL
    public func getCachedFileURL(for key: String) -> URL? {
        guard let item = findCacheItem(key: key) else { return nil }
        
        if isExpired(item) {
            Task {
                try? await removeCacheItem(key)
            }
            return nil
        }
        
        updateAccessTime(for: key)
        return item.fileURL
    }
    
    /// Check if item is cached
    public func isCached(_ key: String) -> Bool {
        guard let item = findCacheItem(key: key) else { return false }
        return !isExpired(item) && fileManager.fileExists(atPath: item.fileURL.path)
    }
    
    /// Remove specific cache item
    public func removeCacheItem(_ key: String) async throws {
        guard let item = findCacheItem(key: key) else { return }
        
        // Remove file
        if fileManager.fileExists(atPath: item.fileURL.path) {
            try fileManager.removeItem(at: item.fileURL)
        }
        
        // Remove from metadata
        cacheItems.removeAll { $0.key == key }
        try saveMetadata()
        updateCacheSize()
    }
    
    /// Clear cache by type
    public func clearCache(type: CacheItemType) async throws {
        isClearing = true
        defer { isClearing = false }
        
        let itemsToRemove = cacheItems.filter { $0.type == type }
        
        for item in itemsToRemove {
            try await removeCacheItem(item.key)
        }
    }
    
    /// Clear all cache
    public func clearAllCache() async throws {
        isClearing = true
        defer { isClearing = false }
        
        // Remove all files
        let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        for url in contents {
            if url != metadataFile {
                try fileManager.removeItem(at: url)
            }
        }
        
        // Clear metadata
        cacheItems.removeAll()
        try saveMetadata()
        updateCacheSize()
    }
    
    /// Clear expired items
    public func clearExpiredItems() async throws {
        let expiredItems = cacheItems.filter { isExpired($0) }
        
        for item in expiredItems {
            try await removeCacheItem(item.key)
        }
    }
    
    /// Get cache statistics
    public func getCacheStatistics() -> CacheStatistics {
        let imageItems = cacheItems.filter { $0.type == .image }
        let videoItems = cacheItems.filter { $0.type == .video }
        let audioItems = cacheItems.filter { $0.type == .audio }
        
        return CacheStatistics(
            totalSize: cacheSize,
            totalItems: cacheItems.count,
            imageCount: imageItems.count,
            videoCount: videoItems.count,
            audioCount: audioItems.count,
            imageSize: imageItems.reduce(0) { $0 + $1.size },
            videoSize: videoItems.reduce(0) { $0 + $1.size },
            audioSize: audioItems.reduce(0) { $0 + $1.size },
            oldestItem: cacheItems.min { $0.createdAt < $1.createdAt }?.createdAt,
            newestItem: cacheItems.max { $0.createdAt < $1.createdAt }?.createdAt
        )
    }
    
    /// Set cache size limit
    public func setCacheSizeLimit(_ limit: Int64) {
        UserDefaults.standard.set(limit, forKey: "media_cache_size_limit")
        
        // Trigger cleanup if current size exceeds new limit
        if cacheSize > limit {
            Task {
                try? await enforceStorageLimit()
            }
        }
    }
    
    /// Get cache size limit
    public func getCacheSizeLimit() -> Int64 {
        let savedLimit = UserDefaults.standard.object(forKey: "media_cache_size_limit") as? Int64
        return savedLimit ?? maxCacheSize
    }
    
    // MARK: - Private Methods
    
    private func setupCacheDirectory() {
        do {
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        } catch {
            print("Failed to create cache directory: \(error)")
        }
    }
    
    private func loadMetadata() {
        guard fileManager.fileExists(atPath: metadataFile.path) else { return }
        
        do {
            let data = try Data(contentsOf: metadataFile)
            cacheItems = try PropertyListDecoder().decode([CacheItem].self, from: data)
        } catch {
            print("Failed to load cache metadata: \(error)")
        }
    }
    
    private func saveMetadata() throws {
        let data = try PropertyListEncoder().encode(cacheItems)
        try data.write(to: metadataFile)
    }
    
    private func updateCacheSize() {
        do {
            let urls = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey]
            )
            
            cacheSize = try urls.reduce(0) { total, url in
                guard url != metadataFile else { return total }
                let attributes = try fileManager.attributesOfItem(atPath: url.path)
                let size = attributes[.size] as? Int64 ?? 0
                return total + size
            }
        } catch {
            print("Failed to calculate cache size: \(error)")
        }
    }
    
    private func createCacheItem(
        key: String,
        data: Data,
        type: CacheItemType,
        originalURL: URL?,
        policy: CachePolicy
    ) async throws -> CacheItem {
        
        // Compress data if needed
        let processedData = try await processData(data, type: type, policy: policy)
        
        // Generate file URL
        let filename = "\(key.hashValue).\(type.fileExtension)"
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        // Create cache item
        return CacheItem(
            key: key,
            fileURL: fileURL,
            size: Int64(processedData.count),
            type: type,
            createdAt: Date(),
            lastAccessedAt: Date(),
            originalURL: originalURL
        )
    }
    
    private func processData(_ data: Data, type: CacheItemType, policy: CachePolicy) async throws -> Data {
        switch type {
        case .image:
            return try await compressImage(data, quality: policy.compressionQuality)
        case .video:
            // For videos, we might implement compression in the future
            return data
        case .audio:
            // For audio, we might implement compression in the future
            return data
        }
    }
    
    private func compressImage(_ data: Data, quality: Float) async throws -> Data {
        guard let image = UIImage(data: data) else {
            throw CacheError.invalidImageData
        }
        
        guard let compressedData = image.jpegData(compressionQuality: CGFloat(quality)) else {
            throw CacheError.compressionFailed
        }
        
        return compressedData
    }
    
    private func storeCacheItem(_ item: CacheItem) async throws {
        // Check storage limits
        try await enforceStorageLimit()
        
        // Add to cache items
        cacheItems.append(item)
        
        // Save metadata
        try saveMetadata()
        
        // Update cache size
        updateCacheSize()
    }
    
    private func enforceStorageLimit() async throws {
        let currentLimit = getCacheSizeLimit()
        
        while cacheSize > currentLimit && !cacheItems.isEmpty {
            // Remove least recently used item
            if let lruItem = findLeastRecentlyUsedItem() {
                try await removeCacheItem(lruItem.key)
            } else {
                break
            }
        }
    }
    
    private func findCacheItem(key: String) -> CacheItem? {
        return cacheItems.first { $0.key == key }
    }
    
    private func findLeastRecentlyUsedItem() -> CacheItem? {
        return cacheItems.min { $0.lastAccessedAt < $1.lastAccessedAt }
    }
    
    private func isExpired(_ item: CacheItem) -> Bool {
        return Date().timeIntervalSince(item.createdAt) > maxItemAge
    }
    
    private func updateAccessTime(for key: String) {
        if let index = cacheItems.firstIndex(where: { $0.key == key }) {
            cacheItems[index].lastAccessedAt = Date()
            
            // Save metadata asynchronously
            Task {
                try? saveMetadata()
            }
        }
    }
    
    private func setupPeriodicCleanup() {
        // Setup timer to periodically clean expired items
        Timer.publish(every: 3600, on: .main, in: .common) // Every hour
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    try? await self?.clearExpiredItems()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Supporting Types

public struct CacheItem: Codable {
    public let key: String
    public let fileURL: URL
    public let size: Int64
    public let type: CacheItemType
    public let createdAt: Date
    public var lastAccessedAt: Date
    public let originalURL: URL?
}

public enum CacheItemType: String, Codable, CaseIterable {
    case image = "image"
    case video = "video"
    case audio = "audio"
    
    var fileExtension: String {
        switch self {
        case .image: return "jpg"
        case .video: return "mp4"
        case .audio: return "m4a"
        }
    }
}

public struct CachePolicy {
    public let maxSize: Int64
    public let compressionQuality: Float
    public let allowedFormats: [MediaFormat]
}

public enum MediaFormat: String, CaseIterable {
    case jpeg = "jpeg"
    case png = "png"
    case webp = "webp"
    case mp4 = "mp4"
    case mov = "mov"
    case m4v = "m4v"
    case mp3 = "mp3"
    case aac = "aac"
    case m4a = "m4a"
}

public struct CacheStatistics {
    public let totalSize: Int64
    public let totalItems: Int
    public let imageCount: Int
    public let videoCount: Int
    public let audioCount: Int
    public let imageSize: Int64
    public let videoSize: Int64
    public let audioSize: Int64
    public let oldestItem: Date?
    public let newestItem: Date?
}

public enum CacheError: LocalizedError {
    case invalidImageData
    case compressionFailed
    case storageLimitExceeded
    case itemNotFound
    
    public var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Invalid image data"
        case .compressionFailed:
            return "Failed to compress media"
        case .storageLimitExceeded:
            return "Storage limit exceeded"
        case .itemNotFound:
            return "Cache item not found"
        }
    }
}
