import XCTest
@testable import AGUICore

final class StepStartedEventTests: XCTestCase {

    // MARK: - Feature: Decode STEP_STARTED

    func test_decodeValidStepStarted_returnsStepStartedEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "STEP_STARTED",
          "stepName": "reasoning"
        }
        """)

        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        guard let stepStarted = event as? StepStartedEvent else {
            return XCTFail("Expected StepStartedEvent, got \(type(of: event))")
        }
        XCTAssertEqual(stepStarted.eventType, .stepStarted)
        XCTAssertEqual(stepStarted.stepName, "reasoning")
        XCTAssertNil(stepStarted.timestamp)
    }

    func test_decodeStepStarted_withTimestamp_populatesTimestamp() throws {
        // Given
        let data = jsonData("""
        {
          "type": "STEP_STARTED",
          "stepName": "reasoning",
          "timestamp": 1704067200000
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let stepStarted = try XCTUnwrap(event as? StepStartedEvent)
        XCTAssertEqual(stepStarted.timestamp, 1704067200000)
    }

    func test_decodeStepStarted_preservesRawEventBytes() throws {
        // Given
        let data = jsonData("""
        {
          "type": "STEP_STARTED",
          "stepName": "reasoning",
          "timestamp": 1704067200000
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let stepStarted = try XCTUnwrap(event as? StepStartedEvent)
        XCTAssertEqual(stepStarted.rawEvent, data)
    }

    func test_decodeStepStarted_ignoresUnknownExtraFields() throws {
        // Given
        let data = jsonData("""
        {
          "type": "STEP_STARTED",
          "stepName": "reasoning",
          "extraField": "ignored",
          "nested": { "x": 1 }
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let stepStarted = try XCTUnwrap(event as? StepStartedEvent)
        XCTAssertEqual(stepStarted.stepName, "reasoning")
    }

    func test_decodeStepStarted_withUnicodeStepName_handlesUnicode() throws {
        // Given
        let data = jsonData("""
        {
          "type": "STEP_STARTED",
          "stepName": "推理-🚀-测试"
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let stepStarted = try XCTUnwrap(event as? StepStartedEvent)
        XCTAssertEqual(stepStarted.stepName, "推理-🚀-测试")
    }

    // MARK: - Feature: Error handling

    func test_decodeMissingType_throwsMissingTypeField() {
        // Given
        let data = jsonData("""
        {
          "stepName": "reasoning"
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
          "type": "STEP_PAUSED",
          "stepName": "reasoning"
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            XCTAssertEqual(error as? EventDecodingError, .unknownEventType("STEP_PAUSED"))
        }
    }

    func test_decodeUnknownType_inTolerantMode_returnsUnknownEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "STEP_PAUSED",
          "stepName": "reasoning"
        }
        """)
        let decoder = makeTolerantDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let unknown = try XCTUnwrap(event as? UnknownEvent)
        XCTAssertEqual(unknown.typeRaw, "STEP_PAUSED")
        XCTAssertEqual(unknown.rawEvent, data)
    }

    func test_decodeKnownTypeButNoHandler_inStrictMode_throwsUnsupportedEventType() {
        // Given
        let data = jsonData("""
        {
          "type": "STEP_STARTED",
          "stepName": "reasoning"
        }
        """)

        // registry intentionally empty -> handler missing
        let decoder = makeStrictDecoder(registry: [:])

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            XCTAssertEqual(error as? EventDecodingError, .unsupportedEventType(.stepStarted))
        }
    }

    func test_decodeKnownTypeButNoHandler_inTolerantMode_returnsUnknownEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "STEP_STARTED",
          "stepName": "reasoning"
        }
        """)
        let decoder = makeTolerantDecoder(registry: [:])

        // When
        let event = try decoder.decode(data)

        // Then
        let unknown = try XCTUnwrap(event as? UnknownEvent)
        XCTAssertEqual(unknown.typeRaw, "STEP_STARTED")
        XCTAssertEqual(unknown.rawEvent, data)
    }

    func test_decodeStepStarted_missingStepName_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "STEP_STARTED"
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            guard case .decodingFailed(let message) = (error as? EventDecodingError) else {
                return XCTFail("Expected .decodingFailed, got \(error)")
            }
            XCTAssertTrue(message.contains("stepName"), "Expected message to mention 'stepName'. Got: \(message)")
        }
    }

    func test_decodeStepStarted_stepNameWrongType_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "STEP_STARTED",
          "stepName": 123
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

    func test_decodeStepStarted_timestampWrongType_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "STEP_STARTED",
          "stepName": "reasoning",
          "timestamp": "invalid"
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
        let data = jsonData(#"{ "type": "STEP_STARTED", "stepName": "r1", "#) // truncated JSON
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            XCTAssertEqual(error as? EventDecodingError, .invalidJSON)
        }
    }

    // MARK: - Feature: Model behaviors

    func test_stepStartedEvent_eventTypeIsAlwaysStepStarted() {
        // Given
        let event = StepStartedEvent(stepName: "reasoning", timestamp: nil, rawEvent: nil)

        // Then
        XCTAssertEqual(event.eventType, .stepStarted)
    }

    func test_stepStartedEvent_equatable_sameFields_areEqual() {
        // Given
        let a = StepStartedEvent(stepName: "reasoning", timestamp: 1, rawEvent: nil)
        let b = StepStartedEvent(stepName: "reasoning", timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertEqual(a, b)
    }

    func test_stepStartedEvent_withEmptyStepName_isValid() {
        // Given
        let event = StepStartedEvent(stepName: "", timestamp: nil, rawEvent: nil)

        // Then
        XCTAssertEqual(event.stepName, "")
        XCTAssertEqual(event.eventType, .stepStarted)
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
