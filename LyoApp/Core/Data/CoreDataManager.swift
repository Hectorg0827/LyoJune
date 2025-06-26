import Foundation
import CoreData
import Combine

// MARK: - Core Data Manager
final class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    @Published var isReady: Bool = false
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "LyoDataModel")
        
        container.loadPersistentStores { [weak self] _, error in
            if let error = error as NSError? {
                print("❌ Core Data error: \(error), \(error.userInfo)")
            } else {
                print("✅ Core Data loaded successfully")
                DispatchQueue.main.async {
                    self?.isReady = true
                }
            }
        }
        
        // Configure automatic merging
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private init() {}
    
    // MARK: - Core Data Operations
    
    func save() {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
            print("✅ Core Data saved successfully")
        } catch {
            print("❌ Core Data save error: \(error)")
        }
    }
    
    func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) -> [T] {
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Core Data fetch error: \(error)")
            return []
        }
    }
    
    func delete(_ object: NSManagedObject) {
        context.delete(object)
        save()
    }
    
    func deleteAll<T: NSManagedObject>(_ type: T.Type) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: type))
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest)
            save()
            print("✅ Deleted all \(type) objects")
        } catch {
            print("❌ Delete all error: \(error)")
        }
    }
    
    // MARK: - User Management
    
    func saveUser(_ user: User) {
        // Delete existing user first
        deleteAll(CachedUser.self)
        
        let cachedUser = CachedUser(context: context)
        cachedUser.id = user.id
        cachedUser.email = user.email
        cachedUser.name = user.name
        cachedUser.avatar = user.avatar
        cachedUser.createdAt = user.createdAt
        cachedUser.updatedAt = user.updatedAt
        cachedUser.isVerified = user.isVerified
        
        // Convert badges array to Data
        if let badges = user.stats?.badges {
            cachedUser.badges = try? NSKeyedArchiver.archivedData(withRootObject: badges, requiringSecureCoding: true)
        }
        
        save()
    }
    
    func fetchUser() -> User? {
        let request: NSFetchRequest<CachedUser> = CachedUser.fetchRequest()
        request.fetchLimit = 1
        
        guard let cachedUser = fetch(request).first else { return nil }
        
        // Convert badges back from Data
        var badges: [String] = []
        if let badgesData = cachedUser.badges {
            badges = (try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(badgesData) as? [String]) ?? []
        }
        
        let stats = UserStats(
            totalCourses: Int(cachedUser.totalCourses),
            completedCourses: Int(cachedUser.completedCourses),
            totalPoints: Int(cachedUser.totalPoints),
            currentStreak: Int(cachedUser.currentStreak),
            longestStreak: Int(cachedUser.longestStreak),
            level: Int(cachedUser.level),
            badges: badges,
            totalStudyTime: cachedUser.totalStudyTime
        )
        
        let preferences = UserPreferences(
            notifications: cachedUser.notifications,
            darkMode: cachedUser.darkMode,
            language: cachedUser.language ?? "en",
            biometricAuth: cachedUser.biometricAuth,
            pushNotifications: cachedUser.pushNotifications,
            emailNotifications: cachedUser.emailNotifications
        )
        
        return User(
            id: cachedUser.id ?? "",
            email: cachedUser.email ?? "",
            name: cachedUser.name ?? "",
            avatar: cachedUser.avatar,
            createdAt: cachedUser.createdAt ?? Date(),
            updatedAt: cachedUser.updatedAt ?? Date(),
            isVerified: cachedUser.isVerified,
            preferences: preferences,
            stats: stats,
            role: UserRole(rawValue: cachedUser.role ?? "student") ?? .student,
            status: UserStatus(rawValue: cachedUser.status ?? "active") ?? .active
        )
    }
    
    // MARK: - Course Management
    
    func saveCourse(_ course: Course) {
        let request: NSFetchRequest<CachedCourse> = CachedCourse.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", course.id)
        
        let cachedCourse: CachedCourse
        if let existing = fetch(request).first {
            cachedCourse = existing
        } else {
            cachedCourse = CachedCourse(context: context)
        }
        
        cachedCourse.id = course.id
        cachedCourse.title = course.title
        cachedCourse.courseDescription = course.description
        cachedCourse.duration = course.duration
        cachedCourse.difficulty = course.difficulty.rawValue
        cachedCourse.category = course.category.rawValue
        cachedCourse.imageURL = course.imageURL
        cachedCourse.createdAt = course.createdAt
        cachedCourse.updatedAt = course.updatedAt
        cachedCourse.isPublished = course.isPublished
        cachedCourse.price = course.price
        cachedCourse.currency = course.currency
        cachedCourse.enrollmentCount = Int32(course.enrollmentCount)
        cachedCourse.rating = course.rating
        cachedCourse.reviewCount = Int32(course.reviewCount)
        
        // Convert tags array to Data
        if !course.tags.isEmpty {
            cachedCourse.tags = try? NSKeyedArchiver.archivedData(withRootObject: course.tags, requiringSecureCoding: true)
        }
        
        save()
    }
    
    func fetchCourses() -> [Course] {
        let request: NSFetchRequest<CachedCourse> = CachedCourse.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        return fetch(request).compactMap { cachedCourse in
            // Convert tags back from Data
            var tags: [String] = []
            if let tagsData = cachedCourse.tags {
                tags = (try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(tagsData) as? [String]) ?? []
            }
            
            let instructor = Instructor(
                id: "instructor_\(cachedCourse.id ?? "")",
                name: "Instructor",
                bio: nil,
                avatar: nil,
                expertise: [],
                rating: 0.0,
                totalCourses: 0,
                totalStudents: 0
            )
            
            return Course(
                id: cachedCourse.id ?? "",
                title: cachedCourse.title ?? "",
                description: cachedCourse.courseDescription ?? "",
                instructor: instructor,
                duration: cachedCourse.duration,
                difficulty: CourseDifficulty(rawValue: cachedCourse.difficulty ?? "beginner") ?? .beginner,
                category: CourseCategory(rawValue: cachedCourse.category ?? "other") ?? .other,
                imageURL: cachedCourse.imageURL,
                lessons: [],
                tags: tags,
                createdAt: cachedCourse.createdAt ?? Date(),
                updatedAt: cachedCourse.updatedAt ?? Date(),
                isPublished: cachedCourse.isPublished,
                price: cachedCourse.price,
                currency: cachedCourse.currency ?? "USD",
                enrollmentCount: Int(cachedCourse.enrollmentCount),
                rating: cachedCourse.rating,
                reviewCount: Int(cachedCourse.reviewCount)
            )
        }
    }
    
    // MARK: - Post Management
    
    func savePost(_ post: Post) {
        let request: NSFetchRequest<CachedPost> = CachedPost.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", post.id)
        
        let cachedPost: CachedPost
        if let existing = fetch(request).first {
            cachedPost = existing
        } else {
            cachedPost = CachedPost(context: context)
        }
        
        cachedPost.id = post.id
        cachedPost.authorId = post.authorId
        cachedPost.authorName = post.authorName
        cachedPost.authorAvatar = post.authorAvatar
        cachedPost.content = post.content
        cachedPost.imageURL = post.imageURL
        cachedPost.videoURL = post.videoURL
        cachedPost.likes = Int32(post.likes)
        cachedPost.comments = Int32(post.comments)
        cachedPost.shares = Int32(post.shares)
        cachedPost.isLiked = post.isLiked
        cachedPost.isBookmarked = post.isBookmarked
        cachedPost.createdAt = post.createdAt
        cachedPost.updatedAt = post.updatedAt
        cachedPost.category = post.category.rawValue
        cachedPost.visibility = post.visibility.rawValue
        
        save()
    }
    
    func fetchPosts() -> [Post] {
        let request: NSFetchRequest<CachedPost> = CachedPost.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        return fetch(request).compactMap { cachedPost in
            Post(
                id: cachedPost.id ?? "",
                authorId: cachedPost.authorId ?? "",
                authorName: cachedPost.authorName ?? "",
                authorAvatar: cachedPost.authorAvatar,
                content: cachedPost.content ?? "",
                imageURL: cachedPost.imageURL,
                videoURL: cachedPost.videoURL,
                likes: Int(cachedPost.likes),
                comments: Int(cachedPost.comments),
                shares: Int(cachedPost.shares),
                isLiked: cachedPost.isLiked,
                isBookmarked: cachedPost.isBookmarked,
                createdAt: cachedPost.createdAt ?? Date(),
                updatedAt: cachedPost.updatedAt ?? Date(),
                tags: [],
                category: PostCategory(rawValue: cachedPost.category ?? "general") ?? .general,
                visibility: PostVisibility(rawValue: cachedPost.visibility ?? "public") ?? .public
            )
        }
    }
    
    // MARK: - Clear Cache
    
    func clearCache() {
        deleteAll(CachedUser.self)
        deleteAll(CachedCourse.self)
        deleteAll(CachedPost.self)
        print("✅ Cache cleared")
    }
}
