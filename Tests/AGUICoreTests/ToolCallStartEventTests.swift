import XCTest
@testable import AGUICore

final class ToolCallStartEventTests: XCTestCase {

    // MARK: - Feature: Decode TOOL_CALL_START

    func test_decodeValidToolCallStart_returnsToolCallStartEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_START",
          "toolCallId": "call-123",
          "toolCallName": "get_weather"
        }
        """)

        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        guard let toolCallStart = event as? ToolCallStartEvent else {
            return XCTFail("Expected ToolCallStartEvent, got \(type(of: event))")
        }
        XCTAssertEqual(toolCallStart.eventType, .toolCallStart)
        XCTAssertEqual(toolCallStart.toolCallId, "call-123")
        XCTAssertEqual(toolCallStart.toolCallName, "get_weather")
        XCTAssertNil(toolCallStart.parentMessageId)
        XCTAssertNil(toolCallStart.timestamp)
    }

    func test_decodeToolCallStart_withParentMessageId_populatesParentMessageId() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_START",
          "toolCallId": "call-123",
          "toolCallName": "get_weather",
          "parentMessageId": "msg-456"
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let toolCallStart = try XCTUnwrap(event as? ToolCallStartEvent)
        XCTAssertEqual(toolCallStart.parentMessageId, "msg-456")
    }

    func test_decodeToolCallStart_withTimestamp_populatesTimestamp() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_START",
          "toolCallId": "call-123",
          "toolCallName": "get_weather",
          "timestamp": 1704067200000
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let toolCallStart = try XCTUnwrap(event as? ToolCallStartEvent)
        XCTAssertEqual(toolCallStart.timestamp, 1704067200000)
    }

    func test_decodeToolCallStart_preservesRawEventBytes() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_START",
          "toolCallId": "call-123",
          "toolCallName": "get_weather",
          "timestamp": 1704067200000
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let toolCallStart = try XCTUnwrap(event as? ToolCallStartEvent)
        XCTAssertEqual(toolCallStart.rawEvent, data)
    }

    func test_decodeToolCallStart_ignoresUnknownExtraFields() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_START",
          "toolCallId": "call-123",
          "toolCallName": "get_weather",
          "extraField": "ignored",
          "nested": { "x": 1 }
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let toolCallStart = try XCTUnwrap(event as? ToolCallStartEvent)
        XCTAssertEqual(toolCallStart.toolCallId, "call-123")
        XCTAssertEqual(toolCallStart.toolCallName, "get_weather")
    }

    func test_decodeToolCallStart_withUnicodeToolCallId_handlesCorrectly() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_START",
          "toolCallId": "call-🚀-123",
          "toolCallName": "get_weather"
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let toolCallStart = try XCTUnwrap(event as? ToolCallStartEvent)
        XCTAssertEqual(toolCallStart.toolCallId, "call-🚀-123")
    }

    func test_decodeToolCallStart_withUnicodeToolCallName_handlesCorrectly() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_START",
          "toolCallId": "call-123",
          "toolCallName": "get_天气"
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let toolCallStart = try XCTUnwrap(event as? ToolCallStartEvent)
        XCTAssertEqual(toolCallStart.toolCallName, "get_天气")
    }

    // MARK: - Feature: Error handling

    func test_decodeMissingType_throwsMissingTypeField() {
        // Given
        let data = jsonData("""
        {
          "toolCallId": "call-123",
          "toolCallName": "get_weather"
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
          "toolCallName": "get_weather"
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
          "toolCallName": "get_weather"
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
          "type": "TOOL_CALL_START",
          "toolCallId": "call-123",
          "toolCallName": "get_weather"
        }
        """)

        // registry intentionally empty -> handler missing
        let decoder = makeStrictDecoder(registry: [:])

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            XCTAssertEqual(error as? EventDecodingError, .unsupportedEventType(.toolCallStart))
        }
    }

    func test_decodeKnownTypeButNoHandler_inTolerantMode_returnsUnknownEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_START",
          "toolCallId": "call-123",
          "toolCallName": "get_weather"
        }
        """)
        let decoder = makeTolerantDecoder(registry: [:])

        // When
        let event = try decoder.decode(data)

        // Then
        let unknown = try XCTUnwrap(event as? UnknownEvent)
        XCTAssertEqual(unknown.typeRaw, "TOOL_CALL_START")
        XCTAssertEqual(unknown.rawEvent, data)
    }

    func test_decodeToolCallStart_missingToolCallId_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_START",
          "toolCallName": "get_weather"
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

    func test_decodeToolCallStart_missingToolCallName_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_START",
          "toolCallId": "call-123"
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            guard case .decodingFailed(let message) = error as? EventDecodingError else {
                return XCTFail("Expected decodingFailed, got \(error)")
            }
            XCTAssertTrue(message.contains("toolCallName") || message.contains("Missing key"))
        }
    }

    func test_decodeToolCallStart_wrongTypeForToolCallId_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_START",
          "toolCallId": 123,
          "toolCallName": "get_weather"
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

    func test_decodeToolCallStart_wrongTypeForToolCallName_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_START",
          "toolCallId": "call-123",
          "toolCallName": 123
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            guard case .decodingFailed(let message) = error as? EventDecodingError else {
                return XCTFail("Expected decodingFailed, got \(error)")
            }
            XCTAssertTrue(message.contains("toolCallName") || message.contains("Type mismatch"))
        }
    }

    func test_decodeToolCallStart_wrongTypeForParentMessageId_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_START",
          "toolCallId": "call-123",
          "toolCallName": "get_weather",
          "parentMessageId": 123
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            guard case .decodingFailed(let message) = error as? EventDecodingError else {
                return XCTFail("Expected decodingFailed, got \(error)")
            }
            XCTAssertTrue(message.contains("parentMessageId") || message.contains("Type mismatch"))
        }
    }

    func test_decodeToolCallStart_wrongTypeForTimestamp_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TOOL_CALL_START",
          "toolCallId": "call-123",
          "toolCallName": "get_weather",
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

    func test_toolCallStartEvent_eventTypeIsAlwaysToolCallStart() {
        // Given
        let event = ToolCallStartEvent(toolCallId: "call-123", toolCallName: "get_weather", parentMessageId: nil, timestamp: nil, rawEvent: nil)

        // Then
        XCTAssertEqual(event.eventType, .toolCallStart)
    }

    func test_toolCallStartEvent_equatable_sameFields_areEqual() {
        // Given
        let a = ToolCallStartEvent(toolCallId: "call-123", toolCallName: "get_weather", parentMessageId: "msg-456", timestamp: 1, rawEvent: nil)
        let b = ToolCallStartEvent(toolCallId: "call-123", toolCallName: "get_weather", parentMessageId: "msg-456", timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertEqual(a, b)
    }

    func test_toolCallStartEvent_equatable_differentToolCallIds_areNotEqual() {
        // Given
        let a = ToolCallStartEvent(toolCallId: "call-123", toolCallName: "get_weather", parentMessageId: nil, timestamp: 1, rawEvent: nil)
        let b = ToolCallStartEvent(toolCallId: "call-456", toolCallName: "get_weather", parentMessageId: nil, timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_toolCallStartEvent_equatable_differentToolCallNames_areNotEqual() {
        // Given
        let a = ToolCallStartEvent(toolCallId: "call-123", toolCallName: "get_weather", parentMessageId: nil, timestamp: 1, rawEvent: nil)
        let b = ToolCallStartEvent(toolCallId: "call-123", toolCallName: "get_time", parentMessageId: nil, timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_toolCallStartEvent_equatable_differentParentMessageIds_areNotEqual() {
        // Given
        let a = ToolCallStartEvent(toolCallId: "call-123", toolCallName: "get_weather", parentMessageId: "msg-456", timestamp: 1, rawEvent: nil)
        let b = ToolCallStartEvent(toolCallId: "call-123", toolCallName: "get_weather", parentMessageId: "msg-789", timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_toolCallStartEvent_equatable_oneNilParentMessageId_areNotEqual() {
        // Given
        let a = ToolCallStartEvent(toolCallId: "call-123", toolCallName: "get_weather", parentMessageId: "msg-456", timestamp: 1, rawEvent: nil)
        let b = ToolCallStartEvent(toolCallId: "call-123", toolCallName: "get_weather", parentMessageId: nil, timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_toolCallStartEvent_equatable_bothNilParentMessageIds_areEqual() {
        // Given
        let a = ToolCallStartEvent(toolCallId: "call-123", toolCallName: "get_weather", parentMessageId: nil, timestamp: 1, rawEvent: nil)
        let b = ToolCallStartEvent(toolCallId: "call-123", toolCallName: "get_weather", parentMessageId: nil, timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertEqual(a, b)
    }

    func test_toolCallStartEvent_equatable_differentTimestamps_areNotEqual() {
        // Given
        let a = ToolCallStartEvent(toolCallId: "call-123", toolCallName: "get_weather", parentMessageId: nil, timestamp: 1, rawEvent: nil)
        let b = ToolCallStartEvent(toolCallId: "call-123", toolCallName: "get_weather", parentMessageId: nil, timestamp: 2, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_toolCallStartEvent_withEmptyToolCallId_isValid() {
        // Given
        let event = ToolCallStartEvent(toolCallId: "", toolCallName: "get_weather", parentMessageId: nil, timestamp: nil, rawEvent: nil)

        // Then
        XCTAssertEqual(event.toolCallId, "")
        XCTAssertEqual(event.eventType, .toolCallStart)
    }

    func test_toolCallStartEvent_withEmptyToolCallName_isValid() {
        // Given
        let event = ToolCallStartEvent(toolCallId: "call-123", toolCallName: "", parentMessageId: nil, timestamp: nil, rawEvent: nil)

        // Then
        XCTAssertEqual(event.toolCallName, "")
        XCTAssertEqual(event.eventType, .toolCallStart)
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
