import XCTest
@testable import AGUICore

final class RunStartedEventTests: XCTestCase {

    // MARK: - Feature: Decode RUN_STARTED

    func test_decodeValidRunStarted_returnsRunStartedEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "RUN_STARTED",
          "threadId": "thread-123",
          "runId": "run-456"
        }
        """)

        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        guard let runStarted = event as? RunStartedEvent else {
            return XCTFail("Expected RunStartedEvent, got \(type(of: event))")
        }
        XCTAssertEqual(runStarted.eventType, .runStarted)
        XCTAssertEqual(runStarted.threadId, "thread-123")
        XCTAssertEqual(runStarted.runId, "run-456")
        XCTAssertNil(runStarted.timestamp)
    }

    func test_decodeRunStarted_withTimestamp_populatesTimestamp() throws {
        // Given
        let data = jsonData("""
        {
          "type": "RUN_STARTED",
          "threadId": "thread-123",
          "runId": "run-456",
          "timestamp": 1704067200000
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let runStarted = try XCTUnwrap(event as? RunStartedEvent)
        XCTAssertEqual(runStarted.timestamp, 1704067200000)
    }

    func test_decodeRunStarted_preservesRawEventBytes() throws {
        // Given
        let data = jsonData("""
        {
          "type": "RUN_STARTED",
          "threadId": "thread-123",
          "runId": "run-456",
          "timestamp": 1704067200000
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let runStarted = try XCTUnwrap(event as? RunStartedEvent)
        XCTAssertEqual(runStarted.rawEvent, data)
    }

    func test_decodeRunStarted_ignoresUnknownExtraFields() throws {
        // Given
        let data = jsonData("""
        {
          "type": "RUN_STARTED",
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
        let runStarted = try XCTUnwrap(event as? RunStartedEvent)
        XCTAssertEqual(runStarted.threadId, "thread-123")
        XCTAssertEqual(runStarted.runId, "run-456")
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
          "type": "RUN_STARTED",
          "threadId": "thread-123",
          "runId": "run-456"
        }
        """)

        // registry intentionally empty -> handler missing
        let decoder = makeStrictDecoder(registry: [:])

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            XCTAssertEqual(error as? EventDecodingError, .unsupportedEventType(.runStarted))
        }
    }

    func test_decodeKnownTypeButNoHandler_inTolerantMode_returnsUnknownEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "RUN_STARTED",
          "threadId": "thread-123",
          "runId": "run-456"
        }
        """)
        let decoder = makeTolerantDecoder(registry: [:])

        // When
        let event = try decoder.decode(data)

        // Then
        let unknown = try XCTUnwrap(event as? UnknownEvent)
        XCTAssertEqual(unknown.typeRaw, "RUN_STARTED")
        XCTAssertEqual(unknown.rawEvent, data)
    }

    func test_decodeRunStarted_missingThreadId_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "RUN_STARTED",
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

    func test_decodeRunStarted_threadIdWrongType_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "RUN_STARTED",
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
        let data = jsonData(#"{ "type": "RUN_STARTED", "threadId": "t1", "#) // truncated JSON
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            XCTAssertEqual(error as? EventDecodingError, .invalidJSON)
        }
    }

    // MARK: - Feature: Model behaviors

    func test_runStartedEvent_eventTypeIsAlwaysRunStarted() {
        // Given
        let event = RunStartedEvent(threadId: "t", runId: "r", timestamp: nil, rawEvent: nil)

        // Then
        XCTAssertEqual(event.eventType, .runStarted)
    }

    func test_runStartedEvent_equatable_sameFields_areEqual() {
        // Given
        let a = RunStartedEvent(threadId: "t", runId: "r", timestamp: 1, rawEvent: nil)
        let b = RunStartedEvent(threadId: "t", runId: "r", timestamp: 1, rawEvent: nil)

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
