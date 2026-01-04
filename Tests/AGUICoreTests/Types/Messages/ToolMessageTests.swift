// ToolMessageTests.swift
// AGUISwift

import XCTest
@testable import AGUICore

/// Tests for the ToolMessage type
final class ToolMessageTests: XCTestCase {
    // MARK: - Initialization Tests

    func testInitWithRequiredFields() {
        let message = ToolMessage(
            id: "tool-msg-1",
            content: "Result: 42",
            toolCallId: "call-123"
        )

        XCTAssertEqual(message.id, "tool-msg-1")
        XCTAssertEqual(message.content, "Result: 42")
        XCTAssertEqual(message.toolCallId, "call-123")
        XCTAssertNil(message.name)
        XCTAssertNil(message.error)
        XCTAssertEqual(message.role, .tool)
    }

    func testInitWithAllFields() {
        let message = ToolMessage(
            id: "tool-msg-2",
            content: "File saved successfully",
            toolCallId: "call-456",
            name: "save_file",
            error: nil
        )

        XCTAssertEqual(message.id, "tool-msg-2")
        XCTAssertEqual(message.content, "File saved successfully")
        XCTAssertEqual(message.toolCallId, "call-456")
        XCTAssertEqual(message.name, "save_file")
        XCTAssertNil(message.error)
        XCTAssertEqual(message.role, .tool)
    }

    func testInitWithError() {
        let message = ToolMessage(
            id: "tool-msg-3",
            content: "Failed to execute",
            toolCallId: "call-789",
            name: "broken_tool",
            error: "File not found"
        )

        XCTAssertEqual(message.id, "tool-msg-3")
        XCTAssertEqual(message.error, "File not found")
    }

    // MARK: - Message Protocol Conformance Tests

    func testConformsToMessageProtocol() {
        let message: any Message = ToolMessage(
            id: "tool-msg-4",
            content: "Success",
            toolCallId: "call-test"
        )

        XCTAssertEqual(message.id, "tool-msg-4")
        XCTAssertEqual(message.role, .tool)
        XCTAssertEqual(message.content, "Success")
    }

    func testRoleIsAlwaysTool() {
        let message1 = ToolMessage(id: "1", content: "Result 1", toolCallId: "call-1")
        let message2 = ToolMessage(id: "2", content: "Result 2", toolCallId: "call-2", name: "tool")

        XCTAssertEqual(message1.role, .tool)
        XCTAssertEqual(message2.role, .tool)
    }

    // MARK: - Encoding Tests

    func testEncodingWithRequiredFields() throws {
        let message = ToolMessage(
            id: "tool-encode-1",
            content: "Result data",
            toolCallId: "call-enc-1"
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let encoded = try encoder.encode(message)
        let json = String(data: encoded, encoding: .utf8)

        XCTAssertNotNil(json)
        XCTAssertTrue(json?.contains("\"id\"") ?? false)
        XCTAssertTrue(json?.contains("\"role\"") ?? false)
        XCTAssertTrue(json?.contains("\"content\"") ?? false)
        XCTAssertTrue(json?.contains("\"toolCallId\"") ?? false)
        XCTAssertTrue(json?.contains("\"tool\"") ?? false)
        XCTAssertTrue(json?.contains("\"tool-encode-1\"") ?? false)
        XCTAssertTrue(json?.contains("\"call-enc-1\"") ?? false)
    }

    func testEncodingWithAllFields() throws {
        let message = ToolMessage(
            id: "tool-encode-2",
            content: "Execution result",
            toolCallId: "call-enc-2",
            name: "execute_command",
            error: "Permission denied"
        )

        let encoder = JSONEncoder()
        let encoded = try encoder.encode(message)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]

        XCTAssertNotNil(json)
        XCTAssertEqual(json?["name"] as? String, "execute_command")
        XCTAssertEqual(json?["error"] as? String, "Permission denied")
    }

    func testEncodedRoleIsTool() throws {
        let message = ToolMessage(id: "tool-role", content: "Test", toolCallId: "call-123")
        let encoded = try JSONEncoder().encode(message)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]

        XCTAssertEqual(json?["role"] as? String, "tool")
    }

    // MARK: - Decoding Tests

    func testDecodingWithRequiredFields() throws {
        let json = """
        {
            "id": "tool-decode-1",
            "role": "tool",
            "content": "Operation successful",
            "toolCallId": "call-dec-1"
        }
        """

        let decoder = JSONDecoder()
        let message = try decoder.decode(ToolMessage.self, from: Data(json.utf8))

        XCTAssertEqual(message.id, "tool-decode-1")
        XCTAssertEqual(message.role, .tool)
        XCTAssertEqual(message.content, "Operation successful")
        XCTAssertEqual(message.toolCallId, "call-dec-1")
        XCTAssertNil(message.name)
        XCTAssertNil(message.error)
    }

    func testDecodingWithAllFields() throws {
        let json = """
        {
            "id": "tool-decode-2",
            "role": "tool",
            "content": "File written",
            "toolCallId": "call-dec-2",
            "name": "write_file",
            "error": null
        }
        """

        let decoder = JSONDecoder()
        let message = try decoder.decode(ToolMessage.self, from: Data(json.utf8))

        XCTAssertEqual(message.id, "tool-decode-2")
        XCTAssertEqual(message.content, "File written")
        XCTAssertEqual(message.toolCallId, "call-dec-2")
        XCTAssertEqual(message.name, "write_file")
        XCTAssertNil(message.error)
    }

    func testDecodingWithError() throws {
        let json = """
        {
            "id": "tool-decode-3",
            "role": "tool",
            "content": "Failed",
            "toolCallId": "call-dec-3",
            "error": "Network timeout"
        }
        """

        let decoder = JSONDecoder()
        let message = try decoder.decode(ToolMessage.self, from: Data(json.utf8))

        XCTAssertEqual(message.error, "Network timeout")
    }

    func testDecodingFailsWithoutId() {
        let json = """
        {
            "role": "tool",
            "content": "Test",
            "toolCallId": "call-1"
        }
        """

        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(ToolMessage.self, from: Data(json.utf8))) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testDecodingFailsWithoutContent() {
        let json = """
        {
            "id": "tool-1",
            "role": "tool",
            "toolCallId": "call-1"
        }
        """

        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(ToolMessage.self, from: Data(json.utf8))) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testDecodingFailsWithoutToolCallId() {
        let json = """
        {
            "id": "tool-1",
            "role": "tool",
            "content": "Result"
        }
        """

        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(ToolMessage.self, from: Data(json.utf8))) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    // MARK: - Round-trip Tests

    func testRoundTripWithRequiredFields() throws {
        let original = ToolMessage(
            id: "tool-roundtrip-1",
            content: "Database query result: 100 rows",
            toolCallId: "call-rt-1"
        )

        let encoder = JSONEncoder()
        let encoded = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ToolMessage.self, from: encoded)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.role, original.role)
        XCTAssertEqual(decoded.content, original.content)
        XCTAssertEqual(decoded.toolCallId, original.toolCallId)
    }

    func testRoundTripWithAllFields() throws {
        let original = ToolMessage(
            id: "tool-roundtrip-2",
            content: "API call failed",
            toolCallId: "call-rt-2",
            name: "api_request",
            error: "HTTP 500 Internal Server Error"
        )

        let encoder = JSONEncoder()
        let encoded = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ToolMessage.self, from: encoded)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.content, original.content)
        XCTAssertEqual(decoded.toolCallId, original.toolCallId)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.error, original.error)
    }

    // MARK: - Equatable Tests

    func testEquality() {
        let message1 = ToolMessage(id: "1", content: "Result", toolCallId: "call-1", name: "tool")
        let message2 = ToolMessage(id: "1", content: "Result", toolCallId: "call-1", name: "tool")
        let message3 = ToolMessage(id: "2", content: "Result", toolCallId: "call-1", name: "tool")
        let message4 = ToolMessage(id: "1", content: "Different", toolCallId: "call-1", name: "tool")
        let message5 = ToolMessage(id: "1", content: "Result", toolCallId: "call-2", name: "tool")

        XCTAssertEqual(message1, message2)
        XCTAssertNotEqual(message1, message3)
        XCTAssertNotEqual(message1, message4)
        XCTAssertNotEqual(message1, message5)
    }

    // MARK: - Hashable Tests

    func testHashable() {
        let message1 = ToolMessage(id: "1", content: "Test", toolCallId: "call-1")
        let message2 = ToolMessage(id: "2", content: "Test", toolCallId: "call-2")

        let set: Set<ToolMessage> = [message1, message2]
        XCTAssertEqual(set.count, 2)
        XCTAssertTrue(set.contains(message1))
        XCTAssertTrue(set.contains(message2))
    }

    // MARK: - Sendable Tests

    func testSendableConformance() {
        let message = ToolMessage(id: "tool-concurrent", content: "Result", toolCallId: "call-123")

        Task {
            let capturedMessage = message
            XCTAssertEqual(capturedMessage.toolCallId, "call-123")
        }
    }

    // MARK: - Real-world Usage Tests

    func testSuccessfulToolExecution() {
        let result = ToolMessage(
            id: "tool-success-1",
            content: "Successfully saved 5 files to /documents",
            toolCallId: "call-save-files-1",
            name: "save_files"
        )

        XCTAssertEqual(result.role, .tool)
        XCTAssertNil(result.error)
        XCTAssertTrue(result.content?.contains("Successfully") ?? false)
    }

    func testFailedToolExecution() {
        let result = ToolMessage(
            id: "tool-error-1",
            content: "Operation failed",
            toolCallId: "call-delete-1",
            name: "delete_file",
            error: "Permission denied: Cannot delete system file"
        )

        XCTAssertNotNil(result.error)
        XCTAssertTrue(result.error?.contains("Permission denied") ?? false)
    }

    func testToolCallIdLinkage() {
        // Verify that toolCallId properly links request and response
        let toolCallId = "call-calc-123"

        let toolMessage = ToolMessage(
            id: "tool-response-1",
            content: "Result: 3.14159",
            toolCallId: toolCallId,
            name: "calculate_pi"
        )

        // The toolCallId should match the original tool call request
        XCTAssertEqual(toolMessage.toolCallId, toolCallId)
    }

    func testDatabaseQueryResult() {
        let queryResult = ToolMessage(
            id: "tool-db-1",
            content: """
            Query executed successfully.
            Rows affected: 42
            Execution time: 127ms
            """,
            toolCallId: "call-query-users",
            name: "execute_sql"
        )

        XCTAssertTrue(queryResult.content?.contains("42") ?? false)
    }
}
