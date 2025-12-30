import XCTest
@testable import AGUICore

final class RunStartedEventTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        // Given
        let threadId = EventTestData.threadId
        let runId = EventTestData.runId
        
        // When
        let event = RunStartedEvent(threadId: threadId, runId: runId)
        
        // Then
        assertEventProperties(
            event,
            expectedThreadId: threadId,
            expectedRunId: runId,
            expectedTimestamp: nil,
            expectedRawEvent: nil
        )
    }
    
    func testInitializationWithOptionalParameters() {
        // Given
        let threadId = EventTestData.threadId
        let runId = EventTestData.runId
        let timestamp = EventTestData.timestamp
        let rawEvent = EventTestData.rawEventData
        
        // When
        let event = RunStartedEvent(
            threadId: threadId,
            runId: runId,
            timestamp: timestamp,
            rawEvent: rawEvent
        )
        
        // Then
        assertEventProperties(
            event,
            expectedThreadId: threadId,
            expectedRunId: runId,
            expectedTimestamp: timestamp,
            expectedRawEvent: rawEvent
        )
    }
    
    func testInitializationWithEmptyStrings() {
        // Given
        let threadId = ""
        let runId = ""
        
        // When
        let event = RunStartedEvent(threadId: threadId, runId: runId)
        
        // Then
        XCTAssertEqual(event.threadId, threadId, "Should accept empty threadId")
        XCTAssertEqual(event.runId, runId, "Should accept empty runId")
    }
    
    func testInitializationWithUnicodeCharacters() {
        // Given
        let threadId = "thread-🚀-123"
        let runId = "run-测试-456"
        
        // When
        let event = RunStartedEvent(threadId: threadId, runId: runId)
        
        // Then
        XCTAssertEqual(event.threadId, threadId, "Should handle Unicode characters")
        XCTAssertEqual(event.runId, runId, "Should handle Unicode characters")
    }
    
    // MARK: - EventType Tests
    
    func testEventTypeProperty() {
        // Given
        let event = makeEvent()
        
        // When & Then
        XCTAssertEqual(
            event.eventType,
            .runStarted,
            "eventType should always return .runStarted"
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
        assertJSONStructure(json, expectedType: "RUN_STARTED", shouldOmitTimestamp: true)
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
        assertJSONStructure(json, expectedType: "RUN_STARTED", expectedTimestamp: timestamp)
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
        assertJSONStructure(json, expectedType: "RUN_STARTED", expectedTimestamp: timestamp)
    }
    
    func testEncodingWithUnicodeIDs() throws {
        // Given
        let threadId = "thread-🚀-123"
        let runId = "run-测试-456"
        let event = makeEvent(threadId: threadId, runId: runId)
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
            expectedType: "RUN_STARTED",
            expectedThreadId: threadId,
            expectedRunId: runId,
            shouldOmitTimestamp: true
        )
    }
    
    // MARK: - Decoding Tests
    
    func testDecoding() throws {
        // Given
        let json = EventTestData.makeJSON(type: "RUN_STARTED")
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        
        // When
        let event = try decoder.decode(RunStartedEvent.self, from: data)
        
        // Then
        assertEventProperties(
            event,
            expectedThreadId: EventTestData.threadId,
            expectedRunId: EventTestData.runId,
            expectedTimestamp: nil,
            expectedRawEvent: nil
        )
        XCTAssertEqual(
            event.eventType,
            .runStarted,
            "eventType should be .runStarted"
        )
    }
    
    func testDecodingWithTimestamp() throws {
        // Given
        let timestamp = EventTestData.timestamp
        let json = EventTestData.makeJSON(type: "RUN_STARTED", timestamp: timestamp)
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        
        // When
        let event = try decoder.decode(RunStartedEvent.self, from: data)
        
        // Then
        assertEventProperties(
            event,
            expectedThreadId: EventTestData.threadId,
            expectedRunId: EventTestData.runId,
            expectedTimestamp: timestamp
        )
        XCTAssertEqual(
            event.eventType,
            .runStarted,
            "eventType should be .runStarted"
        )
    }
    
    func testDecodingWithZeroTimestamp() throws {
        // Given
        let timestamp: Int64 = 0
        let json = EventTestData.makeJSON(type: "RUN_STARTED", timestamp: timestamp)
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        
        // When
        let event = try decoder.decode(RunStartedEvent.self, from: data)
        
        // Then
        XCTAssertEqual(
            event.timestamp,
            timestamp,
            "Should decode zero timestamp correctly"
        )
    }
    
    func testDecodingWithUnicodeIDs() throws {
        // Given
        let threadId = "thread-🚀-123"
        let runId = "run-测试-456"
        let json = EventTestData.makeJSON(type: "RUN_STARTED", threadId: threadId, runId: runId)
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        
        // When
        let event = try decoder.decode(RunStartedEvent.self, from: data)
        
        // Then
        XCTAssertEqual(event.threadId, threadId, "Should decode Unicode threadId")
        XCTAssertEqual(event.runId, runId, "Should decode Unicode runId")
    }
    
    // MARK: - Error Handling Tests
    
    func testDecodingFailsWithWrongType() {
        // Given
        let json = EventTestData.makeJSON(type: "RUN_FINISHED") // Wrong type
        guard let data = try? JSONSerialization.data(withJSONObject: json) else {
            XCTFail("Failed to create JSON data")
            return
        }
        let decoder = JSONDecoder()
        
        // When & Then
        XCTAssertThrowsError(
            try decoder.decode(RunStartedEvent.self, from: data),
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
                context.debugDescription.contains("RUN_STARTED"),
                "Error should mention expected type RUN_STARTED"
            )
            XCTAssertTrue(
                context.debugDescription.contains("RUN_FINISHED"),
                "Error should mention actual type RUN_FINISHED"
            )
        }
    }
    
    func testDecodingFailsWithMissingType() {
        // Given
        let json: [String: Any] = [
            // type is intentionally missing
            "threadId": EventTestData.threadId,
            "runId": EventTestData.runId
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: json) else {
            XCTFail("Failed to create JSON data")
            return
        }
        let decoder = JSONDecoder()
        
        // When & Then
        XCTAssertThrowsError(
            try decoder.decode(RunStartedEvent.self, from: data),
            "Should throw error when type field is missing"
        ) { error in
            assertDecodingError(error)
        }
    }
    
    func testDecodingFailsWithMissingThreadId() {
        // Given
        let json: [String: Any] = [
            "type": "RUN_STARTED",
            "runId": EventTestData.runId
            // threadId is intentionally missing
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        
        // When & Then
        XCTAssertThrowsError(
            try decoder.decode(RunStartedEvent.self, from: data),
            "Should throw error when threadId is missing"
        ) { error in
            assertDecodingError(error)
        }
    }
    
    func testDecodingFailsWithMissingRunId() {
        // Given
        let json: [String: Any] = [
            "type": "RUN_STARTED",
            "threadId": EventTestData.threadId
            // runId is intentionally missing
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        
        // When & Then
        XCTAssertThrowsError(
            try decoder.decode(RunStartedEvent.self, from: data),
            "Should throw error when runId is missing"
        ) { error in
            assertDecodingError(error)
        }
    }
    
    func testDecodingFailsWithInvalidTimestampType() {
        // Given
        let json: [String: Any] = [
            "type": "RUN_STARTED",
            "threadId": EventTestData.threadId,
            "runId": EventTestData.runId,
            "timestamp": "invalid" // Should be Int64, not String
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: json) else {
            XCTFail("Failed to create JSON data")
            return
        }
        let decoder = JSONDecoder()
        
        // When & Then
        XCTAssertThrowsError(
            try decoder.decode(RunStartedEvent.self, from: data),
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
            try decoder.decode(RunStartedEvent.self, from: malformedData),
            "Should throw error when JSON is malformed"
        ) { error in
            assertDecodingError(error)
        }
    }
    
    // MARK: - Round-Trip Tests
    
    func testRoundTripEncodingDecoding() throws {
        // Given
        let originalEvent = makeEvent(timestamp: EventTestData.timestamp)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // When
        let encodedData = try encoder.encode(originalEvent)
        let decodedEvent = try decoder.decode(RunStartedEvent.self, from: encodedData)
        
        // Then
        XCTAssertEqual(
            decodedEvent.threadId,
            originalEvent.threadId,
            "threadId should match after round-trip"
        )
        XCTAssertEqual(
            decodedEvent.runId,
            originalEvent.runId,
            "runId should match after round-trip"
        )
        XCTAssertEqual(
            decodedEvent.timestamp,
            originalEvent.timestamp,
            "timestamp should match after round-trip"
        )
        XCTAssertEqual(
            decodedEvent.eventType,
            originalEvent.eventType,
            "eventType should match after round-trip"
        )
        // Note: rawEvent will be nil after round-trip as per implementation
        XCTAssertNil(
            decodedEvent.rawEvent,
            "rawEvent will be nil after round-trip (not encoded)"
        )
    }
    
    func testRoundTripEncodingDecodingWithoutTimestamp() throws {
        // Given
        let originalEvent = makeEvent()
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // When
        let encodedData = try encoder.encode(originalEvent)
        let decodedEvent = try decoder.decode(RunStartedEvent.self, from: encodedData)
        
        // Then
        XCTAssertEqual(
            decodedEvent.threadId,
            originalEvent.threadId,
            "threadId should match after round-trip"
        )
        XCTAssertEqual(
            decodedEvent.runId,
            originalEvent.runId,
            "runId should match after round-trip"
        )
        XCTAssertNil(
            decodedEvent.timestamp,
            "timestamp should remain nil after round-trip"
        )
        XCTAssertEqual(
            decodedEvent.eventType,
            originalEvent.eventType,
            "eventType should match after round-trip"
        )
    }
    
    func testRoundTripWithUnicodeIDs() throws {
        // Given
        let threadId = "thread-🚀-123"
        let runId = "run-测试-456"
        let originalEvent = makeEvent(threadId: threadId, runId: runId)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // When
        let encodedData = try encoder.encode(originalEvent)
        let decodedEvent = try decoder.decode(RunStartedEvent.self, from: encodedData)
        
        // Then
        XCTAssertEqual(
            decodedEvent.threadId,
            originalEvent.threadId,
            "Unicode threadId should survive round-trip"
        )
        XCTAssertEqual(
            decodedEvent.runId,
            originalEvent.runId,
            "Unicode runId should survive round-trip"
        )
    }
    
    // MARK: - Event-Specific Factory Methods
    
    private func makeEvent(
        threadId: String = EventTestData.threadId,
        runId: String = EventTestData.runId,
        timestamp: Int64? = nil,
        rawEvent: Data? = nil
    ) -> RunStartedEvent {
        RunStartedEvent(
            threadId: threadId,
            runId: runId,
            timestamp: timestamp,
            rawEvent: rawEvent
        )
    }
}
