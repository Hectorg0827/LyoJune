import XCTest
@testable import LyoApp

// Note: To run these tests, you would need to open the `Package.swift` in Xcode
// and run the tests for the "Tests" target.

@MainActor
final class AuthViewModelTests: XCTestCase {

    private var sut: AuthViewModel!
    private var mockHTTPClient: MockHTTPClient!
    private var mockAuthService: MockAuthService!

    override func setUp() {
        super.setUp()
        mockHTTPClient = MockHTTPClient()
        mockAuthService = MockAuthService()
        sut = AuthViewModel(
            httpClient: mockHTTPClient,
            authService: mockAuthService
        )
    }

    override func tearDown() {
        sut = nil
        mockHTTPClient = nil
        mockAuthService = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_signInWithGoogle_onSuccess_callsSaveTokensAndStopsLoading() async {
        // Given
        let expectedResponse = AuthResponse(accessToken: "new_access_token", refreshToken: "new_refresh_token")
        mockHTTPClient.result = .success(expectedResponse)

        XCTAssertFalse(sut.isLoading, "Precondition: isLoading should be false.")

        // When
        let expectation = expectation(description: "isLoading should become true then false")

        // Observe changes to isLoading
        var loadingStates: [Bool] = []
        let cancellable = sut.$isLoading.sink { loadingStates.append($0) }

        sut.signInWithGoogle()

        // Then
        // A small delay to allow the async task in the ViewModel to execute.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Assertions
            XCTAssertEqual(loadingStates, [false, true, false], "isLoading should cycle through true and back to false.")
            XCTAssertEqual(self.mockAuthService.saveTokensCallCount, 1, "saveTokens should be called exactly once.")
            XCTAssertEqual(self.mockAuthService.savedAccessToken, expectedResponse.accessToken)
            XCTAssertEqual(self.mockAuthService.savedRefreshToken, expectedResponse.refreshToken)
            XCTAssertNil(self.sut.errorToast, "errorToast should be nil on success.")

            cancellable.cancel()
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func test_signInWithGoogle_onHttpError_setsErrorToast() async {
        // Given
        let expectedError = APIError.serverError(message: "Internal Server Error")
        mockHTTPClient.result = .failure(expectedError)

        // When
        let expectation = expectation(description: "errorToast should be set")

        sut.signInWithGoogle()

        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.mockAuthService.saveTokensCallCount, 0, "saveTokens should not be called on failure.")
            XCTAssertNotNil(self.sut.errorToast, "errorToast should be set on failure.")
            XCTAssertEqual(self.sut.errorToast?.style, .error)
            XCTAssertEqual(self.sut.errorToast?.message, "Authentication failed: \(expectedError.localizedDescription)")

            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // This test doesn't need to be async as the Apple Sign-In handler is synchronous.
    func test_handleAppleSignIn_onCredentialFailure_setsErrorToast() {
        // Given
        let authError = NSError(domain: ASAuthorizationError.errorDomain, code: ASAuthorizationError.Code.failed.rawValue)
        let result: Result<ASAuthorization, Error> = .failure(authError)

        // When
        sut.handleAppleSignIn(result: result)

        // Then
        XCTAssertNotNil(sut.errorToast)
        XCTAssertEqual(sut.errorToast?.style, .error)
    }
}
