import XCTest
@testable import AGUICore

final class TextMessageStartEventTests: XCTestCase {

    // MARK: - Feature: Decode TEXT_MESSAGE_START

    func test_decodeValidTextMessageStart_returnsTextMessageStartEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_START",
          "messageId": "msg-123",
          "role": "assistant"
        }
        """)

        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        guard let textMessageStart = event as? TextMessageStartEvent else {
            return XCTFail("Expected TextMessageStartEvent, got \(type(of: event))")
        }
        XCTAssertEqual(textMessageStart.eventType, .textMessageStart)
        XCTAssertEqual(textMessageStart.messageId, "msg-123")
        XCTAssertEqual(textMessageStart.role, "assistant")
        XCTAssertNil(textMessageStart.timestamp)
    }

    func test_decodeTextMessageStart_withTimestamp_populatesTimestamp() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_START",
          "messageId": "msg-123",
          "role": "assistant",
          "timestamp": 1704067200000
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let textMessageStart = try XCTUnwrap(event as? TextMessageStartEvent)
        XCTAssertEqual(textMessageStart.timestamp, 1704067200000)
    }

    func test_decodeTextMessageStart_preservesRawEventBytes() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_START",
          "messageId": "msg-123",
          "role": "assistant",
          "timestamp": 1704067200000
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let textMessageStart = try XCTUnwrap(event as? TextMessageStartEvent)
        XCTAssertEqual(textMessageStart.rawEvent, data)
    }

    func test_decodeTextMessageStart_ignoresUnknownExtraFields() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_START",
          "messageId": "msg-123",
          "role": "assistant",
          "extraField": "ignored",
          "nested": { "x": 1 }
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let textMessageStart = try XCTUnwrap(event as? TextMessageStartEvent)
        XCTAssertEqual(textMessageStart.messageId, "msg-123")
        XCTAssertEqual(textMessageStart.role, "assistant")
    }

    func test_decodeTextMessageStart_withUnicodeMessageId_handlesCorrectly() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_START",
          "messageId": "msg-🚀-123",
          "role": "assistant"
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let textMessageStart = try XCTUnwrap(event as? TextMessageStartEvent)
        XCTAssertEqual(textMessageStart.messageId, "msg-🚀-123")
    }

    // MARK: - Feature: Error handling

    func test_decodeMissingType_throwsMissingTypeField() {
        // Given
        let data = jsonData("""
        {
          "messageId": "msg-123",
          "role": "assistant"
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
          "type": "TEXT_MESSAGE_PAUSED",
          "messageId": "msg-123",
          "role": "assistant"
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            guard case .unknownEventType(let type) = error as? EventDecodingError else {
                return XCTFail("Expected unknownEventType, got \(error)")
            }
            XCTAssertEqual(type, "TEXT_MESSAGE_PAUSED")
        }
    }

    func test_decodeUnknownType_inTolerantMode_returnsUnknownEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_PAUSED",
          "messageId": "msg-123",
          "role": "assistant"
        }
        """)
        let decoder = makeTolerantDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let unknown = try XCTUnwrap(event as? UnknownEvent)
        XCTAssertEqual(unknown.typeRaw, "TEXT_MESSAGE_PAUSED")
        XCTAssertEqual(unknown.rawEvent, data)
    }

    func test_decodeKnownTypeButNoHandler_inStrictMode_throwsUnsupportedEventType() {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_START",
          "messageId": "msg-123",
          "role": "assistant"
        }
        """)

        // registry intentionally empty -> handler missing
        let decoder = makeStrictDecoder(registry: [:])

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            XCTAssertEqual(error as? EventDecodingError, .unsupportedEventType(.textMessageStart))
        }
    }

    func test_decodeKnownTypeButNoHandler_inTolerantMode_returnsUnknownEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_START",
          "messageId": "msg-123",
          "role": "assistant"
        }
        """)
        let decoder = makeTolerantDecoder(registry: [:])

        // When
        let event = try decoder.decode(data)

        // Then
        let unknown = try XCTUnwrap(event as? UnknownEvent)
        XCTAssertEqual(unknown.typeRaw, "TEXT_MESSAGE_START")
        XCTAssertEqual(unknown.rawEvent, data)
    }

    func test_decodeTextMessageStart_missingMessageId_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_START",
          "role": "assistant"
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

    func test_decodeTextMessageStart_missingRole_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_START",
          "messageId": "msg-123"
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            guard case .decodingFailed(let message) = error as? EventDecodingError else {
                return XCTFail("Expected decodingFailed, got \(error)")
            }
            XCTAssertTrue(message.contains("role") || message.contains("Missing key"))
        }
    }

    func test_decodeTextMessageStart_wrongTypeForMessageId_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_START",
          "messageId": 123,
          "role": "assistant"
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

    func test_decodeTextMessageStart_wrongTypeForRole_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_START",
          "messageId": "msg-123",
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

    func test_decodeTextMessageStart_wrongTypeForTimestamp_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_START",
          "messageId": "msg-123",
          "role": "assistant",
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

    func test_textMessageStartEvent_eventTypeIsAlwaysTextMessageStart() {
        // Given
        let event = TextMessageStartEvent(messageId: "msg-123", role: "assistant", timestamp: nil, rawEvent: nil)

        // Then
        XCTAssertEqual(event.eventType, .textMessageStart)
    }

    func test_textMessageStartEvent_equatable_sameFields_areEqual() {
        // Given
        let a = TextMessageStartEvent(messageId: "msg-123", role: "assistant", timestamp: 1, rawEvent: nil)
        let b = TextMessageStartEvent(messageId: "msg-123", role: "assistant", timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertEqual(a, b)
    }

    func test_textMessageStartEvent_equatable_differentMessageIds_areNotEqual() {
        // Given
        let a = TextMessageStartEvent(messageId: "msg-123", role: "assistant", timestamp: 1, rawEvent: nil)
        let b = TextMessageStartEvent(messageId: "msg-456", role: "assistant", timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_textMessageStartEvent_equatable_differentRoles_areNotEqual() {
        // Given
        let a = TextMessageStartEvent(messageId: "msg-123", role: "assistant", timestamp: 1, rawEvent: nil)
        let b = TextMessageStartEvent(messageId: "msg-123", role: "user", timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_textMessageStartEvent_equatable_differentTimestamps_areNotEqual() {
        // Given
        let a = TextMessageStartEvent(messageId: "msg-123", role: "assistant", timestamp: 1, rawEvent: nil)
        let b = TextMessageStartEvent(messageId: "msg-123", role: "assistant", timestamp: 2, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_textMessageStartEvent_withEmptyMessageId_isValid() {
        // Given
        let event = TextMessageStartEvent(messageId: "", role: "assistant", timestamp: nil, rawEvent: nil)

        // Then
        XCTAssertEqual(event.messageId, "")
        XCTAssertEqual(event.eventType, .textMessageStart)
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

