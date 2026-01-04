// SystemMessageTests.swift
// AGUISwift

import XCTest
@testable import AGUICore

/// Tests for the SystemMessage type
final class SystemMessageTests: XCTestCase {
    // MARK: - Initialization Tests

    func testInitWithRequiredFields() {
        let message = SystemMessage(
            id: "sys-1",
            content: "You are a helpful assistant."
        )

        XCTAssertEqual(message.id, "sys-1")
        XCTAssertEqual(message.content, "You are a helpful assistant.")
        XCTAssertNil(message.name)
        XCTAssertEqual(message.role, .system)
    }

    func testInitWithAllFields() {
        let message = SystemMessage(
            id: "sys-2",
            content: "Be concise and professional.",
            name: "ProfessionalAssistant"
        )

        XCTAssertEqual(message.id, "sys-2")
        XCTAssertEqual(message.content, "Be concise and professional.")
        XCTAssertEqual(message.name, "ProfessionalAssistant")
        XCTAssertEqual(message.role, .system)
    }

    func testInitWithNilContent() {
        let message = SystemMessage(
            id: "sys-3",
            content: nil
        )

        XCTAssertEqual(message.id, "sys-3")
        XCTAssertNil(message.content)
        XCTAssertNil(message.name)
        XCTAssertEqual(message.role, .system)
    }

    // MARK: - Message Protocol Conformance Tests

    func testConformsToMessageProtocol() {
        let message: any Message = SystemMessage(
            id: "sys-4",
            content: "Test message"
        )

        XCTAssertEqual(message.id, "sys-4")
        XCTAssertEqual(message.role, .system)
        XCTAssertEqual(message.content, "Test message")
    }

    func testRoleIsAlwaysSystem() {
        let message1 = SystemMessage(id: "1", content: "Message 1")
        let message2 = SystemMessage(id: "2", content: nil, name: "System")

        XCTAssertEqual(message1.role, .system)
        XCTAssertEqual(message2.role, .system)
    }

    // MARK: - Encoding Tests

    func testEncodingWithContent() throws {
        let message = SystemMessage(
            id: "sys-encode-1",
            content: "You are a helpful assistant."
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let encoded = try encoder.encode(message)
        let json = String(data: encoded, encoding: .utf8)

        XCTAssertNotNil(json)
        XCTAssertTrue(json?.contains("\"id\"") ?? false)
        XCTAssertTrue(json?.contains("\"role\"") ?? false)
        XCTAssertTrue(json?.contains("\"content\"") ?? false)
        XCTAssertTrue(json?.contains("\"system\"") ?? false)
        XCTAssertTrue(json?.contains("\"sys-encode-1\"") ?? false)
        XCTAssertTrue(json?.contains("You are a helpful assistant") ?? false)
    }

    func testEncodingWithNilContent() throws {
        let message = SystemMessage(
            id: "sys-encode-2",
            content: nil,
            name: "EmptySystem"
        )

        let encoder = JSONEncoder()
        let encoded = try encoder.encode(message)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]

        XCTAssertNotNil(json)
        // When content is nil, it should be encoded as null or omitted
        XCTAssertTrue(json?["content"] == nil || json?["content"] is NSNull)
        XCTAssertEqual(json?["name"] as? String, "EmptySystem")
    }

    func testEncodedRoleIsSystem() throws {
        let message = SystemMessage(id: "sys-role", content: "Test")
        let encoded = try JSONEncoder().encode(message)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]

        XCTAssertEqual(json?["role"] as? String, "system")
    }

    // MARK: - Decoding Tests

    func testDecodingWithContent() throws {
        let json = """
        {
            "id": "sys-decode-1",
            "role": "system",
            "content": "You are a coding assistant."
        }
        """

        let decoder = JSONDecoder()
        let message = try decoder.decode(SystemMessage.self, from: Data(json.utf8))

        XCTAssertEqual(message.id, "sys-decode-1")
        XCTAssertEqual(message.role, .system)
        XCTAssertEqual(message.content, "You are a coding assistant.")
        XCTAssertNil(message.name)
    }

    func testDecodingWithAllFields() throws {
        let json = """
        {
            "id": "sys-decode-2",
            "role": "system",
            "content": "Be professional.",
            "name": "ProfessionalMode"
        }
        """

        let decoder = JSONDecoder()
        let message = try decoder.decode(SystemMessage.self, from: Data(json.utf8))

        XCTAssertEqual(message.id, "sys-decode-2")
        XCTAssertEqual(message.role, .system)
        XCTAssertEqual(message.content, "Be professional.")
        XCTAssertEqual(message.name, "ProfessionalMode")
    }

    func testDecodingWithNilContent() throws {
        let json = """
        {
            "id": "sys-decode-3",
            "role": "system"
        }
        """

        let decoder = JSONDecoder()
        let message = try decoder.decode(SystemMessage.self, from: Data(json.utf8))

        XCTAssertEqual(message.id, "sys-decode-3")
        XCTAssertEqual(message.role, .system)
        XCTAssertNil(message.content)
        XCTAssertNil(message.name)
    }

    func testDecodingWithNullContent() throws {
        let json = """
        {
            "id": "sys-decode-4",
            "role": "system",
            "content": null
        }
        """

        let decoder = JSONDecoder()
        let message = try decoder.decode(SystemMessage.self, from: Data(json.utf8))

        XCTAssertEqual(message.id, "sys-decode-4")
        XCTAssertNil(message.content)
    }

    func testDecodingFailsWithoutId() {
        let json = """
        {
            "role": "system",
            "content": "Test"
        }
        """

        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(SystemMessage.self, from: Data(json.utf8))) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    // MARK: - Round-trip Tests

    func testRoundTripWithContent() throws {
        let original = SystemMessage(
            id: "sys-roundtrip-1",
            content: "You are an expert Swift developer.",
            name: "SwiftExpert"
        )

        let encoder = JSONEncoder()
        let encoded = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SystemMessage.self, from: encoded)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.role, original.role)
        XCTAssertEqual(decoded.content, original.content)
        XCTAssertEqual(decoded.name, original.name)
    }

    func testRoundTripWithNilContent() throws {
        let original = SystemMessage(
            id: "sys-roundtrip-2",
            content: nil
        )

        let encoder = JSONEncoder()
        let encoded = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SystemMessage.self, from: encoded)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.role, original.role)
        XCTAssertNil(decoded.content)
    }

    // MARK: - Equatable Tests

    func testEquality() {
        let message1 = SystemMessage(id: "1", content: "Test", name: "Sys")
        let message2 = SystemMessage(id: "1", content: "Test", name: "Sys")
        let message3 = SystemMessage(id: "2", content: "Test", name: "Sys")
        let message4 = SystemMessage(id: "1", content: "Different", name: "Sys")
        let message5 = SystemMessage(id: "1", content: nil, name: "Sys")

        XCTAssertEqual(message1, message2)
        XCTAssertNotEqual(message1, message3)
        XCTAssertNotEqual(message1, message4)
        XCTAssertNotEqual(message1, message5)
    }

    // MARK: - Hashable Tests

    func testHashable() {
        let message1 = SystemMessage(id: "1", content: "Test")
        let message2 = SystemMessage(id: "2", content: "Test")

        let set: Set<SystemMessage> = [message1, message2]
        XCTAssertEqual(set.count, 2)
        XCTAssertTrue(set.contains(message1))
        XCTAssertTrue(set.contains(message2))
    }

    // MARK: - Sendable Tests

    func testSendableConformance() {
        let message = SystemMessage(id: "sys-concurrent", content: "Test")

        Task {
            let capturedMessage = message
            XCTAssertEqual(capturedMessage.id, "sys-concurrent")
        }
    }

    // MARK: - Real-world Usage Tests

    func testBehavioralGuidelines() {
        let guidelines = SystemMessage(
            id: "sys-behavioral-1",
            content: """
            You are a professional coding assistant. Guidelines:
            - Always explain your reasoning
            - Write clean, well-documented code
            - Follow best practices
            - Be concise but thorough
            """
        )

        XCTAssertEqual(guidelines.role, .system)
        XCTAssertTrue(guidelines.content?.contains("professional") ?? false)
    }

    func testPersonalityTraits() {
        let personality = SystemMessage(
            id: "sys-personality-1",
            content: "You are friendly, patient, and encouraging in all interactions.",
            name: "FriendlyAssistant"
        )

        XCTAssertEqual(personality.role, .system)
        XCTAssertEqual(personality.name, "FriendlyAssistant")
    }

    func testContextSetting() {
        let context = SystemMessage(
            id: "sys-context-1",
            content: "You are helping a beginner learn Swift programming. Be patient and explain concepts clearly."
        )

        XCTAssertNotNil(context.content)
        XCTAssertTrue(context.content?.contains("beginner") ?? false)
    }
}
