import XCTest
@testable import AGUICore

final class RunFinishedEventTests: XCTestCase {

    // MARK: - Feature: Decode RUN_FINISHED

    func test_decodeValidRunFinished_returnsRunFinishedEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "RUN_FINISHED",
          "threadId": "thread-123",
          "runId": "run-456"
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
        XCTAssertEqual(runFinished.threadId, "thread-123")
        XCTAssertEqual(runFinished.runId, "run-456")
        XCTAssertNil(runFinished.timestamp)
    }

    func test_decodeRunFinished_withTimestamp_populatesTimestamp() throws {
        // Given
        let data = jsonData("""
        {
          "type": "RUN_FINISHED",
          "threadId": "thread-123",
          "runId": "run-456",
          "timestamp": 1704067200000
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let runFinished = try XCTUnwrap(event as? RunFinishedEvent)
        XCTAssertEqual(runFinished.timestamp, 1704067200000)
    }

    func test_decodeRunFinished_preservesRawEventBytes() throws {
        // Given
        let data = jsonData("""
        {
          "type": "RUN_FINISHED",
          "threadId": "thread-123",
          "runId": "run-456",
          "timestamp": 1704067200000
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
          "threadId": "thread-123",
          "runId": "run-456",
          "extraField": "ignored",
          "nested": { "x": 1 }
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let runFinished = try XCTUnwrap(event as? RunFinishedEvent)
        XCTAssertEqual(runFinished.threadId, "thread-123")
        XCTAssertEqual(runFinished.runId, "run-456")
    }

    // MARK: - Feature: Error handling

    func test_decodeMissingType_throwsMissingTypeField() {
        // Given
        let data = jsonData("""
        {
          "threadId": "thread-123",
          "runId": "run-456"
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
          "type": "RUN_PAUSED",
          "threadId": "thread-123",
          "runId": "run-456"
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            XCTAssertEqual(error as? EventDecodingError, .unknownEventType("RUN_PAUSED"))
        }
    }

    func test_decodeUnknownType_inTolerantMode_returnsUnknownEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "RUN_PAUSED",
          "threadId": "thread-123",
          "runId": "run-456"
        }
        """)
        let decoder = makeTolerantDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let unknown = try XCTUnwrap(event as? UnknownEvent)
        XCTAssertEqual(unknown.typeRaw, "RUN_PAUSED")
        XCTAssertEqual(unknown.rawEvent, data)
    }

    func test_decodeKnownTypeButNoHandler_inStrictMode_throwsUnsupportedEventType() {
        // Given
        let data = jsonData("""
        {
          "type": "RUN_FINISHED",
          "threadId": "thread-123",
          "runId": "run-456"
        }
        """)

        // registry intentionally empty -> handler missing
        let decoder = makeStrictDecoder(registry: [:])

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            XCTAssertEqual(error as? EventDecodingError, .unsupportedEventType(.runFinished))
        }
    }

    func test_decodeKnownTypeButNoHandler_inTolerantMode_returnsUnknownEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "RUN_FINISHED",
          "threadId": "thread-123",
          "runId": "run-456"
        }
        """)
        let decoder = makeTolerantDecoder(registry: [:])

        // When
        let event = try decoder.decode(data)

        // Then
        let unknown = try XCTUnwrap(event as? UnknownEvent)
        XCTAssertEqual(unknown.typeRaw, "RUN_FINISHED")
        XCTAssertEqual(unknown.rawEvent, data)
    }

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

    func test_decodeInvalidJSON_throwsInvalidJSON() {
        // Given
        let data = jsonData(#"{ "type": "RUN_FINISHED", "threadId": "t1", "#) // truncated JSON
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            XCTAssertEqual(error as? EventDecodingError, .invalidJSON)
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
