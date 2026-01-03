import XCTest
@testable import AGUICore

final class TextMessageContentEventTests: XCTestCase {

    // MARK: - Feature: Decode TEXT_MESSAGE_CONTENT

    func test_decodeValidTextMessageContent_returnsTextMessageContentEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_CONTENT",
          "messageId": "msg-123",
          "delta": "Hello, world!"
        }
        """)

        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        guard let textMessageContent = event as? TextMessageContentEvent else {
            return XCTFail("Expected TextMessageContentEvent, got \(type(of: event))")
        }
        XCTAssertEqual(textMessageContent.eventType, .textMessageContent)
        XCTAssertEqual(textMessageContent.messageId, "msg-123")
        XCTAssertEqual(textMessageContent.delta, "Hello, world!")
        XCTAssertNil(textMessageContent.timestamp)
    }

    func test_decodeTextMessageContent_withTimestamp_populatesTimestamp() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_CONTENT",
          "messageId": "msg-123",
          "delta": "Hello, world!",
          "timestamp": 1704067200000
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let textMessageContent = try XCTUnwrap(event as? TextMessageContentEvent)
        XCTAssertEqual(textMessageContent.timestamp, 1704067200000)
    }

    func test_decodeTextMessageContent_preservesRawEventBytes() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_CONTENT",
          "messageId": "msg-123",
          "delta": "Hello, world!",
          "timestamp": 1704067200000
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let textMessageContent = try XCTUnwrap(event as? TextMessageContentEvent)
        XCTAssertEqual(textMessageContent.rawEvent, data)
    }

    func test_decodeTextMessageContent_ignoresUnknownExtraFields() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_CONTENT",
          "messageId": "msg-123",
          "delta": "Hello, world!",
          "extraField": "ignored",
          "nested": { "x": 1 }
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let textMessageContent = try XCTUnwrap(event as? TextMessageContentEvent)
        XCTAssertEqual(textMessageContent.messageId, "msg-123")
        XCTAssertEqual(textMessageContent.delta, "Hello, world!")
    }

    func test_decodeTextMessageContent_withUnicodeDelta_handlesCorrectly() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_CONTENT",
          "messageId": "msg-123",
          "delta": "Hello, 🌍! 你好"
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let textMessageContent = try XCTUnwrap(event as? TextMessageContentEvent)
        XCTAssertEqual(textMessageContent.delta, "Hello, 🌍! 你好")
    }

    func test_decodeTextMessageContent_withMultilineDelta_handlesCorrectly() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_CONTENT",
          "messageId": "msg-123",
          "delta": "Line 1\\nLine 2\\nLine 3"
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let textMessageContent = try XCTUnwrap(event as? TextMessageContentEvent)
        XCTAssertEqual(textMessageContent.delta, "Line 1\nLine 2\nLine 3")
    }

    func test_decodeTextMessageContent_withEmptyDelta_allowsEmptyString() throws {
        // Given
        // Note: According to protocol, delta should be non-empty, but we allow it
        // for flexibility. Validation can be done at a higher level if needed.
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_CONTENT",
          "messageId": "msg-123",
          "delta": ""
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let textMessageContent = try XCTUnwrap(event as? TextMessageContentEvent)
        XCTAssertEqual(textMessageContent.delta, "")
    }

    // MARK: - Feature: Error handling

    func test_decodeMissingType_throwsMissingTypeField() {
        // Given
        let data = jsonData("""
        {
          "messageId": "msg-123",
          "delta": "Hello, world!"
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
          "delta": "Hello, world!"
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
          "delta": "Hello, world!"
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
          "type": "TEXT_MESSAGE_CONTENT",
          "messageId": "msg-123",
          "delta": "Hello, world!"
        }
        """)

        // registry intentionally empty -> handler missing
        let decoder = makeStrictDecoder(registry: [:])

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            XCTAssertEqual(error as? EventDecodingError, .unsupportedEventType(.textMessageContent))
        }
    }

    func test_decodeKnownTypeButNoHandler_inTolerantMode_returnsUnknownEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_CONTENT",
          "messageId": "msg-123",
          "delta": "Hello, world!"
        }
        """)
        let decoder = makeTolerantDecoder(registry: [:])

        // When
        let event = try decoder.decode(data)

        // Then
        let unknown = try XCTUnwrap(event as? UnknownEvent)
        XCTAssertEqual(unknown.typeRaw, "TEXT_MESSAGE_CONTENT")
        XCTAssertEqual(unknown.rawEvent, data)
    }

    func test_decodeTextMessageContent_missingMessageId_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_CONTENT",
          "delta": "Hello, world!"
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

    func test_decodeTextMessageContent_missingDelta_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_CONTENT",
          "messageId": "msg-123"
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

    func test_decodeTextMessageContent_wrongTypeForMessageId_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_CONTENT",
          "messageId": 123,
          "delta": "Hello, world!"
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

    func test_decodeTextMessageContent_wrongTypeForDelta_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_CONTENT",
          "messageId": "msg-123",
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

    func test_decodeTextMessageContent_wrongTypeForTimestamp_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "TEXT_MESSAGE_CONTENT",
          "messageId": "msg-123",
          "delta": "Hello, world!",
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

    func test_textMessageContentEvent_eventTypeIsAlwaysTextMessageContent() {
        // Given
        let event = TextMessageContentEvent(messageId: "msg-123", delta: "Hello", timestamp: nil, rawEvent: nil)

        // Then
        XCTAssertEqual(event.eventType, .textMessageContent)
    }

    func test_textMessageContentEvent_equatable_sameFields_areEqual() {
        // Given
        let a = TextMessageContentEvent(messageId: "msg-123", delta: "Hello", timestamp: 1, rawEvent: nil)
        let b = TextMessageContentEvent(messageId: "msg-123", delta: "Hello", timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertEqual(a, b)
    }

    func test_textMessageContentEvent_equatable_differentMessageIds_areNotEqual() {
        // Given
        let a = TextMessageContentEvent(messageId: "msg-123", delta: "Hello", timestamp: 1, rawEvent: nil)
        let b = TextMessageContentEvent(messageId: "msg-456", delta: "Hello", timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_textMessageContentEvent_equatable_differentDeltas_areNotEqual() {
        // Given
        let a = TextMessageContentEvent(messageId: "msg-123", delta: "Hello", timestamp: 1, rawEvent: nil)
        let b = TextMessageContentEvent(messageId: "msg-123", delta: "World", timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_textMessageContentEvent_equatable_differentTimestamps_areNotEqual() {
        // Given
        let a = TextMessageContentEvent(messageId: "msg-123", delta: "Hello", timestamp: 1, rawEvent: nil)
        let b = TextMessageContentEvent(messageId: "msg-123", delta: "Hello", timestamp: 2, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_textMessageContentEvent_withEmptyDelta_isValid() {
        // Given
        // Note: Protocol says delta should be non-empty, but we allow it for flexibility
        let event = TextMessageContentEvent(messageId: "msg-123", delta: "", timestamp: nil, rawEvent: nil)

        // Then
        XCTAssertEqual(event.delta, "")
        XCTAssertEqual(event.eventType, .textMessageContent)
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

