//
//  CoreDataStack.swift
//  LyoApp
//
//  Created by LyoApp Development Team on 12/25/24.
//  Copyright © 2024 LyoApp. All rights reserved.
//

import Foundation
import CoreData
import CloudKit
import OSLog

/// Advanced Core Data stack with CloudKit integration, migrations, and performance optimization
@MainActor
public class CoreDataStack: ObservableObject {
    
    // MARK: - Properties
    
    static let shared = CoreDataStack()
    
    private let logger = Logger(subsystem: "com.lyoapp.coredata", category: "CoreDataStack")
    
    /// The main persistent container
    private var persistentContainer: NSPersistentCloudKitContainer?
    
    /// Main context for UI operations (main queue)
    public var viewContext: NSManagedObjectContext {
        return persistentContainer?.viewContext
    }
    
    /// Background context for data operations
    public lazy var backgroundContext: NSManagedObjectContext = {
        guard let container = persistentContainer else {
            fatalError("Persistent container not initialized.")
        }
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        return context
    }()
    
    /// Private context for import operations
    public lazy var privateContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = viewContext
        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        return context
    }()
    
    /// CloudKit sync status
    @Published public var cloudKitStatus: CloudKitStatus = .unknown
    @Published public var syncProgress: Double = 0.0
    @Published public var lastSyncDate: Date?
    @Published public var syncError: Error?
    
    // MARK: - Initialization
    
    private init() {
        setupCoreDataStack()
        setupCloudKitSync()
        observeContextChanges()
    }
    
    // MARK: - Core Data Stack Setup
    
    private func setupCoreDataStack() {
        logger.info("Setting up Core Data stack")
        
        guard let modelURL = Bundle.main.url(forResource: "LyoDataModel", withExtension: "momd"),
              let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            logger.critical("Failed to load Core Data model")
            return
        }
        
        persistentContainer = NSPersistentCloudKitContainer(name: "LyoDataModel", managedObjectModel: managedObjectModel)
        
        // Configure persistent store descriptions
        configurePersistentStoreDescriptions()
        
        // Load persistent stores
        loadPersistentStores()
        
        // Configure view context
        configureViewContext()
        
        logger.info("Core Data stack setup completed")
    }
    
    private func configurePersistentStoreDescriptions() {
        guard let description = persistentContainer?.persistentStoreDescriptions.first else {
            logger.critical("Failed to retrieve persistent store description")
            return
        }
        
        // Enable CloudKit
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // CloudKit configuration
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.lyoapp.container"
        )
        
        // Performance optimizations
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        
        // SQLite specific options
        description.setOption("DELETE" as NSString, forKey: "journal_mode")
        description.setOption("MEMORY" as NSString, forKey: "synchronous")
        description.setOption(NSNumber(value: 20000), forKey: "cache_size")
    }
    
    private func loadPersistentStores() {
        var loadError: Error?
        
        persistentContainer?.loadPersistentStores { [weak self] (storeDescription, error) in
            if let error = error {
                self?.logger.error("Failed to load persistent store: \(error.localizedDescription)")
                self?.persistentContainer = nil
                loadError = error
            } else {
                self?.logger.info("Persistent store loaded successfully: \(storeDescription.description)")
            }
        }
        
        if let error = loadError {
            // Handle store loading error
            handleStoreLoadingError(error)
        }
    }
    
    private func configureViewContext() {
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        viewContext.automaticallyMergesChangesFromParent = true
        
        // Performance settings
        viewContext.undoManager = nil
        viewContext.shouldDeleteInaccessibleFaults = true
        
        // Memory management
        viewContext.stalenessInterval = 0.0
    }
    
    // MARK: - CloudKit Setup
    
    private func setupCloudKitSync() {
        logger.info("Setting up CloudKit sync")
        
        // Check CloudKit availability
        checkCloudKitAvailability()
        
        // Set up remote change notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: persistentContainer.persistentStoreCoordinator
        )
        
        // Set up CloudKit sync notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudKitImportProgress(_:)),
            name: NSPersistentCloudKitContainer.eventChangedNotification,
            object: persistentContainer
        )
    }
    
    private func checkCloudKitAvailability() {
        CKContainer.default().accountStatus { [weak self] (accountStatus, error) in
            DispatchQueue.main.async {
                self?.updateCloudKitStatus(accountStatus: accountStatus, error: error)
            }
        }
    }
    
    private func updateCloudKitStatus(accountStatus: CKAccountStatus, error: Error?) {
        if let error = error {
            logger.error("CloudKit account error: \(error.localizedDescription)")
            cloudKitStatus = .error(error)
            syncError = error
            return
        }
        
        switch accountStatus {
        case .available:
            cloudKitStatus = .available
            logger.info("CloudKit account is available")
        case .noAccount:
            cloudKitStatus = .noAccount
            logger.warning("No iCloud account configured")
        case .restricted:
            cloudKitStatus = .restricted
            logger.warning("iCloud account is restricted")
        case .couldNotDetermine:
            cloudKitStatus = .unknown
            logger.warning("Could not determine iCloud account status")
        case .temporarilyUnavailable:
            cloudKitStatus = .temporarilyUnavailable
            logger.warning("iCloud account is temporarily unavailable")
        @unknown default:
            cloudKitStatus = .unknown
            logger.warning("Unknown iCloud account status")
        }
    }
    
    // MARK: - Context Management
    
    /// Create a new background context for data operations
    public func newBackgroundContext() -> NSManagedObjectContext {
        guard let container = persistentContainer else {
            fatalError("Persistent container not initialized.")
        }
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        return context
    }
    
    /// Perform operation on background context
    public func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            let context = newBackgroundContext()
            context.perform {
                do {
                    let result = try block(context)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Save context with proper error handling
    public func save(context: NSManagedObjectContext? = nil) throws {
        let contextToSave = context ?? viewContext
        
        guard contextToSave.hasChanges else {
            logger.debug("No changes to save in context")
            return
        }
        
        do {
            try contextToSave.save()
            logger.debug("Successfully saved context")
            
            // Save parent context if needed
            if let parentContext = contextToSave.parent, parentContext.hasChanges {
                try parentContext.save()
                logger.debug("Successfully saved parent context")
            }
        } catch {
            logger.error("Failed to save context: \(error.localizedDescription)")
            throw CoreDataError.saveFailed(error)
        }
    }
    
    /// Save all contexts
    public func saveAll() throws {
        // Save private context first
        if privateContext.hasChanges {
            try save(context: privateContext)
        }
        
        // Save view context
        if viewContext.hasChanges {
            try save(context: viewContext)
        }
        
        // Save background context
        if backgroundContext.hasChanges {
            try save(context: backgroundContext)
        }
    }
    
    // MARK: - Batch Operations
    
    /// Perform batch insert operation
    public func batchInsert<T: NSManagedObject>(_ objects: [T], in context: NSManagedObjectContext? = nil) throws {
        let contextToUse = context ?? backgroundContext
        
        contextToUse.performAndWait {
            for object in objects {
                contextToUse.insert(object)
            }
            
            do {
                try self.save(context: contextToUse)
                self.logger.info("Successfully batch inserted \(objects.count) objects")
            } catch {
                self.logger.error("Batch insert failed: \(error.localizedDescription)")
            }
        }
    }
    
    /// Perform batch update operation
    public func batchUpdate<T: NSManagedObject>(
        entityType: T.Type,
        predicate: NSPredicate? = nil,
        propertyValues: [String: Any]
    ) throws {
        let entityName = String(describing: entityType)
        let batchUpdateRequest = NSBatchUpdateRequest(entityName: entityName)
        batchUpdateRequest.predicate = predicate
        batchUpdateRequest.propertiesToUpdate = propertyValues
        batchUpdateRequest.resultType = .updatedObjectsCountResultType
        
        do {
            let result = try viewContext.execute(batchUpdateRequest) as? NSBatchUpdateResult
            guard let count = result?.result as? Int else { throw CoreDataError.batchOperationFailed(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get updated objects count"])) }
            logger.info("Batch updated \(count) \(entityName) objects")
        } catch {
            logger.error("Batch update failed: \(error.localizedDescription)")
            throw CoreDataError.batchOperationFailed(error)
        }
    }
    
    /// Perform batch delete operation
    public func batchDelete<T: NSManagedObject>(
        entityType: T.Type,
        predicate: NSPredicate? = nil
    ) throws {
        let entityName = String(describing: entityType)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = predicate
        
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeCount
        
        do {
            let result = try viewContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
            guard let count = result?.result as? Int else { throw CoreDataError.batchOperationFailed(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get deleted objects count"])) }
            logger.info("Batch deleted \(count) \(entityName) objects")
        } catch {
            logger.error("Batch delete failed: \(error.localizedDescription)")
            throw CoreDataError.batchOperationFailed(error)
        }
    }
    
    // MARK: - Migration Support
    
    /// Check if migration is needed
    public func migrationIsNeeded() -> Bool {
        guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url else {
            return false
        }
        
        do {
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                ofType: NSSQLiteStoreType,
                at: storeURL,
                options: nil
            )
            
            let model = persistentContainer.managedObjectModel
            return !model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        } catch {
            logger.error("Failed to check migration status: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Perform manual migration if needed
    public func performMigrationIfNeeded() throws {
        if migrationIsNeeded() {
            logger.info("Migration is required, performing migration...")
            // Migration logic would go here
            // This is a placeholder for custom migration logic
        }
    }
    
    // MARK: - CloudKit Sync Management
    
    /// Manually trigger CloudKit sync
    public func syncWithCloudKit() async {
        logger.info("Manually triggering CloudKit sync")
        
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            persistentContainer?.initializeCloudKitSchema { (_, error) in
                    if let error = error {
                        self.logger.error("CloudKit schema initialization failed: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    } else {
                        self.logger.info("CloudKit schema initialized successfully")
                        continuation.resume()
                    }
                }
            }
        } catch {
            syncError = error
            logger.error("CloudKit sync failed: \(error.localizedDescription)")
        }
    }
    
    /// Get sync status for specific record zones
    public func getSyncStatus() -> [String: Any] {
        var status: [String: Any] = [:]
        status["cloudKitStatus"] = cloudKitStatus.description
        status["lastSyncDate"] = lastSyncDate?.ISO8601Format() ?? "Never"
        status["syncProgress"] = syncProgress
        
        if let error = syncError {
            status["lastError"] = error.localizedDescription
        }
        
        return status
    }
    
    // MARK: - Performance Monitoring
    
    /// Get Core Data performance metrics
    public func getPerformanceMetrics() -> CoreDataMetrics {
        guard let persistentContainer = persistentContainer else {
            logger.error("Persistent container is nil. Cannot get performance metrics.")
            throw CoreDataError.contextNotAvailable
        }
        let context = viewContext
        let registeredObjectsCount = context.registeredObjects.count
        let insertedObjectsCount = context.insertedObjects.count
        let updatedObjectsCount = context.updatedObjects.count
        let deletedObjectsCount = context.deletedObjects.count
        
        return CoreDataMetrics(
            registeredObjects: registeredObjectsCount,
            insertedObjects: insertedObjectsCount,
            updatedObjects: updatedObjectsCount,
            deletedObjects: deletedObjectsCount,
            hasChanges: context.hasChanges,
            undoManagerEnabled: context.undoManager != nil
        )
    }
    
    /// Reset performance metrics
    public func resetPerformanceMetrics() {
        guard let persistentContainer = persistentContainer else {
            logger.error("Persistent container is nil. Cannot clear memory cache.")
            return
        }
        persistentContainer.viewContext.reset()
        backgroundContext.reset()
        logger.info("Performance metrics reset")
    }
    
    // MARK: - Memory Management
    
    /// Refresh all objects to reduce memory usage
    public func refreshAllObjects() {
        guard let persistentContainer = persistentContainer else {
            logger.error("Persistent container is nil. Cannot refresh all objects.")
            return
        }
        viewContext.refreshAllObjects()
        backgroundContext.refreshAllObjects()
        logger.info("Refreshed all objects to reduce memory usage")
    }
    
    /// Clear memory cache
    public func clearMemoryCache() {
        guard let persistentContainer = persistentContainer else {
            logger.error("Persistent container is nil. Cannot clear memory cache.")
            return
        }
        persistentContainer.viewContext.reset()
        logger.info("Memory cache cleared")
    }
    
    // MARK: - Error Handling
    
    private func handleStoreLoadingError(_ error: Error) {
        logger.error("Store loading error: \(error.localizedDescription)")
        
        // Attempt recovery strategies
        if let nsError = error as NSError? {
            switch nsError.code {
            case NSPersistentStoreIncompatibleVersionHashError,
                 NSMigrationMissingSourceModelError:
                // Handle migration errors
                handleMigrationError(nsError)
            case NSPersistentStoreIncompatibleSchemaError:
                // Handle schema errors
                handleSchemaError(nsError)
            default:
                // General error handling - delete and recreate store
                handleGenericStoreError(nsError)
            }
        }
    }
    
    private func handleMigrationError(_ error: NSError) {
        logger.warning("Migration error detected, attempting recovery")
        // Migration recovery logic would go here
    }
    
    private func handleSchemaError(_ error: NSError) {
        logger.warning("Schema error detected, attempting recovery")
        // Schema recovery logic would go here
    }
    
    private func handleGenericStoreError(_ error: NSError) {
        logger.error("Generic store error, considering store recreation")
        // Store recreation logic would go here (last resort)
    }
    
    // MARK: - Notification Handlers
    
    private func observeContextChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextDidChange(_:)),
            name: .NSManagedObjectContextDidSave,
            object: nil
        )
    }
    
    @objc private func contextDidChange(_ notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext,
              context !== viewContext else { return }
        
        viewContext.performAndWait {
            viewContext.mergeChanges(from: notification)
        }
    }
    
    @objc private func handleRemoteChange(_ notification: Notification) {
        logger.info("Handling remote change notification")
        
        DispatchQueue.main.async {
            self.viewContext.performAndWait {
                self.viewContext.mergeChanges(from: notification)
            }
        }
    }
    
    @objc private func handleCloudKitImportProgress(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event else {
            return
        }
        
        DispatchQueue.main.async {
            switch event.type {
            case .setup:
                self.logger.info("CloudKit setup event")
            case .import:
                self.logger.info("CloudKit import event")
                self.handleImportEvent(event)
            case .export:
                self.logger.info("CloudKit export event")
                self.handleExportEvent(event)
            @unknown default:
                self.logger.info("Unknown CloudKit event type")
            }
        }
    }
    
    private func handleImportEvent(_ event: NSPersistentCloudKitContainer.Event) {
        if event.succeeded {
            lastSyncDate = Date()
            syncError = nil
            logger.info("CloudKit import succeeded")
        } else if let error = event.error {
            syncError = error
            logger.error("CloudKit import failed: \(error.localizedDescription)")
        }
    }
    
    private func handleExportEvent(_ event: NSPersistentCloudKitContainer.Event) {
        if event.succeeded {
            lastSyncDate = Date()
            syncError = nil
            logger.info("CloudKit export succeeded")
        } else if let error = event.error {
            syncError = error
            logger.error("CloudKit export failed: \(error.localizedDescription)")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Supporting Types

public enum CloudKitStatus: CustomStringConvertible {
    case unknown
    case available
    case noAccount
    case restricted
    case temporarilyUnavailable
    case error(Error)
    
    public var description: String {
        switch self {
        case .unknown: return "Unknown"
        case .available: return "Available"
        case .noAccount: return "No Account"
        case .restricted: return "Restricted"
        case .temporarilyUnavailable: return "Temporarily Unavailable"
        case .error(let error): return "Error: \(error.localizedDescription)"
        }
    }
}

public struct CoreDataMetrics {
    let registeredObjects: Int
    let insertedObjects: Int
    let updatedObjects: Int
    let deletedObjects: Int
    let hasChanges: Bool
    let undoManagerEnabled: Bool
}

public enum CoreDataError: Error, LocalizedError {
    case saveFailed(Error)
    case batchOperationFailed(Error)
    case migrationFailed(Error)
    case contextNotAvailable
    
    public var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Save operation failed: \(error.localizedDescription)"
        case .batchOperationFailed(let error):
            return "Batch operation failed: \(error.localizedDescription)"
        case .migrationFailed(let error):
            return "Migration failed: \(error.localizedDescription)"
        case .contextNotAvailable:
            return "Managed object context is not available"
        }
    }
}
