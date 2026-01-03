import XCTest
@testable import AGUICore

final class ToolCallEndEventTests: XCTestCase {

    // MARK: - Feature: Decode TOOL_CALL_END

    func test_decodeValidToolCallEnd_returnsToolCallEndEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_END",
          "toolCallId": "call-123"
        }
        """)

        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        guard let toolCallEnd = event as? ToolCallEndEvent else {
            return XCTFail("Expected ToolCallEndEvent, got \(type(of: event))")
        }
        XCTAssertEqual(toolCallEnd.eventType, .toolCallEnd)
        XCTAssertEqual(toolCallEnd.toolCallId, "call-123")
        XCTAssertNil(toolCallEnd.timestamp)
    }

    func test_decodeToolCallEnd_withTimestamp_populatesTimestamp() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_END",
          "toolCallId": "call-123",
          "timestamp": 1704067200000
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let toolCallEnd = try XCTUnwrap(event as? ToolCallEndEvent)
        XCTAssertEqual(toolCallEnd.timestamp, 1704067200000)
    }

    func test_decodeToolCallEnd_preservesRawEventBytes() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_END",
          "toolCallId": "call-123",
          "timestamp": 1704067200000
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let toolCallEnd = try XCTUnwrap(event as? ToolCallEndEvent)
        XCTAssertEqual(toolCallEnd.rawEvent, data)
    }

    func test_decodeToolCallEnd_ignoresUnknownExtraFields() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_END",
          "toolCallId": "call-123",
          "extraField": "ignored",
          "nested": { "x": 1 }
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let toolCallEnd = try XCTUnwrap(event as? ToolCallEndEvent)
        XCTAssertEqual(toolCallEnd.toolCallId, "call-123")
    }

    func test_decodeToolCallEnd_withUnicodeToolCallId_handlesCorrectly() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_END",
          "toolCallId": "call-🚀-123"
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let toolCallEnd = try XCTUnwrap(event as? ToolCallEndEvent)
        XCTAssertEqual(toolCallEnd.toolCallId, "call-🚀-123")
    }

    // MARK: - Feature: Error handling

    func test_decodeMissingType_throwsMissingTypeField() {
        // Given
        let data = jsonData("""
        {
          "toolCallId": "call-123"
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
          "toolCallId": "call-123"
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
          "toolCallId": "call-123"
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
          "type": "TOOL_CALL_END",
          "toolCallId": "call-123"
        }
        """)

        // registry intentionally empty -> handler missing
        let decoder = makeStrictDecoder(registry: [:])

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            XCTAssertEqual(error as? EventDecodingError, .unsupportedEventType(.toolCallEnd))
        }
    }

    func test_decodeKnownTypeButNoHandler_inTolerantMode_returnsUnknownEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_END",
          "toolCallId": "call-123"
        }
        """)
        let decoder = makeTolerantDecoder(registry: [:])

        // When
        let event = try decoder.decode(data)

        // Then
        let unknown = try XCTUnwrap(event as? UnknownEvent)
        XCTAssertEqual(unknown.typeRaw, "TOOL_CALL_END")
        XCTAssertEqual(unknown.rawEvent, data)
    }

    func test_decodeToolCallEnd_missingToolCallId_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_END"
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

    func test_decodeToolCallEnd_wrongTypeForToolCallId_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_END",
          "toolCallId": 123
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

    func test_decodeToolCallEnd_wrongTypeForTimestamp_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_END",
          "toolCallId": "call-123",
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

    func test_toolCallEndEvent_eventTypeIsAlwaysToolCallEnd() {
        // Given
        let event = ToolCallEndEvent(toolCallId: "call-123", timestamp: nil, rawEvent: nil)

        // Then
        XCTAssertEqual(event.eventType, .toolCallEnd)
    }

    func test_toolCallEndEvent_equatable_sameFields_areEqual() {
        // Given
        let a = ToolCallEndEvent(toolCallId: "call-123", timestamp: 1, rawEvent: nil)
        let b = ToolCallEndEvent(toolCallId: "call-123", timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertEqual(a, b)
    }

    func test_toolCallEndEvent_equatable_differentToolCallIds_areNotEqual() {
        // Given
        let a = ToolCallEndEvent(toolCallId: "call-123", timestamp: 1, rawEvent: nil)
        let b = ToolCallEndEvent(toolCallId: "call-456", timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_toolCallEndEvent_equatable_differentTimestamps_areNotEqual() {
        // Given
        let a = ToolCallEndEvent(toolCallId: "call-123", timestamp: 1, rawEvent: nil)
        let b = ToolCallEndEvent(toolCallId: "call-123", timestamp: 2, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_toolCallEndEvent_equatable_oneNilTimestamp_areNotEqual() {
        // Given
        let a = ToolCallEndEvent(toolCallId: "call-123", timestamp: 1, rawEvent: nil)
        let b = ToolCallEndEvent(toolCallId: "call-123", timestamp: nil, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_toolCallEndEvent_equatable_bothNilTimestamps_areEqual() {
        // Given
        let a = ToolCallEndEvent(toolCallId: "call-123", timestamp: nil, rawEvent: nil)
        let b = ToolCallEndEvent(toolCallId: "call-123", timestamp: nil, rawEvent: nil)

        // Then
        XCTAssertEqual(a, b)
    }

    func test_toolCallEndEvent_withEmptyToolCallId_isValid() {
        // Given
        let event = ToolCallEndEvent(toolCallId: "", timestamp: nil, rawEvent: nil)

        // Then
        XCTAssertEqual(event.toolCallId, "")
        XCTAssertEqual(event.eventType, .toolCallEnd)
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
            registry: registry ?? AGUIEventDecoder.defaultRegistryForTests
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
            registry: registry ?? AGUIEventDecoder.defaultRegistryForTests
        )
    }

    private func jsonData(_ json: String) -> Data {
        Data(json.utf8)
    }
}

