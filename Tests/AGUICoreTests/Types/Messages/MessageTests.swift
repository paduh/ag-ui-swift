// MessageTests.swift
// AGUISwift

import XCTest
@testable import AGUICore

/// Tests for the Message protocol
final class MessageTests: XCTestCase {
    // MARK: - Mock Message Implementation

    /// Mock message implementation for testing protocol conformance
    struct MockMessage: Message {
        let id: String
        let role: Role
        let content: String?
        let name: String?

        init(id: String = "test-id", role: Role = .user, content: String? = "Test content", name: String? = nil) {
            self.id = id
            self.role = role
            self.content = content
            self.name = name
        }
    }

    // MARK: - Protocol Conformance Tests

    func testMessageProtocolRequiresId() {
        let message = MockMessage(id: "msg-123")
        XCTAssertEqual(message.id, "msg-123")
    }

    func testMessageProtocolRequiresRole() {
        let message = MockMessage(role: .assistant)
        XCTAssertEqual(message.role, .assistant)
    }

    func testMessageProtocolRequiresContent() {
        let message = MockMessage(content: "Hello, world!")
        XCTAssertEqual(message.content, "Hello, world!")
    }

    func testMessageProtocolRequiresName() {
        let message = MockMessage(name: "TestBot")
        XCTAssertEqual(message.name, "TestBot")
    }

    func testMessageContentCanBeNil() {
        let message = MockMessage(content: nil)
        XCTAssertNil(message.content)
    }

    func testMessageNameCanBeNil() {
        let message = MockMessage(name: nil)
        XCTAssertNil(message.name)
    }

    // MARK: - Sendable Conformance Tests

    func testMessageIsSendable() {
        // This test verifies that Message conforming types can be sent across isolation boundaries
        let message = MockMessage()

        Task {
            // If MockMessage is Sendable, this should compile without warnings
            let capturedMessage = message
            XCTAssertEqual(capturedMessage.id, message.id)
        }
    }

    // MARK: - Codable Round-trip Tests

    func testMessageCodableRoundTrip() throws {
        let original = MockMessage(
            id: "msg-456",
            role: .user,
            content: "Test message",
            name: "TestUser"
        )

        let encoder = JSONEncoder()
        let encoded = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(MockMessage.self, from: encoded)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.role, original.role)
        XCTAssertEqual(decoded.content, original.content)
        XCTAssertEqual(decoded.name, original.name)
    }

    func testMessageEncodingFormat() throws {
        let message = MockMessage(
            id: "msg-789",
            role: .system,
            content: "System message",
            name: nil
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let encoded = try encoder.encode(message)
        let json = String(data: encoded, encoding: .utf8)

        // Verify JSON structure contains required fields
        XCTAssertNotNil(json)
        XCTAssertTrue(json?.contains("\"id\"") ?? false)
        XCTAssertTrue(json?.contains("\"role\"") ?? false)
        XCTAssertTrue(json?.contains("\"content\"") ?? false)
        XCTAssertTrue(json?.contains("\"msg-789\"") ?? false)
        XCTAssertTrue(json?.contains("\"system\"") ?? false)
    }

    func testMessageDecodingWithMissingOptionalFields() throws {
        let json = """
        {
            "id": "msg-minimal",
            "role": "user"
        }
        """

        let decoder = JSONDecoder()
        let message = try decoder.decode(MockMessage.self, from: Data(json.utf8))

        XCTAssertEqual(message.id, "msg-minimal")
        XCTAssertEqual(message.role, .user)
        XCTAssertNil(message.content)
        XCTAssertNil(message.name)
    }

    func testMessageDecodingFailsWithoutId() {
        let json = """
        {
            "role": "user",
            "content": "Test"
        }
        """

        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(MockMessage.self, from: Data(json.utf8))) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testMessageDecodingFailsWithoutRole() {
        let json = """
        {
            "id": "msg-123",
            "content": "Test"
        }
        """

        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(MockMessage.self, from: Data(json.utf8))) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    // MARK: - Multiple Role Types Tests

    func testMessageSupportsAllRoleTypes() throws {
        let roles: [Role] = [.developer, .system, .assistant, .user, .tool, .activity]

        for role in roles {
            let message = MockMessage(id: "msg-\(role)", role: role)
            XCTAssertEqual(message.role, role, "Message should support role: \(role)")

            // Verify encoding/decoding preserves role
            let encoded = try JSONEncoder().encode(message)
            let decoded = try JSONDecoder().decode(MockMessage.self, from: encoded)
            XCTAssertEqual(decoded.role, role, "Round-trip should preserve role: \(role)")
        }
    }

    // MARK: - Equatable Tests (if implemented)

    func testMockMessageEquality() {
        let message1 = MockMessage(id: "msg-1", role: .user, content: "Hello", name: "User1")
        let message2 = MockMessage(id: "msg-1", role: .user, content: "Hello", name: "User1")
        let message3 = MockMessage(id: "msg-2", role: .user, content: "Hello", name: "User1")

        XCTAssertEqual(message1, message2)
        XCTAssertNotEqual(message1, message3)
    }
}

// MARK: - MockMessage Equatable Conformance

extension MessageTests.MockMessage: Equatable {
    static func == (lhs: MessageTests.MockMessage, rhs: MessageTests.MockMessage) -> Bool {
        lhs.id == rhs.id &&
        lhs.role == rhs.role &&
        lhs.content == rhs.content &&
        lhs.name == rhs.name
    }
}
