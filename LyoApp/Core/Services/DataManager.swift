import Foundation
import Combine
import CoreData

// MARK: - Data Manager
@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var isLoading = false
    @Published var lastSyncDate: Date?
    
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        lastSyncDate = userDefaults.object(forKey: Constants.UserDefaultsKeys.lastSyncDate) as? Date
        setupPeriodicSync()
    }
    
    // MARK: - Core Data Stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "LyoApp")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save Core Data context: \(error)")
            }
        }
    }
    
    // MARK: - Cache Management
    func clearCache() {
        let cacheURL = Constants.FilePaths.caches
        try? FileManager.default.removeItem(at: cacheURL)
        try? FileManager.default.createDirectory(at: cacheURL, withIntermediateDirectories: true)
    }
    
    func getCacheSize() -> Int64 {
        let cacheURL = Constants.FilePaths.caches
        guard let enumerator = FileManager.default.enumerator(at: cacheURL, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                  let fileSize = resourceValues.fileSize else {
                continue
            }
            totalSize += Int64(fileSize)
        }
        
        return totalSize
    }
    
    // MARK: - Offline Content Management
    func saveForOffline<T: Codable>(_ data: T, key: String) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let encoded = try encoder.encode(data)
            let url = Constants.FilePaths.offlineContent.appendingPathComponent("\(key).json")
            
            // Create directory if it doesn't exist
            try FileManager.default.createDirectory(
                at: Constants.FilePaths.offlineContent,
                withIntermediateDirectories: true,
                attributes: nil
            )
            
            try encoded.write(to: url)
        } catch {
            print("Failed to save offline data for key \(key): \(error)")
        }
    }
    
    func loadFromOffline<T: Codable>(_ type: T.Type, key: String) -> T? {
        let url = Constants.FilePaths.offlineContent.appendingPathComponent("\(key).json")
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(type, from: data)
        } catch {
            print("Failed to load offline data for key \(key): \(error)")
            return nil
        }
    }
    
    func removeOfflineData(key: String) {
        let url = Constants.FilePaths.offlineContent.appendingPathComponent("\(key).json")
        try? FileManager.default.removeItem(at: url)
    }
    
    // MARK: - User Preferences
    func setUserPreference<T: Codable>(_ value: T, forKey key: String) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(value)
            userDefaults.set(data, forKey: key)
        } catch {
            print("Failed to save user preference for key \(key): \(error)")
        }
    }
    
    func getUserPreference<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(type, from: data)
        } catch {
            print("Failed to load user preference for key \(key): \(error)")
            return nil
        }
    }
    
    func removeUserPreference(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
    
    // MARK: - Sync Management
    func syncData() async {
        guard NetworkManager.shared.isOnline else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Sync user data
            await syncUserData()
            
            // Sync content data
            await syncContentData()
            
            // Update last sync date
            lastSyncDate = Date()
            userDefaults.set(lastSyncDate, forKey: Constants.UserDefaultsKeys.lastSyncDate)
            
            NotificationCenter.default.post(name: Constants.NotificationNames.dataDidSync, object: nil)
            
        } catch {
            print("Sync failed: \(error)")
        }
    }
    
    private func syncUserData() async {
        // Sync user profile and preferences
        // Implementation would depend on specific API endpoints
    }
    
    private func syncContentData() async {
        // Sync courses, posts, and other content
        // Implementation would depend on specific API endpoints
    }
    
    private func setupPeriodicSync() {
        // Sync every 5 minutes when app is active
        Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.syncData()
                }
            }
            .store(in: &cancellables)
        
        // Sync when app becomes active
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task {
                    await self?.syncData()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - File Management
    func saveFile(data: Data, filename: String, in directory: URL) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        
        let fileURL = directory.appendingPathComponent(filename)
        try data.write(to: fileURL)
        
        return fileURL
    }
    
    func deleteFile(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
    
    func fileExists(at url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    // MARK: - Analytics Data
    func trackEvent(_ event: String, parameters: [String: Any] = [:]) {
        guard Constants.FeatureFlags.enableAnalytics else { return }
        
        let eventData: [String: Any] = [
            "event": event,
            "parameters": parameters,
            "timestamp": Date().timeIntervalSince1970,
            "userId": AuthService.shared.currentUser?.id ?? "anonymous"
        ]
        
        // Store locally and sync later
        saveForOffline(eventData, key: "analytics_\(UUID().uuidString)")
    }
}

// MARK: - Cache Policy
enum CachePolicy {
    case cacheFirst
    case networkFirst
    case networkOnly
    case cacheOnly
}

// MARK: - Cached Resource Manager
class CachedResourceManager {
    static let shared = CachedResourceManager()
    
    private let cache = NSCache<NSString, NSData>()
    private let queue = DispatchQueue(label: "com.lyo.cache", qos: .utility)
    
    private init() {
        cache.totalCostLimit = Constants.Limits.cacheSize
    }
    
    func getData(for url: URL, policy: CachePolicy = .cacheFirst) async throws -> Data {
        let key = url.absoluteString as NSString
        
        switch policy {
        case .cacheOnly:
            if let cachedData = cache.object(forKey: key) {
                return cachedData as Data
            } else {
                throw NetworkError.noData
            }
            
        case .networkOnly:
            let data = try await downloadData(from: url)
            cache.setObject(data as NSData, forKey: key, cost: data.count)
            return data
            
        case .cacheFirst:
            if let cachedData = cache.object(forKey: key) {
                return cachedData as Data
            } else {
                let data = try await downloadData(from: url)
                cache.setObject(data as NSData, forKey: key, cost: data.count)
                return data
            }
            
        case .networkFirst:
            do {
                let data = try await downloadData(from: url)
                cache.setObject(data as NSData, forKey: key, cost: data.count)
                return data
            } catch {
                if let cachedData = cache.object(forKey: key) {
                    return cachedData as Data
                } else {
                    throw error
                }
            }
        }
    }
    
    private func downloadData(from url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}
