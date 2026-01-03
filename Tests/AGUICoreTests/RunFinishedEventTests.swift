import XCTest
@testable import AGUICore

final class RunFinishedEventTests: XCTestCase,
                                    AGUIEventDecoderTestHelpers,
                                    EventDecodingErrorTests {

    // MARK: - EventDecodingErrorTests Protocol Requirements

    var validEventFieldsWithoutType: [String: Any] {
        [
            "threadId": EventTestData.threadId,
            "runId": EventTestData.runId
        ]
    }

    var eventTypeString: String { "RUN_FINISHED" }
    var expectedEventType: EventType { .runFinished }
    var unknownEventTypeString: String { "RUN_PAUSED" }

    // MARK: - Feature: Decode RUN_FINISHED

    func test_decodeValidRunFinished_returnsRunFinishedEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "RUN_FINISHED",
          "threadId": "\(EventTestData.threadId)",
          "runId": "\(EventTestData.runId)"
        }
        """)

        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        guard let runFinished = event as? RunFinishedEvent else {
            return XCTFail("Expected RunFinishedEvent, got \(type(of: event))")
        }
        XCTAssertEqual(runFinished.eventType, .runFinished)
        XCTAssertEqual(runFinished.threadId, EventTestData.threadId)
        XCTAssertEqual(runFinished.runId, EventTestData.runId)
        XCTAssertNil(runFinished.timestamp)
    }

    func test_decodeRunFinished_withTimestamp_populatesTimestamp() throws {
        // Given
        let data = jsonData("""
        {
          "type": "RUN_FINISHED",
          "threadId": "\(EventTestData.threadId)",
          "runId": "\(EventTestData.runId)",
          "timestamp": \(EventTestData.timestamp)
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let runFinished = try XCTUnwrap(event as? RunFinishedEvent)
        XCTAssertEqual(runFinished.timestamp, EventTestData.timestamp)
    }

    func test_decodeRunFinished_preservesRawEventBytes() throws {
        // Given
        let data = jsonData("""
        {
          "type": "RUN_FINISHED",
          "threadId": "\(EventTestData.threadId)",
          "runId": "\(EventTestData.runId)",
          "timestamp": \(EventTestData.timestamp)
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let runFinished = try XCTUnwrap(event as? RunFinishedEvent)
        XCTAssertEqual(runFinished.rawEvent, data)
    }

    func test_decodeRunFinished_ignoresUnknownExtraFields() throws {
        // Given
        let data = jsonData("""
        {
          "type": "RUN_FINISHED",
          "threadId": "\(EventTestData.threadId)",
          "runId": "\(EventTestData.runId)",
          "extraField": "ignored",
          "nested": { "x": 1 }
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let runFinished = try XCTUnwrap(event as? RunFinishedEvent)
        XCTAssertEqual(runFinished.threadId, EventTestData.threadId)
        XCTAssertEqual(runFinished.runId, EventTestData.runId)
    }

    // MARK: - Feature: Error handling (event-specific)

    func test_decodeRunFinished_missingThreadId_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "RUN_FINISHED",
          "runId": "run-456"
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            guard case .decodingFailed(let message) = (error as? EventDecodingError) else {
                return XCTFail("Expected .decodingFailed, got \(error)")
            }
            XCTAssertTrue(message.contains("threadId"), "Expected message to mention 'threadId'. Got: \(message)")
        }
    }

    func test_decodeRunFinished_threadIdWrongType_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "RUN_FINISHED",
          "threadId": 123,
          "runId": "run-456"
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            guard case .decodingFailed(let message) = (error as? EventDecodingError) else {
                return XCTFail("Expected .decodingFailed, got \(error)")
            }
            XCTAssertTrue(message.lowercased().contains("type mismatch") || message.contains("Type mismatch"),
                          "Expected a type mismatch message. Got: \(message)")
        }
    }

    // MARK: - Feature: Model behaviors

    func test_runFinishedEvent_eventTypeIsAlwaysRunFinished() {
        // Given
        let event = RunFinishedEvent(threadId: "t", runId: "r", timestamp: nil, rawEvent: nil)

        // Then
        XCTAssertEqual(event.eventType, .runFinished)
    }

    func test_runFinishedEvent_equatable_sameFields_areEqual() {
        // Given
        let a = RunFinishedEvent(threadId: "t", runId: "r", timestamp: 1, rawEvent: nil)
        let b = RunFinishedEvent(threadId: "t", runId: "r", timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertEqual(a, b)
    }
}
