import XCTest
@testable import AGUICore

final class ToolCallResultEventTests: XCTestCase {

    // MARK: - Feature: Decode TOOL_CALL_RESULT

    func test_decodeValidToolCallResult_returnsToolCallResultEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_RESULT",
          "messageId": "msg-123",
          "toolCallId": "call-456",
          "content": "Temperature: 72°F"
        }
        """)

        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        guard let toolCallResult = event as? ToolCallResultEvent else {
            return XCTFail("Expected ToolCallResultEvent, got \(type(of: event))")
        }
        XCTAssertEqual(toolCallResult.eventType, .toolCallResult)
        XCTAssertEqual(toolCallResult.messageId, "msg-123")
        XCTAssertEqual(toolCallResult.toolCallId, "call-456")
        XCTAssertEqual(toolCallResult.content, "Temperature: 72°F")
        XCTAssertNil(toolCallResult.role)
        XCTAssertNil(toolCallResult.timestamp)
    }

    func test_decodeToolCallResult_withRole_populatesRole() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_RESULT",
          "messageId": "msg-123",
          "toolCallId": "call-456",
          "content": "Temperature: 72°F",
          "role": "tool"
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let toolCallResult = try XCTUnwrap(event as? ToolCallResultEvent)
        XCTAssertEqual(toolCallResult.role, "tool")
    }

    func test_decodeToolCallResult_withTimestamp_populatesTimestamp() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_RESULT",
          "messageId": "msg-123",
          "toolCallId": "call-456",
          "content": "Temperature: 72°F",
          "timestamp": 1704067200000
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let toolCallResult = try XCTUnwrap(event as? ToolCallResultEvent)
        XCTAssertEqual(toolCallResult.timestamp, 1704067200000)
    }

    func test_decodeToolCallResult_preservesRawEventBytes() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_RESULT",
          "messageId": "msg-123",
          "toolCallId": "call-456",
          "content": "Temperature: 72°F",
          "timestamp": 1704067200000
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let toolCallResult = try XCTUnwrap(event as? ToolCallResultEvent)
        XCTAssertEqual(toolCallResult.rawEvent, data)
    }

    func test_decodeToolCallResult_ignoresUnknownExtraFields() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_RESULT",
          "messageId": "msg-123",
          "toolCallId": "call-456",
          "content": "Temperature: 72°F",
          "extraField": "ignored",
          "nested": { "x": 1 }
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let toolCallResult = try XCTUnwrap(event as? ToolCallResultEvent)
        XCTAssertEqual(toolCallResult.messageId, "msg-123")
        XCTAssertEqual(toolCallResult.toolCallId, "call-456")
        XCTAssertEqual(toolCallResult.content, "Temperature: 72°F")
    }

    func test_decodeToolCallResult_withUnicodeContent_handlesCorrectly() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_RESULT",
          "messageId": "msg-123",
          "toolCallId": "call-456",
          "content": "温度: 22°C 🌡️"
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let toolCallResult = try XCTUnwrap(event as? ToolCallResultEvent)
        XCTAssertEqual(toolCallResult.content, "温度: 22°C 🌡️")
    }

    func test_decodeToolCallResult_withMultilineContent_handlesCorrectly() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_RESULT",
          "messageId": "msg-123",
          "toolCallId": "call-456",
          "content": "Line 1\\nLine 2\\nLine 3"
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let toolCallResult = try XCTUnwrap(event as? ToolCallResultEvent)
        XCTAssertEqual(toolCallResult.content, "Line 1\nLine 2\nLine 3")
    }

    func test_decodeToolCallResult_withEmptyContent_allowsEmptyString() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_RESULT",
          "messageId": "msg-123",
          "toolCallId": "call-456",
          "content": ""
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let toolCallResult = try XCTUnwrap(event as? ToolCallResultEvent)
        XCTAssertEqual(toolCallResult.content, "")
    }

    // MARK: - Feature: Error handling

    func test_decodeMissingType_throwsMissingTypeField() {
        // Given
        let data = jsonData("""
        {
          "messageId": "msg-123",
          "toolCallId": "call-456",
          "content": "Temperature: 72°F"
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            XCTAssertEqual(error as? EventDecodingError, .missingTypeField)
        }
    }

    func test_decodeUnknownType_inStrictMode_throwsUnknownEventType() {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_PAUSED",
          "messageId": "msg-123",
          "toolCallId": "call-456",
          "content": "Temperature: 72°F"
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            guard case .unknownEventType(let type) = error as? EventDecodingError else {
                return XCTFail("Expected unknownEventType, got \(error)")
            }
            XCTAssertEqual(type, "TOOL_CALL_PAUSED")
        }
    }

    func test_decodeUnknownType_inTolerantMode_returnsUnknownEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_PAUSED",
          "messageId": "msg-123",
          "toolCallId": "call-456",
          "content": "Temperature: 72°F"
        }
        """)
        let decoder = makeTolerantDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let unknown = try XCTUnwrap(event as? UnknownEvent)
        XCTAssertEqual(unknown.typeRaw, "TOOL_CALL_PAUSED")
        XCTAssertEqual(unknown.rawEvent, data)
    }

    func test_decodeKnownTypeButNoHandler_inStrictMode_throwsUnsupportedEventType() {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_RESULT",
          "messageId": "msg-123",
          "toolCallId": "call-456",
          "content": "Temperature: 72°F"
        }
        """)

        // registry intentionally empty -> handler missing
        let decoder = makeStrictDecoder(registry: [:])

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            XCTAssertEqual(error as? EventDecodingError, .unsupportedEventType(.toolCallResult))
        }
    }

    func test_decodeKnownTypeButNoHandler_inTolerantMode_returnsUnknownEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_RESULT",
          "messageId": "msg-123",
          "toolCallId": "call-456",
          "content": "Temperature: 72°F"
        }
        """)
        let decoder = makeTolerantDecoder(registry: [:])

        // When
        let event = try decoder.decode(data)

        // Then
        let unknown = try XCTUnwrap(event as? UnknownEvent)
        XCTAssertEqual(unknown.typeRaw, "TOOL_CALL_RESULT")
        XCTAssertEqual(unknown.rawEvent, data)
    }

    func test_decodeToolCallResult_missingMessageId_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_RESULT",
          "toolCallId": "call-456",
          "content": "Temperature: 72°F"
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            guard case .decodingFailed(let message) = error as? EventDecodingError else {
                return XCTFail("Expected decodingFailed, got \(error)")
            }
            XCTAssertTrue(message.contains("messageId") || message.contains("Missing key"))
        }
    }

    func test_decodeToolCallResult_missingToolCallId_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_RESULT",
          "messageId": "msg-123",
          "content": "Temperature: 72°F"
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            guard case .decodingFailed(let message) = error as? EventDecodingError else {
                return XCTFail("Expected decodingFailed, got \(error)")
            }
            XCTAssertTrue(message.contains("toolCallId") || message.contains("Missing key"))
        }
    }

    func test_decodeToolCallResult_missingContent_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_RESULT",
          "messageId": "msg-123",
          "toolCallId": "call-456"
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            guard case .decodingFailed(let message) = error as? EventDecodingError else {
                return XCTFail("Expected decodingFailed, got \(error)")
            }
            XCTAssertTrue(message.contains("content") || message.contains("Missing key"))
        }
    }

    func test_decodeToolCallResult_wrongTypeForMessageId_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_RESULT",
          "messageId": 123,
          "toolCallId": "call-456",
          "content": "Temperature: 72°F"
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            guard case .decodingFailed(let message) = error as? EventDecodingError else {
                return XCTFail("Expected decodingFailed, got \(error)")
            }
            XCTAssertTrue(message.contains("messageId") || message.contains("Type mismatch"))
        }
    }

    func test_decodeToolCallResult_wrongTypeForToolCallId_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_RESULT",
          "messageId": "msg-123",
          "toolCallId": 456,
          "content": "Temperature: 72°F"
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            guard case .decodingFailed(let message) = error as? EventDecodingError else {
                return XCTFail("Expected decodingFailed, got \(error)")
            }
            XCTAssertTrue(message.contains("toolCallId") || message.contains("Type mismatch"))
        }
    }

    func test_decodeToolCallResult_wrongTypeForContent_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_RESULT",
          "messageId": "msg-123",
          "toolCallId": "call-456",
          "content": 123
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            guard case .decodingFailed(let message) = error as? EventDecodingError else {
                return XCTFail("Expected decodingFailed, got \(error)")
            }
            XCTAssertTrue(message.contains("content") || message.contains("Type mismatch"))
        }
    }

    func test_decodeToolCallResult_wrongTypeForRole_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_RESULT",
          "messageId": "msg-123",
          "toolCallId": "call-456",
          "content": "Temperature: 72°F",
          "role": 123
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            guard case .decodingFailed(let message) = error as? EventDecodingError else {
                return XCTFail("Expected decodingFailed, got \(error)")
            }
            XCTAssertTrue(message.contains("role") || message.contains("Type mismatch"))
        }
    }

    func test_decodeToolCallResult_wrongTypeForTimestamp_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_RESULT",
          "messageId": "msg-123",
          "toolCallId": "call-456",
          "content": "Temperature: 72°F",
          "timestamp": "invalid"
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            guard case .decodingFailed(let message) = error as? EventDecodingError else {
                return XCTFail("Expected decodingFailed, got \(error)")
            }
            XCTAssertTrue(message.contains("timestamp") || message.contains("Type mismatch"))
        }
    }

    func test_decodeInvalidJSON_throwsInvalidJSON() {
        // Given
        let data = Data("invalid json".utf8)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            XCTAssertEqual(error as? EventDecodingError, .invalidJSON)
        }
    }

    // MARK: - Feature: Model behaviors

    func test_toolCallResultEvent_eventTypeIsAlwaysToolCallResult() {
        // Given
        let event = ToolCallResultEvent(messageId: "msg-123", toolCallId: "call-456", content: "Result", timestamp: nil, rawEvent: nil)

        // Then
        XCTAssertEqual(event.eventType, .toolCallResult)
    }

    func test_toolCallResultEvent_equatable_sameFields_areEqual() {
        // Given
        let a = ToolCallResultEvent(messageId: "msg-123", toolCallId: "call-456", content: "Result", role: "tool", timestamp: 1, rawEvent: nil)
        let b = ToolCallResultEvent(messageId: "msg-123", toolCallId: "call-456", content: "Result", role: "tool", timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertEqual(a, b)
    }

    func test_toolCallResultEvent_equatable_differentMessageIds_areNotEqual() {
        // Given
        let a = ToolCallResultEvent(messageId: "msg-123", toolCallId: "call-456", content: "Result", timestamp: 1, rawEvent: nil)
        let b = ToolCallResultEvent(messageId: "msg-789", toolCallId: "call-456", content: "Result", timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_toolCallResultEvent_equatable_differentToolCallIds_areNotEqual() {
        // Given
        let a = ToolCallResultEvent(messageId: "msg-123", toolCallId: "call-456", content: "Result", timestamp: 1, rawEvent: nil)
        let b = ToolCallResultEvent(messageId: "msg-123", toolCallId: "call-789", content: "Result", timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_toolCallResultEvent_equatable_differentContent_areNotEqual() {
        // Given
        let a = ToolCallResultEvent(messageId: "msg-123", toolCallId: "call-456", content: "Result1", timestamp: 1, rawEvent: nil)
        let b = ToolCallResultEvent(messageId: "msg-123", toolCallId: "call-456", content: "Result2", timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_toolCallResultEvent_equatable_differentRoles_areNotEqual() {
        // Given
        let a = ToolCallResultEvent(messageId: "msg-123", toolCallId: "call-456", content: "Result", role: "tool", timestamp: 1, rawEvent: nil)
        let b = ToolCallResultEvent(messageId: "msg-123", toolCallId: "call-456", content: "Result", role: "assistant", timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_toolCallResultEvent_equatable_oneNilRole_areNotEqual() {
        // Given
        let a = ToolCallResultEvent(messageId: "msg-123", toolCallId: "call-456", content: "Result", role: "tool", timestamp: 1, rawEvent: nil)
        let b = ToolCallResultEvent(messageId: "msg-123", toolCallId: "call-456", content: "Result", role: nil, timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_toolCallResultEvent_equatable_bothNilRoles_areEqual() {
        // Given
        let a = ToolCallResultEvent(messageId: "msg-123", toolCallId: "call-456", content: "Result", role: nil, timestamp: 1, rawEvent: nil)
        let b = ToolCallResultEvent(messageId: "msg-123", toolCallId: "call-456", content: "Result", role: nil, timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertEqual(a, b)
    }

    func test_toolCallResultEvent_equatable_differentTimestamps_areNotEqual() {
        // Given
        let a = ToolCallResultEvent(messageId: "msg-123", toolCallId: "call-456", content: "Result", timestamp: 1, rawEvent: nil)
        let b = ToolCallResultEvent(messageId: "msg-123", toolCallId: "call-456", content: "Result", timestamp: 2, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_toolCallResultEvent_withEmptyContent_isValid() {
        // Given
        let event = ToolCallResultEvent(messageId: "msg-123", toolCallId: "call-456", content: "", timestamp: nil, rawEvent: nil)

        // Then
        XCTAssertEqual(event.content, "")
        XCTAssertEqual(event.eventType, .toolCallResult)
    }

    // MARK: - Helpers

    private func makeStrictDecoder(
        registry: [EventType: AGUIEventDecoder.DecodeHandler]? = nil
    ) -> AGUIEventDecoder {
        var config = AGUIEventDecoder.Configuration()
        config.unknownEventStrategy = .throwError
        return AGUIEventDecoder(
            config: config,
            makeDecoder: { JSONDecoder() },
            registry: registry ?? AGUIEventDecoder.defaultRegistry()
        )
    }

    private func makeTolerantDecoder(
        registry: [EventType: AGUIEventDecoder.DecodeHandler]? = nil
    ) -> AGUIEventDecoder {
        var config = AGUIEventDecoder.Configuration()
        config.unknownEventStrategy = .returnUnknown
        return AGUIEventDecoder(
            config: config,
            makeDecoder: { JSONDecoder() },
            registry: registry ?? AGUIEventDecoder.defaultRegistry()
        )
    }

    private func jsonData(_ json: String) -> Data {
        Data(json.utf8)
    }
}

