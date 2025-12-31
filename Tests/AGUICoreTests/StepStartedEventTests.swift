import XCTest
@testable import AGUICore

final class StepStartedEventTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        // Given
        let stepName = "reasoning"
        
        // When
        let event = StepStartedEvent(stepName: stepName)
        
        // Then
        assertEventProperties(
            event,
            expectedStepName: stepName,
            expectedTimestamp: nil,
            expectedRawEvent: nil
        )
    }
    
    func testInitializationWithOptionalParameters() {
        // Given
        let stepName = "tool_calling"
        let timestamp = EventTestData.timestamp
        let rawEvent = EventTestData.rawEventData
        
        // When
        let event = StepStartedEvent(
            stepName: stepName,
            timestamp: timestamp,
            rawEvent: rawEvent
        )
        
        // Then
        assertEventProperties(
            event,
            expectedStepName: stepName,
            expectedTimestamp: timestamp,
            expectedRawEvent: rawEvent
        )
    }
    
    func testInitializationWithEmptyString() {
        // Given
        let stepName = ""
        
        // When
        let event = StepStartedEvent(stepName: stepName)
        
        // Then
        XCTAssertEqual(event.stepName, stepName, "Should accept empty stepName")
    }
    
    func testInitializationWithUnicodeCharacters() {
        // Given
        let stepName = "推理-🚀-测试"
        
        // When
        let event = StepStartedEvent(stepName: stepName)
        
        // Then
        XCTAssertEqual(event.stepName, stepName, "Should handle Unicode characters")
    }
    
    // MARK: - EventType Tests
    
    func testEventTypeProperty() {
        // Given
        let event = makeEvent()
        
        // When & Then
        XCTAssertEqual(
            event.eventType,
            .stepStarted,
            "eventType should always return .stepStarted"
        )
    }
    
    // MARK: - Encoding Tests
    
    func testEncoding() throws {
        // Given
        let event = makeEvent()
        let encoder = JSONEncoder()
        
        // When
        let data = try encoder.encode(event)
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any],
            "JSON should be valid dictionary"
        )
        
        // Then
        assertJSONStructure(json, expectedType: "STEP_STARTED", shouldOmitTimestamp: true)
    }
    
    func testEncodingWithTimestamp() throws {
        // Given
        let timestamp = EventTestData.timestamp
        let event = makeEvent(timestamp: timestamp)
        let encoder = JSONEncoder()
        
        // When
        let data = try encoder.encode(event)
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any],
            "JSON should be valid dictionary"
        )
        
        // Then
        assertJSONStructure(json, expectedType: "STEP_STARTED", expectedTimestamp: timestamp)
    }
    
    func testEncodingOmitsRawEvent() throws {
        // Given
        // rawEvent is intentionally excluded from JSON encoding
        // as it represents the original raw data and shouldn't be serialized
        // to avoid duplication and potential inconsistencies
        let rawEvent = EventTestData.rawEventData
        let event = makeEvent(rawEvent: rawEvent)
        let encoder = JSONEncoder()
        
        // When
        let data = try encoder.encode(event)
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any],
            "JSON should be valid dictionary"
        )
        
        // Then
        XCTAssertNil(
            json["rawEvent"],
            "rawEvent should not be encoded in JSON"
        )
    }
    
    func testEncodingWithZeroTimestamp() throws {
        // Given
        let timestamp: Int64 = 0
        let event = makeEvent(timestamp: timestamp)
        let encoder = JSONEncoder()
        
        // When
        let data = try encoder.encode(event)
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any],
            "JSON should be valid dictionary"
        )
        
        // Then
        assertJSONStructure(json, expectedType: "STEP_STARTED", expectedTimestamp: timestamp)
    }
    
    func testEncodingWithUnicodeStepName() throws {
        // Given
        let stepName = "推理-🚀-测试"
        let event = makeEvent(stepName: stepName)
        let encoder = JSONEncoder()
        
        // When
        let data = try encoder.encode(event)
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any],
            "JSON should be valid dictionary"
        )
        
        // Then
        assertJSONStructure(
            json,
            expectedType: "STEP_STARTED",
            expectedStepName: stepName,
            shouldOmitTimestamp: true
        )
    }
    
    // MARK: - Decoding Tests
    
    func testDecoding() throws {
        // Given
        let stepName = "reasoning"
        let json = EventTestData.makeJSON(
            type: "STEP_STARTED",
            additionalFields: ["stepName": stepName]
        )
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        
        // When
        let event = try decoder.decode(StepStartedEvent.self, from: data)
        
        // Then
        assertEventProperties(
            event,
            expectedStepName: stepName,
            expectedTimestamp: nil,
            expectedRawEvent: nil
        )
        XCTAssertEqual(event.eventType, .stepStarted, "eventType should be .stepStarted")
    }
    
    func testDecodingWithTimestamp() throws {
        // Given
        let stepName = "tool_calling"
        let timestamp = EventTestData.timestamp
        let json = EventTestData.makeJSON(
            type: "STEP_STARTED",
            timestamp: timestamp,
            additionalFields: ["stepName": stepName]
        )
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        
        // When
        let event = try decoder.decode(StepStartedEvent.self, from: data)
        
        // Then
        assertEventProperties(
            event,
            expectedStepName: stepName,
            expectedTimestamp: timestamp,
            expectedRawEvent: nil
        )
        XCTAssertEqual(event.eventType, .stepStarted, "eventType should be .stepStarted")
    }
    
    func testDecodingWithZeroTimestamp() throws {
        // Given
        let stepName = "reasoning"
        let timestamp: Int64 = 0
        let json = EventTestData.makeJSON(
            type: "STEP_STARTED",
            timestamp: timestamp,
            additionalFields: ["stepName": stepName]
        )
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        
        // When
        let event = try decoder.decode(StepStartedEvent.self, from: data)
        
        // Then
        XCTAssertEqual(
            event.timestamp,
            timestamp,
            "Should decode zero timestamp correctly"
        )
    }
    
    func testDecodingWithUnicodeStepName() throws {
        // Given
        let stepName = "推理-🚀-测试"
        let json = EventTestData.makeJSON(
            type: "STEP_STARTED",
            additionalFields: ["stepName": stepName]
        )
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        
        // When
        let event = try decoder.decode(StepStartedEvent.self, from: data)
        
        // Then
        XCTAssertEqual(event.stepName, stepName, "Should decode Unicode stepName")
    }
    
    // MARK: - Error Handling Tests
    
    func testDecodingFailsWithWrongType() {
        // Given
        let json = EventTestData.makeJSON(
            type: "RUN_STARTED",
            additionalFields: ["stepName": "reasoning"]
        )
        guard let data = try? JSONSerialization.data(withJSONObject: json) else {
            XCTFail("Failed to create JSON data")
            return
        }
        let decoder = JSONDecoder()
        
        // When & Then
        XCTAssertThrowsError(
            try decoder.decode(StepStartedEvent.self, from: data),
            "Should throw error when event type is incorrect"
        ) { error in
            guard let decodingError = error as? DecodingError else {
                XCTFail("Expected DecodingError, got \(type(of: error))")
                return
            }
            
            guard case .dataCorrupted(let context) = decodingError else {
                XCTFail("Expected DecodingError.dataCorrupted, got \(decodingError)")
                return
            }
            
            XCTAssertTrue(
                context.debugDescription.contains("STEP_STARTED"),
                "Error should mention expected type STEP_STARTED"
            )
            XCTAssertTrue(
                context.debugDescription.contains("RUN_STARTED"),
                "Error should mention actual type RUN_STARTED"
            )
        }
    }
    
    func testDecodingFailsWithMissingType() {
        // Given
        let json: [String: Any] = [
            // type is intentionally missing
            "stepName": "reasoning"
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: json) else {
            XCTFail("Failed to create JSON data")
            return
        }
        let decoder = JSONDecoder()
        
        // When & Then
        XCTAssertThrowsError(
            try decoder.decode(StepStartedEvent.self, from: data),
            "Should throw error when type field is missing"
        ) { error in
            assertDecodingError(error)
        }
    }
    
    func testDecodingFailsWithMissingStepName() {
        // Given
        let json: [String: Any] = [
            "type": "STEP_STARTED"
            // stepName is intentionally missing
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        
        // When & Then
        XCTAssertThrowsError(
            try decoder.decode(StepStartedEvent.self, from: data),
            "Should throw error when stepName is missing"
        ) { error in
            assertDecodingError(error)
        }
    }
    
    func testDecodingFailsWithInvalidTimestampType() {
        // Given
        let json: [String: Any] = [
            "type": "STEP_STARTED",
            "stepName": "reasoning",
            "timestamp": "invalid" // Should be Int64, not String
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: json) else {
            XCTFail("Failed to create JSON data")
            return
        }
        let decoder = JSONDecoder()
        
        // When & Then
        XCTAssertThrowsError(
            try decoder.decode(StepStartedEvent.self, from: data),
            "Should throw error when timestamp has wrong type"
        ) { error in
            assertDecodingError(error)
        }
    }
    
    func testDecodingFailsWithMalformedJSON() {
        // Given
        let malformedData = "{invalid json}".data(using: .utf8)!
        let decoder = JSONDecoder()
        
        // When & Then
        XCTAssertThrowsError(
            try decoder.decode(StepStartedEvent.self, from: malformedData),
            "Should throw error when JSON is malformed"
        ) { error in
            assertDecodingError(error)
        }
    }
    
    // MARK: - Round-Trip Tests
    
    func testRoundTripEncodingDecoding() throws {
        // Given
        let originalEvent = makeEvent(
            stepName: "tool_calling",
            timestamp: EventTestData.timestamp
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // When
        let encodedData = try encoder.encode(originalEvent)
        let decodedEvent = try decoder.decode(StepStartedEvent.self, from: encodedData)
        
        // Then
        assertEventProperties(
            decodedEvent,
            expectedStepName: originalEvent.stepName,
            expectedTimestamp: originalEvent.timestamp,
            expectedRawEvent: nil // rawEvent is nil after round-trip
        )
        XCTAssertEqual(
            decodedEvent.eventType,
            originalEvent.eventType,
            "eventType should match after round-trip"
        )
    }
    
    func testRoundTripEncodingDecodingWithoutTimestamp() throws {
        // Given
        let originalEvent = makeEvent(stepName: "reasoning")
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // When
        let encodedData = try encoder.encode(originalEvent)
        let decodedEvent = try decoder.decode(StepStartedEvent.self, from: encodedData)
        
        // Then
        assertEventProperties(
            decodedEvent,
            expectedStepName: originalEvent.stepName,
            expectedTimestamp: nil,
            expectedRawEvent: nil
        )
        XCTAssertEqual(
            decodedEvent.eventType,
            originalEvent.eventType,
            "eventType should match after round-trip"
        )
    }
    
    func testRoundTripWithUnicodeStepName() throws {
        // Given
        let stepName = "推理-🚀-测试"
        let originalEvent = makeEvent(stepName: stepName)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // When
        let encodedData = try encoder.encode(originalEvent)
        let decodedEvent = try decoder.decode(StepStartedEvent.self, from: encodedData)
        
        // Then
        XCTAssertEqual(
            decodedEvent.stepName,
            originalEvent.stepName,
            "Unicode stepName should survive round-trip"
        )
    }
    
    // MARK: - Event-Specific Factory Methods
    
    private func makeEvent(
        stepName: String = "reasoning",
        timestamp: Int64? = nil,
        rawEvent: Data? = nil
    ) -> StepStartedEvent {
        StepStartedEvent(
            stepName: stepName,
            timestamp: timestamp,
            rawEvent: rawEvent
        )
    }
    
    // MARK: - Helper Methods
    
    private func assertEventProperties(
        _ event: StepStartedEvent,
        expectedStepName: String,
        expectedTimestamp: Int64? = nil,
        expectedRawEvent: Data? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            event.stepName,
            expectedStepName,
            "stepName should match expected value",
            file: file,
            line: line
        )
        XCTAssertEqual(
            event.timestamp,
            expectedTimestamp,
            "timestamp should match expected value",
            file: file,
            line: line
        )
        XCTAssertEqual(
            event.rawEvent,
            expectedRawEvent,
            "rawEvent should match expected value",
            file: file,
            line: line
        )
    }
    
    private func assertJSONStructure(
        _ json: [String: Any],
        expectedType: String = "STEP_STARTED",
        expectedStepName: String = "reasoning",
        expectedTimestamp: Int64? = nil,
        shouldOmitTimestamp: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            json["type"] as? String,
            expectedType,
            "Event type should be \(expectedType)",
            file: file,
            line: line
        )
        XCTAssertEqual(
            json["stepName"] as? String,
            expectedStepName,
            "stepName should match expected value",
            file: file,
            line: line
        )
        
        if shouldOmitTimestamp {
            XCTAssertNil(
                json["timestamp"],
                "timestamp should be omitted when nil",
                file: file,
                line: line
            )
        } else if let expectedTimestamp = expectedTimestamp {
            XCTAssertEqual(
                json["timestamp"] as? Int64,
                expectedTimestamp,
                "timestamp should match expected value",
                file: file,
                line: line
            )
        }
        
        XCTAssertNil(
            json["rawEvent"],
            "rawEvent should not be encoded in JSON",
            file: file,
            line: line
        )
    }
    
    private func assertDecodingError(
        _ error: Error,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard error is DecodingError else {
            XCTFail(
                "Expected DecodingError, got \(type(of: error))",
                file: file,
                line: line
            )
            return
        }
    }
}

