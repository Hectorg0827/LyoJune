import SwiftUI
import Combine

@MainActor
class TestViewModel: ObservableObject {
    @Published var test: String = "hello"
    
    init() {
        // test
    }
}