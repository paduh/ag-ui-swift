import XCTest
@testable import AGUICore

final class RunFinishedEventTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        // Given
        let threadId = EventTestData.threadId
        let runId = EventTestData.runId
        
        // When
        let event = RunFinishedEvent(threadId: threadId, runId: runId)
        
        // Then
        assertEventProperties(
            event,
            expectedThreadId: threadId,
            expectedRunId: runId,
            expectedTimestamp: nil,
        )
    }
    
    func testInitializationWithOptionalParameters() {
        // Given
        let threadId = EventTestData.threadId
        let runId = EventTestData.runId
        let timestamp = EventTestData.timestamp
        // When
        let event = RunFinishedEvent(
            threadId: threadId,
            runId: runId,
            timestamp: timestamp
        )
        
        // Then
        assertEventProperties(
            event,
            expectedThreadId: threadId,
            expectedRunId: runId,
            expectedTimestamp: timestamp
        )
    }
    
    func testInitializationWithEmptyStrings() {
        // Given
        let threadId = ""
        let runId = ""
        
        // When
        let event = RunFinishedEvent(threadId: threadId, runId: runId)
        
        // Then
        XCTAssertEqual(event.threadId, threadId, "Should accept empty threadId")
        XCTAssertEqual(event.runId, runId, "Should accept empty runId")
    }
    
    func testInitializationWithUnicodeCharacters() {
        // Given
        let threadId = "thread-🚀-123"
        let runId = "run-测试-456"
        
        // When
        let event = RunFinishedEvent(threadId: threadId, runId: runId)
        
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
            .runFinished,
            "eventType should always return .runFinished"
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
        assertJSONStructure(json, expectedType: "RUN_FINISHED", shouldOmitTimestamp: true)
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
        assertJSONStructure(json, expectedType: "RUN_FINISHED", expectedTimestamp: timestamp)
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
        assertJSONStructure(json, expectedType: "RUN_FINISHED", expectedTimestamp: timestamp)
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
            expectedType: "RUN_FINISHED",
            expectedThreadId: threadId,
            expectedRunId: runId,
            shouldOmitTimestamp: true
        )
    }
    
    // MARK: - Decoding Tests
    
    func testDecoding() throws {
        // Given
        let json = EventTestData.makeJSON(type: "RUN_FINISHED")
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        
        // When
        let event = try decoder.decode(RunFinishedEvent.self, from: data)
        
        // Then
        assertEventProperties(
            event,
            expectedThreadId: EventTestData.threadId,
            expectedRunId: EventTestData.runId,
            expectedTimestamp: nil,
        )
        XCTAssertEqual(
            event.eventType,
            .runFinished,
            "eventType should be .runFinished"
        )
    }
    
    func testDecodingWithTimestamp() throws {
        // Given
        let timestamp = EventTestData.timestamp
        let json = EventTestData.makeJSON(type: "RUN_FINISHED", timestamp: timestamp)
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        
        // When
        let event = try decoder.decode(RunFinishedEvent.self, from: data)
        
        // Then
        assertEventProperties(
            event,
            expectedThreadId: EventTestData.threadId,
            expectedRunId: EventTestData.runId,
            expectedTimestamp: timestamp
        )
        XCTAssertEqual(
            event.eventType,
            .runFinished,
            "eventType should be .runFinished"
        )
    }
    
    func testDecodingWithZeroTimestamp() throws {
        // Given
        let timestamp: Int64 = 0
        let json = EventTestData.makeJSON(type: "RUN_FINISHED", timestamp: timestamp)
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        
        // When
        let event = try decoder.decode(RunFinishedEvent.self, from: data)
        
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
        let json = EventTestData.makeJSON(type: "RUN_FINISHED", threadId: threadId, runId: runId)
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        
        // When
        let event = try decoder.decode(RunFinishedEvent.self, from: data)
        
        // Then
        XCTAssertEqual(event.threadId, threadId, "Should decode Unicode threadId")
        XCTAssertEqual(event.runId, runId, "Should decode Unicode runId")
    }
    
    // MARK: - Error Handling Tests
    
    func testDecodingFailsWithWrongType() {
        // Given
        let json = EventTestData.makeJSON(type: "RUN_STARTED") // Wrong type
        guard let data = try? JSONSerialization.data(withJSONObject: json) else {
            XCTFail("Failed to create JSON data")
            return
        }
        let decoder = JSONDecoder()
        
        // When & Then
        XCTAssertThrowsError(
            try decoder.decode(RunFinishedEvent.self, from: data),
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
                context.debugDescription.contains("RUN_FINISHED"),
                "Error should mention expected type RUN_FINISHED"
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
            try decoder.decode(RunFinishedEvent.self, from: data),
            "Should throw error when type field is missing"
        ) { error in
            assertDecodingError(error)
        }
    }
    
    func testDecodingFailsWithMissingThreadId() {
        // Given
        let json: [String: Any] = [
            "type": "RUN_FINISHED",
            "runId": EventTestData.runId
            // threadId is intentionally missing
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        
        // When & Then
        XCTAssertThrowsError(
            try decoder.decode(RunFinishedEvent.self, from: data),
            "Should throw error when threadId is missing"
        ) { error in
            assertDecodingError(error)
        }
    }
    
    func testDecodingFailsWithMissingRunId() {
        // Given
        let json: [String: Any] = [
            "type": "RUN_FINISHED",
            "threadId": EventTestData.threadId
            // runId is intentionally missing
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        
        // When & Then
        XCTAssertThrowsError(
            try decoder.decode(RunFinishedEvent.self, from: data),
            "Should throw error when runId is missing"
        ) { error in
            assertDecodingError(error)
        }
    }
    
    func testDecodingFailsWithInvalidTimestampType() {
        // Given
        let json: [String: Any] = [
            "type": "RUN_FINISHED",
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
            try decoder.decode(RunFinishedEvent.self, from: data),
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
            try decoder.decode(RunFinishedEvent.self, from: malformedData),
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
        let decodedEvent = try decoder.decode(RunFinishedEvent.self, from: encodedData)
        
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
    }
    
    func testRoundTripEncodingDecodingWithoutTimestamp() throws {
        // Given
        let originalEvent = makeEvent()
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // When
        let encodedData = try encoder.encode(originalEvent)
        let decodedEvent = try decoder.decode(RunFinishedEvent.self, from: encodedData)
        
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
        let decodedEvent = try decoder.decode(RunFinishedEvent.self, from: encodedData)
        
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
    ) -> RunFinishedEvent {
        RunFinishedEvent(
            threadId: threadId,
            runId: runId,
            timestamp: timestamp,
        )
    }
    
    // MARK: - Helper Methods
    
    private func assertEventProperties(
        _ event: RunFinishedEvent,
        expectedThreadId: String,
        expectedRunId: String,
        expectedTimestamp: Int64? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            event.threadId,
            expectedThreadId,
            "threadId should match expected value",
            file: file,
            line: line
        )
        XCTAssertEqual(
            event.runId,
            expectedRunId,
            "runId should match expected value",
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
    }
    
    private func assertJSONStructure(
        _ json: [String: Any],
        expectedType: String = "RUN_FINISHED",
        expectedThreadId: String = EventTestData.threadId,
        expectedRunId: String = EventTestData.runId,
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
            json["threadId"] as? String,
            expectedThreadId,
            "threadId should match expected value",
            file: file,
            line: line
        )
        XCTAssertEqual(
            json["runId"] as? String,
            expectedRunId,
            "runId should match expected value",
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
