import XCTest
@testable import LyoApp

final class OnDeviceAIServiceTests: XCTestCase {

    func test_initializer_whenModelFilesAreMissing_returnsNil() {
        // GIVEN: An environment where the `gemma_2b.mlpackage` and `tokenizer.json`
        // have not been added to the test bundle.

        // WHEN: We attempt to initialize the service.
        let service = OnDeviceAIService()

        // THEN: The initializer should fail and return nil.
        XCTAssertNil(service, "The OnDeviceAIService should fail to initialize if the model and tokenizer files are not present in the bundle.")
    }
}
