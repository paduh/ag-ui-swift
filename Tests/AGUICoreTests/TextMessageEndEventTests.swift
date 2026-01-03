import XCTest
@testable import AGUICore

final class TextMessageEndEventTests: XCTestCase {

    // MARK: - Feature: Decode TEXT_MESSAGE_END

    func test_decodeValidTextMessageEnd_returnsTextMessageEndEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_END",
          "messageId": "msg-123"
        }
        """)

        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        guard let textMessageEnd = event as? TextMessageEndEvent else {
            return XCTFail("Expected TextMessageEndEvent, got \(type(of: event))")
        }
        XCTAssertEqual(textMessageEnd.eventType, .textMessageEnd)
        XCTAssertEqual(textMessageEnd.messageId, "msg-123")
        XCTAssertNil(textMessageEnd.timestamp)
    }

    func test_decodeTextMessageEnd_withTimestamp_populatesTimestamp() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_END",
          "messageId": "msg-123",
          "timestamp": 1704067200000
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let textMessageEnd = try XCTUnwrap(event as? TextMessageEndEvent)
        XCTAssertEqual(textMessageEnd.timestamp, 1704067200000)
    }

    func test_decodeTextMessageEnd_preservesRawEventBytes() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_END",
          "messageId": "msg-123",
          "timestamp": 1704067200000
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let textMessageEnd = try XCTUnwrap(event as? TextMessageEndEvent)
        XCTAssertEqual(textMessageEnd.rawEvent, data)
    }

    func test_decodeTextMessageEnd_ignoresUnknownExtraFields() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_END",
          "messageId": "msg-123",
          "extraField": "ignored",
          "nested": { "x": 1 }
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let textMessageEnd = try XCTUnwrap(event as? TextMessageEndEvent)
        XCTAssertEqual(textMessageEnd.messageId, "msg-123")
    }

    func test_decodeTextMessageEnd_withUnicodeMessageId_handlesCorrectly() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_END",
          "messageId": "msg-🚀-123"
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let textMessageEnd = try XCTUnwrap(event as? TextMessageEndEvent)
        XCTAssertEqual(textMessageEnd.messageId, "msg-🚀-123")
    }

    // MARK: - Feature: Error handling

    func test_decodeMissingType_throwsMissingTypeField() {
        // Given
        let data = jsonData("""
        {
          "messageId": "msg-123"
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
          "messageId": "msg-123"
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
          "messageId": "msg-123"
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
          "type": "TEXT_MESSAGE_END",
          "messageId": "msg-123"
        }
        """)

        // registry intentionally empty -> handler missing
        let decoder = makeStrictDecoder(registry: [:])

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            XCTAssertEqual(error as? EventDecodingError, .unsupportedEventType(.textMessageEnd))
        }
    }

    func test_decodeKnownTypeButNoHandler_inTolerantMode_returnsUnknownEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_END",
          "messageId": "msg-123"
        }
        """)
        let decoder = makeTolerantDecoder(registry: [:])

        // When
        let event = try decoder.decode(data)

        // Then
        let unknown = try XCTUnwrap(event as? UnknownEvent)
        XCTAssertEqual(unknown.typeRaw, "TEXT_MESSAGE_END")
        XCTAssertEqual(unknown.rawEvent, data)
    }

    func test_decodeTextMessageEnd_missingMessageId_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_END"
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

    func test_decodeTextMessageEnd_wrongTypeForMessageId_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_END",
          "messageId": 123
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

    func test_decodeTextMessageEnd_wrongTypeForTimestamp_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_END",
          "messageId": "msg-123",
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

    func test_textMessageEndEvent_eventTypeIsAlwaysTextMessageEnd() {
        // Given
        let event = TextMessageEndEvent(messageId: "msg-123", timestamp: nil, rawEvent: nil)

        // Then
        XCTAssertEqual(event.eventType, .textMessageEnd)
    }

    func test_textMessageEndEvent_equatable_sameFields_areEqual() {
        // Given
        let a = TextMessageEndEvent(messageId: "msg-123", timestamp: 1, rawEvent: nil)
        let b = TextMessageEndEvent(messageId: "msg-123", timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertEqual(a, b)
    }

    func test_textMessageEndEvent_equatable_differentMessageIds_areNotEqual() {
        // Given
        let a = TextMessageEndEvent(messageId: "msg-123", timestamp: 1, rawEvent: nil)
        let b = TextMessageEndEvent(messageId: "msg-456", timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_textMessageEndEvent_equatable_differentTimestamps_areNotEqual() {
        // Given
        let a = TextMessageEndEvent(messageId: "msg-123", timestamp: 1, rawEvent: nil)
        let b = TextMessageEndEvent(messageId: "msg-123", timestamp: 2, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_textMessageEndEvent_equatable_oneNilTimestamp_areNotEqual() {
        // Given
        let a = TextMessageEndEvent(messageId: "msg-123", timestamp: 1, rawEvent: nil)
        let b = TextMessageEndEvent(messageId: "msg-123", timestamp: nil, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_textMessageEndEvent_equatable_bothNilTimestamps_areEqual() {
        // Given
        let a = TextMessageEndEvent(messageId: "msg-123", timestamp: nil, rawEvent: nil)
        let b = TextMessageEndEvent(messageId: "msg-123", timestamp: nil, rawEvent: nil)

        // Then
        XCTAssertEqual(a, b)
    }

    func test_textMessageEndEvent_withEmptyMessageId_isValid() {
        // Given
        let event = TextMessageEndEvent(messageId: "", timestamp: nil, rawEvent: nil)

        // Then
        XCTAssertEqual(event.messageId, "")
        XCTAssertEqual(event.eventType, .textMessageEnd)
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

