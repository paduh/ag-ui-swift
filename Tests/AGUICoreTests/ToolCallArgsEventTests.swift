import XCTest
@testable import AGUICore

final class ToolCallArgsEventTests: XCTestCase {

    // MARK: - Feature: Decode TOOL_CALL_ARGS

    func test_decodeValidToolCallArgs_returnsToolCallArgsEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_ARGS",
          "toolCallId": "call-123",
          "delta": "{\\"location\\": \\"San Francisco\\"}"
        }
        """)

        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        guard let toolCallArgs = event as? ToolCallArgsEvent else {
            return XCTFail("Expected ToolCallArgsEvent, got \(type(of: event))")
        }
        XCTAssertEqual(toolCallArgs.eventType, .toolCallArgs)
        XCTAssertEqual(toolCallArgs.toolCallId, "call-123")
        XCTAssertEqual(toolCallArgs.delta, "{\"location\": \"San Francisco\"}")
        XCTAssertNil(toolCallArgs.timestamp)
    }

    func test_decodeToolCallArgs_withTimestamp_populatesTimestamp() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_ARGS",
          "toolCallId": "call-123",
          "delta": "{\\"location\\": \\"San Francisco\\"}",
          "timestamp": 1704067200000
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let toolCallArgs = try XCTUnwrap(event as? ToolCallArgsEvent)
        XCTAssertEqual(toolCallArgs.timestamp, 1704067200000)
    }

    func test_decodeToolCallArgs_preservesRawEventBytes() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_ARGS",
          "toolCallId": "call-123",
          "delta": "{\\"location\\": \\"San Francisco\\"}",
          "timestamp": 1704067200000
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let toolCallArgs = try XCTUnwrap(event as? ToolCallArgsEvent)
        XCTAssertEqual(toolCallArgs.rawEvent, data)
    }

    func test_decodeToolCallArgs_ignoresUnknownExtraFields() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_ARGS",
          "toolCallId": "call-123",
          "delta": "{\\"location\\": \\"San Francisco\\"}",
          "extraField": "ignored",
          "nested": { "x": 1 }
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let toolCallArgs = try XCTUnwrap(event as? ToolCallArgsEvent)
        XCTAssertEqual(toolCallArgs.toolCallId, "call-123")
        XCTAssertEqual(toolCallArgs.delta, "{\"location\": \"San Francisco\"}")
    }

    func test_decodeToolCallArgs_withUnicodeDelta_handlesCorrectly() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_ARGS",
          "toolCallId": "call-123",
          "delta": "{\\"city\\": \\"北京\\"}"
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let toolCallArgs = try XCTUnwrap(event as? ToolCallArgsEvent)
        XCTAssertEqual(toolCallArgs.delta, "{\"city\": \"北京\"}")
    }

    func test_decodeToolCallArgs_withMultilineDelta_handlesCorrectly() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_ARGS",
          "toolCallId": "call-123",
          "delta": "{\\n  \\"key\\": \\"value\\"\\n}"
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let toolCallArgs = try XCTUnwrap(event as? ToolCallArgsEvent)
        XCTAssertEqual(toolCallArgs.delta, "{\n  \"key\": \"value\"\n}")
    }

    func test_decodeToolCallArgs_withEmptyDelta_allowsEmptyString() throws {
        // Given
        // Note: According to protocol, delta should be non-empty, but we allow it
        // for flexibility. Validation can be done at a higher level if needed.
        let data = jsonData("""
        {
          "type": "TOOL_CALL_ARGS",
          "toolCallId": "call-123",
          "delta": ""
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let toolCallArgs = try XCTUnwrap(event as? ToolCallArgsEvent)
        XCTAssertEqual(toolCallArgs.delta, "")
    }

    // MARK: - Feature: Error handling

    func test_decodeMissingType_throwsMissingTypeField() {
        // Given
        let data = jsonData("""
        {
          "toolCallId": "call-123",
          "delta": "{\\"location\\": \\"San Francisco\\"}"
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
          "toolCallId": "call-123",
          "delta": "{\\"location\\": \\"San Francisco\\"}"
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
          "toolCallId": "call-123",
          "delta": "{\\"location\\": \\"San Francisco\\"}"
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
          "type": "TOOL_CALL_ARGS",
          "toolCallId": "call-123",
          "delta": "{\\"location\\": \\"San Francisco\\"}"
        }
        """)

        // registry intentionally empty -> handler missing
        let decoder = makeStrictDecoder(registry: [:])

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            XCTAssertEqual(error as? EventDecodingError, .unsupportedEventType(.toolCallArgs))
        }
    }

    func test_decodeKnownTypeButNoHandler_inTolerantMode_returnsUnknownEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_ARGS",
          "toolCallId": "call-123",
          "delta": "{\\"location\\": \\"San Francisco\\"}"
        }
        """)
        let decoder = makeTolerantDecoder(registry: [:])

        // When
        let event = try decoder.decode(data)

        // Then
        let unknown = try XCTUnwrap(event as? UnknownEvent)
        XCTAssertEqual(unknown.typeRaw, "TOOL_CALL_ARGS")
        XCTAssertEqual(unknown.rawEvent, data)
    }

    func test_decodeToolCallArgs_missingToolCallId_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_ARGS",
          "delta": "{\\"location\\": \\"San Francisco\\"}"
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

    func test_decodeToolCallArgs_missingDelta_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_ARGS",
          "toolCallId": "call-123"
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            guard case .decodingFailed(let message) = error as? EventDecodingError else {
                return XCTFail("Expected decodingFailed, got \(error)")
            }
            XCTAssertTrue(message.contains("delta") || message.contains("Missing key"))
        }
    }

    func test_decodeToolCallArgs_wrongTypeForToolCallId_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_ARGS",
          "toolCallId": 123,
          "delta": "{\\"location\\": \\"San Francisco\\"}"
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

    func test_decodeToolCallArgs_wrongTypeForDelta_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_ARGS",
          "toolCallId": "call-123",
          "delta": 123
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            guard case .decodingFailed(let message) = error as? EventDecodingError else {
                return XCTFail("Expected decodingFailed, got \(error)")
            }
            XCTAssertTrue(message.contains("delta") || message.contains("Type mismatch"))
        }
    }

    func test_decodeToolCallArgs_wrongTypeForTimestamp_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_ARGS",
          "toolCallId": "call-123",
          "delta": "{\\"location\\": \\"San Francisco\\"}",
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

    func test_toolCallArgsEvent_eventTypeIsAlwaysToolCallArgs() {
        // Given
        let event = ToolCallArgsEvent(toolCallId: "call-123", delta: "{\"key\": \"value\"}", timestamp: nil, rawEvent: nil)

        // Then
        XCTAssertEqual(event.eventType, .toolCallArgs)
    }

    func test_toolCallArgsEvent_equatable_sameFields_areEqual() {
        // Given
        let a = ToolCallArgsEvent(toolCallId: "call-123", delta: "{\"key\": \"value\"}", timestamp: 1, rawEvent: nil)
        let b = ToolCallArgsEvent(toolCallId: "call-123", delta: "{\"key\": \"value\"}", timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertEqual(a, b)
    }

    func test_toolCallArgsEvent_equatable_differentToolCallIds_areNotEqual() {
        // Given
        let a = ToolCallArgsEvent(toolCallId: "call-123", delta: "{\"key\": \"value\"}", timestamp: 1, rawEvent: nil)
        let b = ToolCallArgsEvent(toolCallId: "call-456", delta: "{\"key\": \"value\"}", timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_toolCallArgsEvent_equatable_differentDeltas_areNotEqual() {
        // Given
        let a = ToolCallArgsEvent(toolCallId: "call-123", delta: "{\"key\": \"value1\"}", timestamp: 1, rawEvent: nil)
        let b = ToolCallArgsEvent(toolCallId: "call-123", delta: "{\"key\": \"value2\"}", timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_toolCallArgsEvent_equatable_differentTimestamps_areNotEqual() {
        // Given
        let a = ToolCallArgsEvent(toolCallId: "call-123", delta: "{\"key\": \"value\"}", timestamp: 1, rawEvent: nil)
        let b = ToolCallArgsEvent(toolCallId: "call-123", delta: "{\"key\": \"value\"}", timestamp: 2, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_toolCallArgsEvent_withEmptyDelta_isValid() {
        // Given
        // Note: Protocol says delta should be non-empty, but we allow it for flexibility
        let event = ToolCallArgsEvent(toolCallId: "call-123", delta: "", timestamp: nil, rawEvent: nil)

        // Then
        XCTAssertEqual(event.delta, "")
        XCTAssertEqual(event.eventType, .toolCallArgs)
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

