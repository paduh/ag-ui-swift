import XCTest
@testable import AGUICore

final class ThinkingTextMessageContentEventTests: XCTestCase,
                                                    AGUIEventDecoderTestHelpers,
                                                    EventDecodingErrorTests {

    // MARK: - EventDecodingErrorTests Protocol Requirements

    var validEventFieldsWithoutType: [String: Any] {
        ["delta": "Analyzing the problem..."]
    }

    var eventTypeString: String { "THINKING_TEXT_MESSAGE_CONTENT" }
    var expectedEventType: EventType { .thinkingTextMessageContent }
    var unknownEventTypeString: String { "THINKING_TEXT_MESSAGE_CHUNK" }

    // MARK: - Feature: Decode THINKING_TEXT_MESSAGE_CONTENT

    func test_decodeValidThinkingTextMessageContent_returnsEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "THINKING_TEXT_MESSAGE_CONTENT",
          "delta": "Analyzing the problem..."
        }
        """)

        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        guard let content = event as? ThinkingTextMessageContentEvent else {
            return XCTFail("Expected ThinkingTextMessageContentEvent, got \(type(of: event))")
        }
        XCTAssertEqual(content.eventType, .thinkingTextMessageContent)
        XCTAssertEqual(content.delta, "Analyzing the problem...")
        XCTAssertNil(content.timestamp)
    }

    func test_decodeThinkingTextMessageContent_withTimestamp_populatesTimestamp() throws {
        // Given
        let data = jsonData("""
        {
          "type": "THINKING_TEXT_MESSAGE_CONTENT",
          "delta": "Thinking...",
          "timestamp": \(EventTestData.timestamp)
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let content = try XCTUnwrap(event as? ThinkingTextMessageContentEvent)
        XCTAssertEqual(content.delta, "Thinking...")
        XCTAssertEqual(content.timestamp, EventTestData.timestamp)
    }

    func test_decodeThinkingTextMessageContent_preservesRawEventBytes() throws {
        // Given
        let data = jsonData("""
        {
          "type": "THINKING_TEXT_MESSAGE_CONTENT",
          "delta": "test"
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let content = try XCTUnwrap(event as? ThinkingTextMessageContentEvent)
        XCTAssertEqual(content.rawEvent, data)
    }

    func test_decodeThinkingTextMessageContent_missingDelta_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "THINKING_TEXT_MESSAGE_CONTENT"
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

    func test_decodeThinkingTextMessageContent_wrongTypeForDelta_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "THINKING_TEXT_MESSAGE_CONTENT",
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

    // MARK: - Feature: Model behaviors

    func test_thinkingTextMessageContentEvent_eventTypeIsAlways() {
        // Given
        let event = ThinkingTextMessageContentEvent(delta: "test", timestamp: nil, rawEvent: nil)

        // Then
        XCTAssertEqual(event.eventType, .thinkingTextMessageContent)
    }

    func test_thinkingTextMessageContentEvent_equatable_sameFields_areEqual() {
        // Given
        let event1 = ThinkingTextMessageContentEvent(delta: "test", timestamp: EventTestData.timestamp, rawEvent: nil)
        let event2 = ThinkingTextMessageContentEvent(delta: "test", timestamp: EventTestData.timestamp, rawEvent: nil)

        // Then
        XCTAssertEqual(event1, event2)
    }

    func test_thinkingTextMessageContentEvent_equatable_differentDeltas_areNotEqual() {
        // Given
        let event1 = ThinkingTextMessageContentEvent(delta: "test1", timestamp: EventTestData.timestamp, rawEvent: nil)
        let event2 = ThinkingTextMessageContentEvent(delta: "test2", timestamp: EventTestData.timestamp, rawEvent: nil)

        // Then
        XCTAssertNotEqual(event1, event2)
    }

    func test_thinkingTextMessageContentEvent_equatable_differentTimestamps_areNotEqual() {
        // Given
        let event1 = ThinkingTextMessageContentEvent(delta: "test", timestamp: EventTestData.timestamp, rawEvent: nil)
        let event2 = ThinkingTextMessageContentEvent(delta: "test", timestamp: EventTestData.timestamp2, rawEvent: nil)

        // Then
        XCTAssertNotEqual(event1, event2)
    }

    func test_thinkingTextMessageContentEvent_description_containsKeyInformation() {
        // Given
        let event = ThinkingTextMessageContentEvent(delta: "test", timestamp: EventTestData.timestamp, rawEvent: nil)

        // Then
        let description = event.description
        XCTAssertTrue(description.contains("ThinkingTextMessageContentEvent"))
        XCTAssertTrue(description.contains("delta"))
    }
}
