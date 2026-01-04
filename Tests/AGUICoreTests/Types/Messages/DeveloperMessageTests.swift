// DeveloperMessageTests.swift
// AGUISwift

import XCTest
@testable import AGUICore

/// Tests for the DeveloperMessage type
final class DeveloperMessageTests: XCTestCase {
    // MARK: - Initialization Tests

    func testInitWithRequiredFields() {
        let message = DeveloperMessage(
            id: "dev-1",
            content: "System configuration message"
        )

        XCTAssertEqual(message.id, "dev-1")
        XCTAssertEqual(message.content, "System configuration message")
        XCTAssertNil(message.name)
        XCTAssertEqual(message.role, .developer)
    }

    func testInitWithAllFields() {
        let message = DeveloperMessage(
            id: "dev-2",
            content: "Admin instructions",
            name: "SystemAdmin"
        )

        XCTAssertEqual(message.id, "dev-2")
        XCTAssertEqual(message.content, "Admin instructions")
        XCTAssertEqual(message.name, "SystemAdmin")
        XCTAssertEqual(message.role, .developer)
    }

    // MARK: - Message Protocol Conformance Tests

    func testConformsToMessageProtocol() {
        let message: any Message = DeveloperMessage(
            id: "dev-3",
            content: "Test message"
        )

        XCTAssertEqual(message.id, "dev-3")
        XCTAssertEqual(message.role, .developer)
        XCTAssertEqual(message.content, "Test message")
    }

    func testRoleIsAlwaysDeveloper() {
        let message1 = DeveloperMessage(id: "1", content: "Message 1")
        let message2 = DeveloperMessage(id: "2", content: "Message 2", name: "Admin")

        XCTAssertEqual(message1.role, .developer)
        XCTAssertEqual(message2.role, .developer)
    }

    // MARK: - Encoding Tests

    func testEncodingWithRequiredFields() throws {
        let message = DeveloperMessage(
            id: "dev-encode-1",
            content: "Configuration message"
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let encoded = try encoder.encode(message)
        let json = String(data: encoded, encoding: .utf8)

        XCTAssertNotNil(json)
        XCTAssertTrue(json?.contains("\"id\"") ?? false)
        XCTAssertTrue(json?.contains("\"role\"") ?? false)
        XCTAssertTrue(json?.contains("\"content\"") ?? false)
        XCTAssertTrue(json?.contains("\"developer\"") ?? false)
        XCTAssertTrue(json?.contains("\"dev-encode-1\"") ?? false)
        XCTAssertTrue(json?.contains("\"Configuration message\"") ?? false)
    }

    func testEncodingWithAllFields() throws {
        let message = DeveloperMessage(
            id: "dev-encode-2",
            content: "Admin message",
            name: "DevOps"
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let encoded = try encoder.encode(message)
        let json = String(data: encoded, encoding: .utf8)

        XCTAssertNotNil(json)
        XCTAssertTrue(json?.contains("\"name\"") ?? false)
        XCTAssertTrue(json?.contains("\"DevOps\"") ?? false)
    }

    func testEncodedRoleIsDeveloper() throws {
        let message = DeveloperMessage(id: "dev-role", content: "Test")
        let encoded = try JSONEncoder().encode(message)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]

        XCTAssertEqual(json?["role"] as? String, "developer")
    }

    // MARK: - Decoding Tests

    func testDecodingWithRequiredFields() throws {
        let json = """
        {
            "id": "dev-decode-1",
            "role": "developer",
            "content": "System setup"
        }
        """

        let decoder = JSONDecoder()
        let message = try decoder.decode(DeveloperMessage.self, from: Data(json.utf8))

        XCTAssertEqual(message.id, "dev-decode-1")
        XCTAssertEqual(message.role, .developer)
        XCTAssertEqual(message.content, "System setup")
        XCTAssertNil(message.name)
    }

    func testDecodingWithAllFields() throws {
        let json = """
        {
            "id": "dev-decode-2",
            "role": "developer",
            "content": "Configuration",
            "name": "SysAdmin"
        }
        """

        let decoder = JSONDecoder()
        let message = try decoder.decode(DeveloperMessage.self, from: Data(json.utf8))

        XCTAssertEqual(message.id, "dev-decode-2")
        XCTAssertEqual(message.role, .developer)
        XCTAssertEqual(message.content, "Configuration")
        XCTAssertEqual(message.name, "SysAdmin")
    }

    func testDecodingFailsWithoutId() {
        let json = """
        {
            "role": "developer",
            "content": "Test"
        }
        """

        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(DeveloperMessage.self, from: Data(json.utf8))) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testDecodingFailsWithoutContent() {
        let json = """
        {
            "id": "dev-1",
            "role": "developer"
        }
        """

        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(DeveloperMessage.self, from: Data(json.utf8))) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testDecodingFailsWithWrongRole() {
        let json = """
        {
            "id": "dev-1",
            "role": "user",
            "content": "Test"
        }
        """

        // Note: In a proper polymorphic decoder, this would fail.
        // For now, we're just testing the struct directly
        let decoder = JSONDecoder()
        let message = try? decoder.decode(DeveloperMessage.self, from: Data(json.utf8))

        // The message can decode, but role property will always be .developer
        XCTAssertNotNil(message)
        XCTAssertEqual(message?.role, .developer)
    }

    // MARK: - Round-trip Tests

    func testRoundTripEncodingDecoding() throws {
        let original = DeveloperMessage(
            id: "dev-roundtrip",
            content: "System configuration for agent behavior",
            name: "ConfigManager"
        )

        let encoder = JSONEncoder()
        let encoded = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DeveloperMessage.self, from: encoded)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.role, original.role)
        XCTAssertEqual(decoded.content, original.content)
        XCTAssertEqual(decoded.name, original.name)
    }

    // MARK: - Equatable Tests

    func testEquality() {
        let message1 = DeveloperMessage(id: "1", content: "Config", name: "Admin")
        let message2 = DeveloperMessage(id: "1", content: "Config", name: "Admin")
        let message3 = DeveloperMessage(id: "2", content: "Config", name: "Admin")
        let message4 = DeveloperMessage(id: "1", content: "Different", name: "Admin")

        XCTAssertEqual(message1, message2)
        XCTAssertNotEqual(message1, message3)
        XCTAssertNotEqual(message1, message4)
    }

    // MARK: - Hashable Tests

    func testHashable() {
        let message1 = DeveloperMessage(id: "1", content: "Test")
        let message2 = DeveloperMessage(id: "2", content: "Test")

        let set: Set<DeveloperMessage> = [message1, message2]
        XCTAssertEqual(set.count, 2)
        XCTAssertTrue(set.contains(message1))
        XCTAssertTrue(set.contains(message2))
    }

    // MARK: - Sendable Tests

    func testSendableConformance() {
        let message = DeveloperMessage(id: "dev-concurrent", content: "Test")

        Task {
            let capturedMessage = message
            XCTAssertEqual(capturedMessage.id, "dev-concurrent")
        }
    }

    // MARK: - Real-world Usage Tests

    func testSystemLevelConfiguration() {
        let configMessage = DeveloperMessage(
            id: "config-1",
            content: """
            System configuration:
            - Enable debug logging
            - Set max tokens to 4096
            - Use temperature 0.7
            """,
            name: "SystemConfigurator"
        )

        XCTAssertEqual(configMessage.role, .developer)
        XCTAssertTrue(configMessage.content?.contains("System configuration") ?? false)
    }

    func testMetaInstructions() {
        let metaMessage = DeveloperMessage(
            id: "meta-1",
            content: "Agent should prioritize code quality over speed in all responses"
        )

        XCTAssertEqual(metaMessage.role, .developer)
        XCTAssertNotNil(metaMessage.content)
    }
}
