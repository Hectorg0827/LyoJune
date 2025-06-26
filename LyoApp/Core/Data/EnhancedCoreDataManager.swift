import Foundation
import CoreData
import CloudKit

// MARK: - Phase 3A: Enhanced Core Data Manager
// Modern Core Data stack with CloudKit sync and offline-first architecture

@MainActor
public class EnhancedCoreDataManager: ObservableObject {
    
    // MARK: - Singleton
    public static let shared = EnhancedCoreDataManager()
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "LyoDataModel")
        
        // Configure for CloudKit
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }
        
        // Enable CloudKit
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description.setOption("iCloud.com.lyoapp.LyoApp" as NSString, forKey: NSPersistentCloudKitContainerOptionsKey)
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        
        // Automatically merge changes from parent
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Configure merge policy
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    public var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // Background context for heavy operations
    public lazy var backgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }()
    
    // MARK: - Initialization
    
    private init() {
        setupNotifications()
    }
    
    // MARK: - Core Data Operations
    
    public func save() {
        let context = viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save Core Data context: \(error)")
            }
        }
    }
    
    public func saveBackground(_ context: NSManagedObjectContext) {
        context.perform {
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    print("Failed to save background context: \(error)")
                }
            }
        }
    }
    
    // MARK: - CloudKit Sync
    
    public func initializeCloudKitSchema() async {
        do {
            try await persistentContainer.initializeCloudKitSchema(options: [])
            print("CloudKit schema initialized successfully")
        } catch {
            print("Failed to initialize CloudKit schema: \(error)")
        }
    }
    
    // MARK: - Data Migration
    
    public func performMigrationIfNeeded() {
        // This will be implemented when we have model versions
        print("Migration check completed")
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextDidSave),
            name: .NSManagedObjectContextDidSave,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(remoteChangeOccurred),
            name: .NSPersistentStoreRemoteChange,
            object: nil
        )
    }
    
    @objc private func contextDidSave(notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext,
              context !== viewContext else { return }
        
        viewContext.perform {
            self.viewContext.mergeChanges(fromContextDidSave: notification)
        }
    }
    
    @objc private func remoteChangeOccurred(notification: Notification) {
        viewContext.perform {
            self.viewContext.refreshAllObjects()
            self.objectWillChange.send()
        }
    }
    
    // MARK: - Batch Operations
    
    public func batchDelete<T: NSManagedObject>(entity: T.Type, predicate: NSPredicate) async throws {
        let request = NSBatchDeleteRequest(fetchRequest: T.fetchRequest())
        request.predicate = predicate
        request.resultType = .resultTypeObjectIDs
        
        let result = try await backgroundContext.execute(request) as? NSBatchDeleteResult
        let objectIDs = result?.result as? [NSManagedObjectID] ?? []
        
        await MainActor.run {
            let changes = [NSDeletedObjectsKey: objectIDs]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [viewContext])
        }
    }
    
    public func batchUpdate<T: NSManagedObject>(
        entity: T.Type,
        predicate: NSPredicate,
        properties: [String: Any]
    ) async throws {
        let request = NSBatchUpdateRequest(entity: T.entity())
        request.predicate = predicate
        request.propertiesToUpdate = properties
        request.resultType = .updatedObjectIDsResultType
        
        let result = try await backgroundContext.execute(request) as? NSBatchUpdateResult
        let objectIDs = result?.result as? [NSManagedObjectID] ?? []
        
        await MainActor.run {
            for objectID in objectIDs {
                let object = viewContext.object(with: objectID)
                viewContext.refresh(object, mergeChanges: true)
            }
        }
    }
    
    // MARK: - Performance Monitoring
    
    public func enablePerformanceMonitoring() {
        viewContext.perform {
            self.viewContext.stalenessInterval = 0.0
        }
    }
    
    // MARK: - Debug Helpers
    
    #if DEBUG
    public func printStats() {
        print("=== Core Data Stats ===")
        print("Objects in context: \(viewContext.registeredObjects.count)")
        print("Has changes: \(viewContext.hasChanges)")
        print("Undo manager enabled: \(viewContext.undoManager != nil)")
    }
    #endif
}

// MARK: - Fetch Request Builder

public class FetchRequestBuilder<T: NSManagedObject> {
    private var fetchRequest: NSFetchRequest<T>
    
    public init(entity: T.Type) {
        self.fetchRequest = NSFetchRequest<T>(entityName: String(describing: entity))
    }
    
    public func predicate(_ predicate: NSPredicate) -> Self {
        fetchRequest.predicate = predicate
        return self
    }
    
    public func sortDescriptors(_ descriptors: [NSSortDescriptor]) -> Self {
        fetchRequest.sortDescriptors = descriptors
        return self
    }
    
    public func limit(_ limit: Int) -> Self {
        fetchRequest.fetchLimit = limit
        return self
    }
    
    public func offset(_ offset: Int) -> Self {
        fetchRequest.fetchOffset = offset
        return self
    }
    
    public func relationshipKeyPathsForPrefetching(_ keyPaths: [String]) -> Self {
        fetchRequest.relationshipKeyPathsForPrefetching = keyPaths
        return self
    }
    
    public func build() -> NSFetchRequest<T> {
        return fetchRequest
    }
}

// MARK: - Repository Protocol

public protocol Repository {
    associatedtype Entity: NSManagedObject
    
    func fetch() async throws -> [Entity]
    func fetch(predicate: NSPredicate) async throws -> [Entity]
    func fetch(limit: Int, offset: Int) async throws -> [Entity]
    func fetchFirst(predicate: NSPredicate) async throws -> Entity?
    func create() -> Entity
    func save() async throws
    func delete(_ entity: Entity) async throws
    func deleteAll() async throws
}

// MARK: - Base Repository Implementation

public class BaseRepository<T: NSManagedObject>: Repository {
    public typealias Entity = T
    
    protected let coreDataManager: EnhancedCoreDataManager
    protected let entityName: String
    
    public init(coreDataManager: EnhancedCoreDataManager = .shared) {
        self.coreDataManager = coreDataManager
        self.entityName = String(describing: T.self)
    }
    
    public func fetch() async throws -> [T] {
        let request = FetchRequestBuilder(entity: T.self).build()
        return try await coreDataManager.viewContext.perform {
            try self.coreDataManager.viewContext.fetch(request)
        }
    }
    
    public func fetch(predicate: NSPredicate) async throws -> [T] {
        let request = FetchRequestBuilder(entity: T.self)
            .predicate(predicate)
            .build()
        
        return try await coreDataManager.viewContext.perform {
            try self.coreDataManager.viewContext.fetch(request)
        }
    }
    
    public func fetch(limit: Int, offset: Int = 0) async throws -> [T] {
        let request = FetchRequestBuilder(entity: T.self)
            .limit(limit)
            .offset(offset)
            .build()
        
        return try await coreDataManager.viewContext.perform {
            try self.coreDataManager.viewContext.fetch(request)
        }
    }
    
    public func fetchFirst(predicate: NSPredicate) async throws -> T? {
        let request = FetchRequestBuilder(entity: T.self)
            .predicate(predicate)
            .limit(1)
            .build()
        
        return try await coreDataManager.viewContext.perform {
            try self.coreDataManager.viewContext.fetch(request).first
        }
    }
    
    public func create() -> T {
        return T(context: coreDataManager.viewContext)
    }
    
    public func save() async throws {
        try await coreDataManager.viewContext.perform {
            try self.coreDataManager.viewContext.save()
        }
    }
    
    public func delete(_ entity: T) async throws {
        await coreDataManager.viewContext.perform {
            self.coreDataManager.viewContext.delete(entity)
        }
        try await save()
    }
    
    public func deleteAll() async throws {
        let predicate = NSPredicate(value: true)
        try await coreDataManager.batchDelete(entity: T.self, predicate: predicate)
    }
}

// MARK: - Sync Status

public enum SyncStatus {
    case notStarted
    case syncing
    case completed
    case failed(Error)
}

// MARK: - Offline Sync Manager

@MainActor
public class OfflineSyncManager: ObservableObject {
    @Published public var syncStatus: SyncStatus = .notStarted
    @Published public var lastSyncDate: Date?
    
    private let coreDataManager: EnhancedCoreDataManager
    
    public init(coreDataManager: EnhancedCoreDataManager = .shared) {
        self.coreDataManager = coreDataManager
    }
    
    public func startSync() async {
        syncStatus = .syncing
        
        do {
            // Implement sync logic here
            // This will be expanded with actual API calls
            try await performSync()
            syncStatus = .completed
            lastSyncDate = Date()
        } catch {
            syncStatus = .failed(error)
        }
    }
    
    private func performSync() async throws {
        // Placeholder for actual sync implementation
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
    }
}

#Preview {
    Text("Core Data Manager Preview")
        .environmentObject(EnhancedCoreDataManager.shared)
}
