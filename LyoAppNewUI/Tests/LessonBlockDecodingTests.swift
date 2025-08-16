import XCTest
@testable import LyoApp

final class LessonBlockDecodingTests: XCTestCase {

    func test_decodingHeadingBlock_isSuccessful() throws {
        // Given
        let json = """
        {
            "type": "heading",
            "text": "Welcome to SwiftUI"
        }
        """.data(using: .utf8)!

        // When
        let decodedBlock = try JSONDecoder().decode(LessonBlock.self, from: json)

        // Then
        guard case .heading(let text) = decodedBlock else {
            XCTFail("Decoded the wrong block type.")
            return
        }
        XCTAssertEqual(text, "Welcome to SwiftUI")
    }

    func test_decodingParagraphBlock_isSuccessful() throws {
        // Given
        let json = """
        {
            "type": "paragraph",
            "text": "This is a paragraph of text."
        }
        """.data(using: .utf8)!

        // When
        let decodedBlock = try JSONDecoder().decode(LessonBlock.self, from: json)

        // Then
        guard case .paragraph(let text) = decodedBlock else {
            XCTFail("Decoded the wrong block type.")
            return
        }
        XCTAssertEqual(text, "This is a paragraph of text.")
    }

    func test_decodingYouTubeBlock_isSuccessful() throws {
        // Given
        let json = """
        {
            "type": "youtubeVideo",
            "videoId": "dQw4w9WgXcQ"
        }
        """.data(using: .utf8)!

        // When
        let decodedBlock = try JSONDecoder().decode(LessonBlock.self, from: json)

        // Then
        guard case .youtubeVideo(let videoId) = decodedBlock else {
            XCTFail("Decoded the wrong block type.")
            return
        }
        XCTAssertEqual(videoId, "dQw4w9WgXcQ")
    }

    func test_decodingLinkBlock_isSuccessful() throws {
        // Given
        let json = """
        {
            "type": "link",
            "title": "Apple Developer",
            "url": "https://developer.apple.com"
        }
        """.data(using: .utf8)!

        // When
        let decodedBlock = try JSONDecoder().decode(LessonBlock.self, from: json)

        // Then
        guard case .link(let title, let url) = decodedBlock else {
            XCTFail("Decoded the wrong block type.")
            return
        }
        XCTAssertEqual(title, "Apple Developer")
        XCTAssertEqual(url.absoluteString, "https://developer.apple.com")
    }

    func test_decodingLessonWithBlocks_isSuccessful() throws {
        // Given
        let json = """
        {
            "id": "A4B4E6A5-9261-459E-9A5A-18392C112C16",
            "title": "My Lesson",
            "content": [
                { "type": "heading", "text": "First Heading" },
                { "type": "paragraph", "text": "Some text." }
            ]
        }
        """.data(using: .utf8)!

        // When
        let lesson = try JSONDecoder().decode(Lesson.self, from: json)

        // Then
        XCTAssertEqual(lesson.title, "My Lesson")
        XCTAssertEqual(lesson.contentBlocks.count, 2)
        XCTAssertEqual(lesson.contentBlocks[0], .heading("First Heading"))
        XCTAssertEqual(lesson.contentBlocks[1], .paragraph("Some text."))
    }

    func test_decoding_withInvalidType_throwsError() {
        // Given
        let json = """
        {
            "type": "invalid_type",
            "text": "some text"
        }
        """.data(using: .utf8)!

        // Then
        XCTAssertThrowsError(try JSONDecoder().decode(LessonBlock.self, from: json))
    }
}
