import XCTest
@testable import LyoApp

@MainActor
final class ProfileViewModelTests: XCTestCase {

    private var sut: ProfileViewModel!
    private var mockService: MockProfileAndSettingsService!
    private let testUserId = UUID()

    override func setUp() {
        super.setUp()
        mockService = MockProfileAndSettingsService()
        sut = ProfileViewModel(userId: testUserId, profileService: mockService)
    }

    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_fetchProfile_onSuccess_updatesStateToLoaded() async {
        // Given
        let profile = UserProfile.placeholder(id: testUserId, isCurrentUser: true)
        mockService.profileResult = .success(profile)

        // When
        sut.fetchProfile()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockService.getProfileCallCount, 1)
        XCTAssertEqual(sut.viewState, .loaded)
        XCTAssertEqual(sut.userProfile, profile)
    }

    func test_fetchProfile_onFailure_updatesStateToError() async {
        // Given
        mockService.profileResult = .failure(.unauthorized)

        // When
        sut.fetchProfile()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockService.getProfileCallCount, 1)
        XCTAssertEqual(sut.viewState, .error)
        XCTAssertNil(sut.userProfile)
    }

    func test_toggleFollow_whenNotFollowing_callsFollowUser() async {
        // Given
        let profile = UserProfile.placeholder(id: testUserId, isFollowedByCurrentUser: false)
        sut.userProfile = profile

        // When
        sut.toggleFollow()

        // Then (Optimistic UI)
        XCTAssertTrue(sut.userProfile?.isFollowedByCurrentUser ?? false)

        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(mockService.followUserCallCount, 1)
        XCTAssertEqual(mockService.unfollowUserCallCount, 0)
    }

    func test_toggleFollow_whenFollowing_callsUnfollowUser() async {
        // Given
        let profile = UserProfile.placeholder(id: testUserId, isFollowedByCurrentUser: true)
        sut.userProfile = profile

        // When
        sut.toggleFollow()

        // Then (Optimistic UI)
        XCTAssertFalse(sut.userProfile?.isFollowedByCurrentUser ?? true)

        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(mockService.unfollowUserCallCount, 1)
        XCTAssertEqual(mockService.followUserCallCount, 0)
    }

    func test_toggleFollow_onFailure_revertsOptimisticUpdate() async {
        // Given
        let profile = UserProfile.placeholder(id: testUserId, isFollowedByCurrentUser: false)
        sut.userProfile = profile
        mockService.followError = .serverError(message: "Failed")

        // When
        sut.toggleFollow()

        // Then (Optimistic UI)
        XCTAssertTrue(sut.userProfile?.isFollowedByCurrentUser ?? false)

        try? await Task.sleep(nanoseconds: 100_000_000)

        // After failure, it should revert
        XCTAssertFalse(sut.userProfile?.isFollowedByCurrentUser ?? true)
    }
}

extension UserProfile {
    static func placeholder(id: UUID, isCurrentUser: Bool = false, isFollowedByCurrentUser: Bool = false) -> UserProfile {
        .init(id: id, username: "test", profileImageURL: nil, bio: nil, followerCount: 0, followingCount: 0, isCurrentUser: isCurrentUser, isFollowedByCurrentUser: isFollowedByCurrentUser)
    }
}
