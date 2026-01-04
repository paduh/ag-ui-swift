// AssistantMessageTests.swift
// AGUISwift

import XCTest
@testable import AGUICore

/// Tests for the AssistantMessage type
final class AssistantMessageTests: XCTestCase {
    // MARK: - Initialization Tests

    func testInitWithContentOnly() {
        let message = AssistantMessage(
            id: "asst-1",
            content: "Hello! How can I help you?"
        )

        XCTAssertEqual(message.id, "asst-1")
        XCTAssertEqual(message.content, "Hello! How can I help you?")
        XCTAssertNil(message.name)
        XCTAssertNil(message.toolCalls)
        XCTAssertEqual(message.role, .assistant)
    }

    func testInitWithToolCallsOnly() {
        let toolCall = ToolCall(
            id: "call_123",
            function: FunctionCall(name: "get_weather", arguments: "{}")
        )

        let message = AssistantMessage(
            id: "asst-2",
            content: nil,
            toolCalls: [toolCall]
        )

        XCTAssertEqual(message.id, "asst-2")
        XCTAssertNil(message.content)
        XCTAssertEqual(message.toolCalls?.count, 1)
        XCTAssertEqual(message.toolCalls?.first?.id, "call_123")
    }

    func testInitWithContentAndToolCalls() {
        let toolCall = ToolCall(
            id: "call_456",
            function: FunctionCall(name: "search", arguments: "{\"query\":\"test\"}")
        )

        let message = AssistantMessage(
            id: "asst-3",
            content: "Let me search for that information.",
            toolCalls: [toolCall]
        )

        XCTAssertEqual(message.id, "asst-3")
        XCTAssertEqual(message.content, "Let me search for that information.")
        XCTAssertEqual(message.toolCalls?.count, 1)
    }

    func testInitWithAllFields() {
        let toolCalls = [
            ToolCall(id: "call_1", function: FunctionCall(name: "func1", arguments: "{}")),
            ToolCall(id: "call_2", function: FunctionCall(name: "func2", arguments: "{}"))
        ]

        let message = AssistantMessage(
            id: "asst-4",
            content: "Processing your request",
            name: "HelperBot",
            toolCalls: toolCalls
        )

        XCTAssertEqual(message.id, "asst-4")
        XCTAssertEqual(message.content, "Processing your request")
        XCTAssertEqual(message.name, "HelperBot")
        XCTAssertEqual(message.toolCalls?.count, 2)
        XCTAssertEqual(message.role, .assistant)
    }

    // MARK: - Message Protocol Conformance Tests

    func testConformsToMessageProtocol() {
        let message: any Message = AssistantMessage(
            id: "asst-5",
            content: "Test"
        )

        XCTAssertEqual(message.id, "asst-5")
        XCTAssertEqual(message.role, .assistant)
        XCTAssertEqual(message.content, "Test")
    }

    func testRoleIsAlwaysAssistant() {
        let message1 = AssistantMessage(id: "1", content: "Message 1")
        let message2 = AssistantMessage(id: "2", content: nil, toolCalls: [])

        XCTAssertEqual(message1.role, .assistant)
        XCTAssertEqual(message2.role, .assistant)
    }

    // MARK: - Encoding Tests

    func testEncodingWithContentOnly() throws {
        let message = AssistantMessage(
            id: "asst-encode-1",
            content: "Simple response"
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let encoded = try encoder.encode(message)
        let json = String(data: encoded, encoding: .utf8)

        XCTAssertNotNil(json)
        XCTAssertTrue(json?.contains("\"id\"") ?? false)
        XCTAssertTrue(json?.contains("\"role\"") ?? false)
        XCTAssertTrue(json?.contains("\"content\"") ?? false)
        XCTAssertTrue(json?.contains("\"assistant\"") ?? false)
        XCTAssertTrue(json?.contains("\"Simple response\"") ?? false)
    }

    func testEncodingWithToolCalls() throws {
        let toolCall = ToolCall(
            id: "call_test",
            function: FunctionCall(name: "test_func", arguments: "{}")
        )

        let message = AssistantMessage(
            id: "asst-encode-2",
            content: "Calling function",
            toolCalls: [toolCall]
        )

        let encoded = try JSONEncoder().encode(message)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]

        XCTAssertNotNil(json?["toolCalls"])
        let toolCallsArray = json?["toolCalls"] as? [[String: Any]]
        XCTAssertEqual(toolCallsArray?.count, 1)
        XCTAssertEqual(toolCallsArray?.first?["id"] as? String, "call_test")
    }

    func testEncodedRoleIsAssistant() throws {
        let message = AssistantMessage(id: "asst-role", content: "Test")
        let encoded = try JSONEncoder().encode(message)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]

        XCTAssertEqual(json?["role"] as? String, "assistant")
    }

    // MARK: - Decoding Tests

    func testDecodingWithContentOnly() throws {
        let json = """
        {
            "id": "asst-decode-1",
            "role": "assistant",
            "content": "Hello there!"
        }
        """

        let decoder = JSONDecoder()
        let message = try decoder.decode(AssistantMessage.self, from: Data(json.utf8))

        XCTAssertEqual(message.id, "asst-decode-1")
        XCTAssertEqual(message.role, .assistant)
        XCTAssertEqual(message.content, "Hello there!")
        XCTAssertNil(message.toolCalls)
    }

    func testDecodingWithToolCalls() throws {
        let json = """
        {
            "id": "asst-decode-2",
            "role": "assistant",
            "content": "Let me check that",
            "toolCalls": [
                {
                    "id": "call_abc",
                    "type": "function",
                    "function": {
                        "name": "get_data",
                        "arguments": "{\\"key\\":\\"value\\"}"
                    }
                }
            ]
        }
        """

        let decoder = JSONDecoder()
        let message = try decoder.decode(AssistantMessage.self, from: Data(json.utf8))

        XCTAssertEqual(message.id, "asst-decode-2")
        XCTAssertEqual(message.content, "Let me check that")
        XCTAssertEqual(message.toolCalls?.count, 1)
        XCTAssertEqual(message.toolCalls?.first?.id, "call_abc")
        XCTAssertEqual(message.toolCalls?.first?.function.name, "get_data")
    }

    func testDecodingWithNilContent() throws {
        let json = """
        {
            "id": "asst-decode-3",
            "role": "assistant"
        }
        """

        let decoder = JSONDecoder()
        let message = try decoder.decode(AssistantMessage.self, from: Data(json.utf8))

        XCTAssertEqual(message.id, "asst-decode-3")
        XCTAssertNil(message.content)
    }

    func testDecodingWithMultipleToolCalls() throws {
        let json = """
        {
            "id": "asst-decode-4",
            "role": "assistant",
            "toolCalls": [
                {
                    "id": "call_1",
                    "type": "function",
                    "function": {"name": "func1", "arguments": "{}"}
                },
                {
                    "id": "call_2",
                    "type": "function",
                    "function": {"name": "func2", "arguments": "{}"}
                }
            ]
        }
        """

        let decoder = JSONDecoder()
        let message = try decoder.decode(AssistantMessage.self, from: Data(json.utf8))

        XCTAssertEqual(message.toolCalls?.count, 2)
        XCTAssertEqual(message.toolCalls?[0].id, "call_1")
        XCTAssertEqual(message.toolCalls?[1].id, "call_2")
    }

    func testDecodingFailsWithoutId() {
        let json = """
        {
            "role": "assistant",
            "content": "Test"
        }
        """

        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(AssistantMessage.self, from: Data(json.utf8))) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    // MARK: - Round-trip Tests

    func testRoundTripWithContent() throws {
        let original = AssistantMessage(
            id: "asst-roundtrip-1",
            content: "This is a test response",
            name: "Assistant"
        )

        let encoder = JSONEncoder()
        let encoded = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AssistantMessage.self, from: encoded)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.content, original.content)
        XCTAssertEqual(decoded.name, original.name)
    }

    func testRoundTripWithToolCalls() throws {
        let toolCalls = [
            ToolCall(id: "call_rt1", function: FunctionCall(name: "func1", arguments: "{\"a\":1}")),
            ToolCall(id: "call_rt2", function: FunctionCall(name: "func2", arguments: "{\"b\":2}"))
        ]

        let original = AssistantMessage(
            id: "asst-roundtrip-2",
            content: "Executing functions",
            toolCalls: toolCalls
        )

        let encoder = JSONEncoder()
        let encoded = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AssistantMessage.self, from: encoded)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.toolCalls?.count, original.toolCalls?.count)
        XCTAssertEqual(decoded.toolCalls?[0].id, original.toolCalls?[0].id)
    }

    // MARK: - Equatable Tests

    func testEquality() {
        let toolCall = ToolCall(id: "call_1", function: FunctionCall(name: "test", arguments: "{}"))

        let message1 = AssistantMessage(id: "1", content: "Test", toolCalls: [toolCall])
        let message2 = AssistantMessage(id: "1", content: "Test", toolCalls: [toolCall])
        let message3 = AssistantMessage(id: "2", content: "Test", toolCalls: [toolCall])
        let message4 = AssistantMessage(id: "1", content: "Different")

        XCTAssertEqual(message1, message2)
        XCTAssertNotEqual(message1, message3)
        XCTAssertNotEqual(message1, message4)
    }

    // MARK: - Hashable Tests

    func testHashable() {
        let message1 = AssistantMessage(id: "1", content: "Test")
        let message2 = AssistantMessage(id: "2", content: "Test")

        let set: Set<AssistantMessage> = [message1, message2]
        XCTAssertEqual(set.count, 2)
        XCTAssertTrue(set.contains(message1))
        XCTAssertTrue(set.contains(message2))
    }

    // MARK: - Sendable Tests

    func testSendableConformance() {
        let message = AssistantMessage(id: "asst-concurrent", content: "Test")

        Task {
            let capturedMessage = message
            XCTAssertEqual(capturedMessage.id, "asst-concurrent")
        }
    }

    // MARK: - Real-world Usage Tests

    func testTextOnlyResponse() {
        let response = AssistantMessage(
            id: "asst-text-1",
            content: "I understand your question. Let me explain..."
        )

        XCTAssertEqual(response.role, .assistant)
        XCTAssertNotNil(response.content)
        XCTAssertNil(response.toolCalls)
    }

    func testToolCallWithExplanation() {
        let weatherCall = ToolCall(
            id: "call_weather",
            function: FunctionCall(
                name: "get_weather",
                arguments: "{\"location\":\"San Francisco\"}"
            )
        )

        let response = AssistantMessage(
            id: "asst-tool-1",
            content: "Let me check the weather for you.",
            toolCalls: [weatherCall]
        )

        XCTAssertNotNil(response.content)
        XCTAssertEqual(response.toolCalls?.count, 1)
        XCTAssertTrue(response.content?.contains("weather") ?? false)
    }

    func testMultipleToolCallsAtOnce() {
        let toolCalls = [
            ToolCall(id: "call_1", function: FunctionCall(name: "get_user", arguments: "{\"id\":\"123\"}")),
            ToolCall(id: "call_2", function: FunctionCall(name: "get_orders", arguments: "{\"userId\":\"123\"}")),
            ToolCall(id: "call_3", function: FunctionCall(name: "get_preferences", arguments: "{\"userId\":\"123\"}"))
        ]

        let response = AssistantMessage(
            id: "asst-multi-1",
            content: "Gathering information from multiple sources...",
            toolCalls: toolCalls
        )

        XCTAssertEqual(response.toolCalls?.count, 3)
    }

    func testToolCallOnlyNoText() {
        let toolCall = ToolCall(
            id: "call_silent",
            function: FunctionCall(name: "background_task", arguments: "{}")
        )

        let response = AssistantMessage(
            id: "asst-silent-1",
            content: nil,
            toolCalls: [toolCall]
        )

        XCTAssertNil(response.content)
        XCTAssertNotNil(response.toolCalls)
    }
}
