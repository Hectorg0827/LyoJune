import Foundation
import CoreData
import Combine

/// Core Data Manager for offline data persistence in Phase 3
class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "LyoAppDataModel")
        
        // Configure persistent store
        let storeDescription = container.persistentStoreDescriptions.first
        storeDescription?.shouldInferMappingModelAutomatically = true
        storeDescription?.shouldMigrateStoreAutomatically = true
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { [weak self] storeDescription, error in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                print("❌ Core Data error: \(error), \(error.userInfo)")
            } else {
                print("✅ Core Data store loaded successfully")
                self?.setupRemoteChangeNotifications()
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private init() {
        loadLastSyncDate()
        setupNetworkMonitoring()
    }
    
    // MARK: - Core Data Operations
    
    func save() {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("❌ Failed to save Core Data context: \(error)")
        }
    }
    
    func saveWithCompletion(_ completion: @escaping (Bool) -> Void) {
        guard context.hasChanges else {
            completion(true)
            return
        }
        
        do {
            try context.save()
            completion(true)
        } catch {
            print("❌ Failed to save Core Data context: \(error)")
            completion(false)
        }
    }
    
    func performBackgroundTask<T>(_ task: @escaping (NSManagedObjectContext) -> T) -> Future<T, CoreDataError> {
        return Future<T, CoreDataError> { promise in
            self.persistentContainer.performBackgroundTask { context in
                let result = task(context)
                
                if context.hasChanges {
                    do {
                        try context.save()
                        promise(.success(result))
                    } catch {
                        promise(.failure(.saveFailed(error)))
                    }
                } else {
                    promise(.success(result))
                }
            }
        }
    }
    
    // MARK: - Course Management
    
    func saveCourse(_ course: CourseModel) -> Future<Void, CoreDataError> {
        return performBackgroundTask { context in
            let cdCourse = self.findOrCreateCourse(course.id, in: context)
            self.updateCourseEntity(cdCourse, with: course)
        }
    }
    
    func saveCourses(_ courses: [CourseModel]) -> Future<Void, CoreDataError> {
        return performBackgroundTask { context in
            for course in courses {
                let cdCourse = self.findOrCreateCourse(course.id, in: context)
                self.updateCourseEntity(cdCourse, with: course)
            }
        }
    }
    
    func getCourse(by id: String) -> CDCourse? {
        let request: NSFetchRequest<CDCourse> = CDCourse.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
    
    func getCourses(
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor] = []
    ) -> [CDCourse] {
        let request: NSFetchRequest<CDCourse> = CDCourse.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        
        return (try? context.fetch(request)) ?? []
    }
    
    func getOfflineCourses() -> [CDCourse] {
        let predicate = NSPredicate(format: "isDownloadedForOffline == YES")
        return getCourses(predicate: predicate)
    }
    
    // MARK: - User Progress Management
    
    func saveUserProgress(_ progress: UserProgress) -> Future<Void, CoreDataError> {
        return performBackgroundTask { context in
            let cdProgress = self.findOrCreateUserProgress(in: context)
            self.updateUserProgressEntity(cdProgress, with: progress)
        }
    }
    
    func getUserProgress() -> CDUserProgress? {
        let request: NSFetchRequest<CDUserProgress> = CDUserProgress.fetchRequest()
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
    
    func saveLessonProgress(_ progress: LessonProgress, courseId: String, lessonId: String) -> Future<Void, CoreDataError> {
        return performBackgroundTask { context in
            let cdProgress = self.findOrCreateLessonProgress(courseId: courseId, lessonId: lessonId, in: context)
            self.updateLessonProgressEntity(cdProgress, with: progress)
        }
    }
    
    func getLessonProgress(courseId: String, lessonId: String) -> CDLessonProgress? {
        let request: NSFetchRequest<CDLessonProgress> = CDLessonProgress.fetchRequest()
        request.predicate = NSPredicate(format: "courseId == %@ AND lessonId == %@", courseId, lessonId)
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
    
    // MARK: - Feed Post Management
    
    func saveFeedPost(_ post: FeedPost) -> Future<Void, CoreDataError> {
        return performBackgroundTask { context in
            let cdPost = self.findOrCreateFeedPost(post.id, in: context)
            self.updateFeedPostEntity(cdPost, with: post)
        }
    }
    
    func saveFeedPosts(_ posts: [FeedPost]) -> Future<Void, CoreDataError> {
        return performBackgroundTask { context in
            for post in posts {
                let cdPost = self.findOrCreateFeedPost(post.id, in: context)
                self.updateFeedPostEntity(cdPost, with: post)
            }
        }
    }
    
    func getFeedPosts(limit: Int = 20, offset: Int = 0) -> [CDFeedPost] {
        let request: NSFetchRequest<CDFeedPost> = CDFeedPost.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDFeedPost.createdAt, ascending: false)]
        request.fetchLimit = limit
        request.fetchOffset = offset
        
        return (try? context.fetch(request)) ?? []
    }
    
    // MARK: - User Profile Management
    
    func saveUserProfile(_ profile: UserProfile) -> Future<Void, CoreDataError> {
        return performBackgroundTask { context in
            let cdProfile = self.findOrCreateUserProfile(profile.id, in: context)
            self.updateUserProfileEntity(cdProfile, with: profile)
        }
    }
    
    func getUserProfile(id: String) -> CDUserProfile? {
        let request: NSFetchRequest<CDUserProfile> = CDUserProfile.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
    
    // MARK: - Offline Content Management
    
    func markCourseForOfflineDownload(_ courseId: String) -> Future<Void, CoreDataError> {
        return performBackgroundTask { context in
            if let course = self.findOrCreateCourse(courseId, in: context) {
                course.isDownloadedForOffline = true
                course.downloadedAt = Date()
            }
        }
    }
    
    func removeCourseFromOfflineDownload(_ courseId: String) -> Future<Void, CoreDataError> {
        return performBackgroundTask { context in
            if let course = self.findOrCreateCourse(courseId, in: context) {
                course.isDownloadedForOffline = false
                course.downloadedAt = nil
            }
        }
    }
    
    func getOfflineDownloadSize() -> Int64 {
        let courses = getOfflineCourses()
        return courses.reduce(0) { $0 + $1.downloadSize }
    }
    
    // MARK: - Sync Management
    
    func needsSync() -> Bool {
        guard let lastSync = lastSyncDate else { return true }
        let timeSinceLastSync = Date().timeIntervalSince(lastSync)
        return timeSinceLastSync > 300 // 5 minutes
    }
    
    func markSyncCompleted() {
        lastSyncDate = Date()
        UserDefaults.standard.set(lastSyncDate, forKey: "last_sync_date")
    }
    
    func getPendingSyncItems() -> [CDSyncItem] {
        let request: NSFetchRequest<CDSyncItem> = CDSyncItem.fetchRequest()
        request.predicate = NSPredicate(format: "isSynced == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDSyncItem.createdAt, ascending: true)]
        
        return (try? context.fetch(request)) ?? []
    }
    
    func createSyncItem(type: SyncItemType, entityId: String, data: Data) -> Future<Void, CoreDataError> {
        return performBackgroundTask { context in
            let syncItem = CDSyncItem(context: context)
            syncItem.id = UUID().uuidString
            syncItem.type = type.rawValue
            syncItem.entityId = entityId
            syncItem.data = data
            syncItem.createdAt = Date()
            syncItem.isSynced = false
        }
    }
    
    func markSyncItemAsCompleted(_ syncItemId: String) -> Future<Void, CoreDataError> {
        return performBackgroundTask { context in
            let request: NSFetchRequest<CDSyncItem> = CDSyncItem.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", syncItemId)
            
            if let syncItem = try? context.fetch(request).first {
                syncItem.isSynced = true
                syncItem.syncedAt = Date()
            }
        }
    }
    
    // MARK: - Data Cleanup
    
    func cleanupOldData() -> Future<Void, CoreDataError> {
        return performBackgroundTask { context in
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            
            // Clean up old feed posts
            let feedPostRequest: NSFetchRequest<CDFeedPost> = CDFeedPost.fetchRequest()
            feedPostRequest.predicate = NSPredicate(format: "createdAt < %@", cutoffDate as NSDate)
            
            if let oldPosts = try? context.fetch(feedPostRequest) {
                for post in oldPosts {
                    context.delete(post)
                }
            }
            
            // Clean up completed sync items
            let syncItemRequest: NSFetchRequest<CDSyncItem> = CDSyncItem.fetchRequest()
            syncItemRequest.predicate = NSPredicate(format: "isSynced == YES AND syncedAt < %@", cutoffDate as NSDate)
            
            if let completedSyncItems = try? context.fetch(syncItemRequest) {
                for item in completedSyncItems {
                    context.delete(item)
                }
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func findOrCreateCourse(_ id: String, in context: NSManagedObjectContext) -> CDCourse {
        let request: NSFetchRequest<CDCourse> = CDCourse.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        if let existingCourse = try? context.fetch(request).first {
            return existingCourse
        } else {
            let newCourse = CDCourse(context: context)
            newCourse.id = id
            return newCourse
        }
    }
    
    private func updateCourseEntity(_ entity: CDCourse, with course: CourseModel) {
        entity.title = course.title
        entity.courseDescription = course.description
        entity.category = course.category
        entity.difficultyLevel = course.difficultyLevel
        entity.duration = Int32(course.estimatedDuration)
        entity.rating = course.rating
        entity.enrollmentCount = Int32(course.enrollmentCount)
        entity.thumbnailURL = course.thumbnailURL
        entity.instructorId = course.instructorId
        entity.price = course.price ?? 0.0
        entity.isFree = course.isFree
        entity.updatedAt = Date()
    }
    
    private func findOrCreateUserProgress(in context: NSManagedObjectContext) -> CDUserProgress {
        let request: NSFetchRequest<CDUserProgress> = CDUserProgress.fetchRequest()
        request.fetchLimit = 1
        
        if let existingProgress = try? context.fetch(request).first {
            return existingProgress
        } else {
            return CDUserProgress(context: context)
        }
    }
    
    private func updateUserProgressEntity(_ entity: CDUserProgress, with progress: UserProgress) {
        entity.overallProgress = progress.overallProgress
        entity.completedCourses = Int32(progress.completedCourses)
        entity.inProgressCourses = Int32(progress.inProgressCourses)
        entity.totalLearningHours = Int32(progress.totalLearningHours)
        entity.currentStreak = Int32(progress.currentStreak)
        entity.longestStreak = Int32(progress.longestStreak)
        entity.updatedAt = Date()
    }
    
    private func findOrCreateLessonProgress(courseId: String, lessonId: String, in context: NSManagedObjectContext) -> CDLessonProgress {
        let request: NSFetchRequest<CDLessonProgress> = CDLessonProgress.fetchRequest()
        request.predicate = NSPredicate(format: "courseId == %@ AND lessonId == %@", courseId, lessonId)
        request.fetchLimit = 1
        
        if let existingProgress = try? context.fetch(request).first {
            return existingProgress
        } else {
            let newProgress = CDLessonProgress(context: context)
            newProgress.courseId = courseId
            newProgress.lessonId = lessonId
            return newProgress
        }
    }
    
    private func updateLessonProgressEntity(_ entity: CDLessonProgress, with progress: LessonProgress) {
        entity.percentage = progress.percentage
        entity.timeSpent = progress.timeSpent
        entity.completed = progress.completed
        entity.lastAccessed = progress.lastAccessed
        entity.updatedAt = Date()
    }
    
    private func findOrCreateFeedPost(_ id: String, in context: NSManagedObjectContext) -> CDFeedPost {
        let request: NSFetchRequest<CDFeedPost> = CDFeedPost.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        if let existingPost = try? context.fetch(request).first {
            return existingPost
        } else {
            let newPost = CDFeedPost(context: context)
            newPost.id = id
            return newPost
        }
    }
    
    private func updateFeedPostEntity(_ entity: CDFeedPost, with post: FeedPost) {
        entity.content = post.content
        entity.authorId = post.authorId
        entity.authorName = post.authorName
        entity.authorAvatarURL = post.authorAvatarURL
        entity.createdAt = post.createdAt
        entity.likeCount = Int32(post.likeCount)
        entity.commentCount = Int32(post.commentCount)
        entity.isLikedByCurrentUser = post.isLikedByCurrentUser
        entity.mediaURLs = post.mediaURLs?.joined(separator: ",")
        entity.courseId = post.courseId
        entity.updatedAt = Date()
    }
    
    private func findOrCreateUserProfile(_ id: String, in context: NSManagedObjectContext) -> CDUserProfile {
        let request: NSFetchRequest<CDUserProfile> = CDUserProfile.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        if let existingProfile = try? context.fetch(request).first {
            return existingProfile
        } else {
            let newProfile = CDUserProfile(context: context)
            newProfile.id = id
            return newProfile
        }
    }
    
    private func updateUserProfileEntity(_ entity: CDUserProfile, with profile: UserProfile) {
        entity.email = profile.email
        entity.fullName = profile.fullName
        entity.username = profile.username
        entity.avatarURL = profile.avatarUrl
        entity.bio = profile.bio
        entity.location = profile.location
        entity.website = profile.website
        entity.createdAt = profile.createdAt
        entity.updatedAt = Date()
    }
    
    private func loadLastSyncDate() {
        lastSyncDate = UserDefaults.standard.object(forKey: "last_sync_date") as? Date
    }
    
    private func setupNetworkMonitoring() {
        EnhancedNetworkManager.shared.$isOnline
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isOnline in
                if isOnline && self?.needsSync() == true {
                    // Schedule sync when network comes back online
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        Task {
                            await self?.performBackgroundSync()
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupRemoteChangeNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(managedObjectContextDidSave),
            name: .NSManagedObjectContextDidSave,
            object: nil
        )
    }
    
    @objc private func managedObjectContextDidSave(notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext,
              context !== self.context else { return }
        
        DispatchQueue.main.async {
            self.context.mergeChanges(fromContextDidSave: notification)
        }
    }
    
    // MARK: - Background Sync
    
    func performBackgroundSync() async {
        guard !isSyncing else { return }
        
        await MainActor.run {
            isSyncing = true
        }
        
        defer {
            Task { @MainActor in
                isSyncing = false
            }
        }
        
        // Process pending sync items
        let pendingItems = getPendingSyncItems()
        
        for item in pendingItems {
            await processSyncItem(item)
        }
        
        await MainActor.run {
            markSyncCompleted()
        }
    }
    
    private func processSyncItem(_ item: CDSyncItem) async {
        guard let type = SyncItemType(rawValue: item.type ?? "") else { return }
        
        switch type {
        case .lessonProgress:
            await syncLessonProgress(item)
        case .userProfile:
            await syncUserProfile(item)
        case .feedPost:
            await syncFeedPost(item)
        }
    }
    
    private func syncLessonProgress(_ item: CDSyncItem) async {
        // Implementation would sync lesson progress with backend
        // For now, mark as completed
        _ = await markSyncItemAsCompleted(item.id ?? "")
    }
    
    private func syncUserProfile(_ item: CDSyncItem) async {
        // Implementation would sync user profile with backend
        // For now, mark as completed
        _ = await markSyncItemAsCompleted(item.id ?? "")
    }
    
    private func syncFeedPost(_ item: CDSyncItem) async {
        // Implementation would sync feed post with backend
        // For now, mark as completed
        _ = await markSyncItemAsCompleted(item.id ?? "")
    }
}

// MARK: - Supporting Types

enum CoreDataError: LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .unknown:
            return "An unknown Core Data error occurred"
        }
    }
}

enum SyncItemType: String, CaseIterable {
    case lessonProgress = "lesson_progress"
    case userProfile = "user_profile"
    case feedPost = "feed_post"
}
