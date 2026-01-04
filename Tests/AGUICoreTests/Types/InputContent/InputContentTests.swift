// InputContentTests.swift
// AGUISwift

import XCTest
@testable import AGUICore

/// Tests for the InputContent protocol and TextInputContent type
final class InputContentTests: XCTestCase {
    // MARK: - TextInputContent Initialization Tests

    func testTextInputContentInit() {
        let content = TextInputContent(text: "Hello, world!")

        XCTAssertEqual(content.text, "Hello, world!")
        XCTAssertEqual(content.type, "text")
    }

    func testTextInputContentWithEmptyString() {
        let content = TextInputContent(text: "")

        XCTAssertEqual(content.text, "")
        XCTAssertEqual(content.type, "text")
    }

    func testTextInputContentWithMultilineText() {
        let multilineText = """
        This is line 1
        This is line 2
        This is line 3
        """

        let content = TextInputContent(text: multilineText)

        XCTAssertTrue(content.text.contains("line 1"))
        XCTAssertTrue(content.text.contains("line 2"))
    }

    // MARK: - TextInputContent Encoding Tests

    func testTextInputContentEncoding() throws {
        let content = TextInputContent(text: "Test message")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let encoded = try encoder.encode(content)
        let json = String(data: encoded, encoding: .utf8)

        XCTAssertNotNil(json)
        XCTAssertTrue(json?.contains("\"type\"") ?? false)
        XCTAssertTrue(json?.contains("\"text\"") ?? false)
        XCTAssertTrue(json?.contains("\"Test message\"") ?? false)
    }

    func testTextInputContentEncodedStructure() throws {
        let content = TextInputContent(text: "Sample text")

        let encoded = try JSONEncoder().encode(content)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]

        XCTAssertEqual(json?["type"] as? String, "text")
        XCTAssertEqual(json?["text"] as? String, "Sample text")
    }

    // MARK: - TextInputContent Decoding Tests

    func testTextInputContentDecoding() throws {
        let json = """
        {
            "type": "text",
            "text": "Hello from JSON"
        }
        """

        let decoder = JSONDecoder()
        let content = try decoder.decode(TextInputContent.self, from: Data(json.utf8))

        XCTAssertEqual(content.type, "text")
        XCTAssertEqual(content.text, "Hello from JSON")
    }

    func testTextInputContentDecodingWithoutType() throws {
        // Type should default to "text" if not present
        let json = """
        {
            "text": "Text without explicit type"
        }
        """

        let decoder = JSONDecoder()
        let content = try decoder.decode(TextInputContent.self, from: Data(json.utf8))

        XCTAssertEqual(content.type, "text")
        XCTAssertEqual(content.text, "Text without explicit type")
    }

    func testTextInputContentDecodingFailsWithoutText() {
        let json = """
        {
            "type": "text"
        }
        """

        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(TextInputContent.self, from: Data(json.utf8))) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    // MARK: - TextInputContent Round-trip Tests

    func testTextInputContentRoundTrip() throws {
        let original = TextInputContent(text: "Round-trip test message")

        let encoder = JSONEncoder()
        let encoded = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TextInputContent.self, from: encoded)

        XCTAssertEqual(decoded.type, original.type)
        XCTAssertEqual(decoded.text, original.text)
    }

    // MARK: - InputContent Protocol Conformance Tests

    func testTextInputContentConformsToInputContent() {
        let content: any InputContent = TextInputContent(text: "Protocol test")

        XCTAssertEqual(content.type, "text")
    }

    func testInputContentArrayWithTextContent() {
        let contents: [any InputContent] = [
            TextInputContent(text: "First message"),
            TextInputContent(text: "Second message"),
            TextInputContent(text: "Third message")
        ]

        XCTAssertEqual(contents.count, 3)
        XCTAssertEqual(contents[0].type, "text")
    }

    // MARK: - Equatable Tests

    func testTextInputContentEquality() {
        let content1 = TextInputContent(text: "Same text")
        let content2 = TextInputContent(text: "Same text")
        let content3 = TextInputContent(text: "Different text")

        XCTAssertEqual(content1, content2)
        XCTAssertNotEqual(content1, content3)
    }

    // MARK: - Hashable Tests

    func testTextInputContentHashable() {
        let content1 = TextInputContent(text: "Text 1")
        let content2 = TextInputContent(text: "Text 2")

        let set: Set<TextInputContent> = [content1, content2]
        XCTAssertEqual(set.count, 2)
        XCTAssertTrue(set.contains(content1))
        XCTAssertTrue(set.contains(content2))
    }

    // MARK: - Sendable Tests

    func testTextInputContentSendable() {
        let content = TextInputContent(text: "Concurrent test")

        Task {
            let capturedContent = content
            XCTAssertEqual(capturedContent.text, "Concurrent test")
        }
    }

    // MARK: - Real-world Usage Tests

    func testSimpleTextMessage() {
        let content = TextInputContent(text: "What is the weather like today?")

        XCTAssertEqual(content.type, "text")
        XCTAssertTrue(content.text.contains("weather"))
    }

    func testLongTextMessage() {
        let longText = """
        This is a longer message that spans multiple lines and contains
        various information. It might be used in a complex user query that
        requires detailed explanation or context.

        The message can include:
        - Multiple paragraphs
        - Lists
        - Technical details
        """

        let content = TextInputContent(text: longText)

        XCTAssertTrue(content.text.contains("multiple lines"))
        XCTAssertTrue(content.text.contains("Lists"))
    }

    func testCodeSnippetInText() {
        let codeText = """
        Can you help me with this Swift code?

        ```swift
        func greet(name: String) {
            print("Hello, \\(name)!")
        }
        ```
        """

        let content = TextInputContent(text: codeText)

        XCTAssertTrue(content.text.contains("Swift code"))
        XCTAssertTrue(content.text.contains("func greet"))
    }

    func testUnicodeInText() {
        let unicodeText = "Hello 👋 World 🌍 with émojis and spëcial çharacters"

        let content = TextInputContent(text: unicodeText)

        XCTAssertEqual(content.text, unicodeText)
        XCTAssertTrue(content.text.contains("👋"))
    }

    func testTextTypeAlwaysText() {
        let content1 = TextInputContent(text: "Message 1")
        let content2 = TextInputContent(text: "Message 2")
        let content3 = TextInputContent(text: "")

        XCTAssertEqual(content1.type, "text")
        XCTAssertEqual(content2.type, "text")
        XCTAssertEqual(content3.type, "text")
    }
}
