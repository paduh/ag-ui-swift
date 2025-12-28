import XCTest
@testable import AGUICore

final class RunStartedEventTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        // Given
        let threadId = "thread-123"
        let runId = "run-456"
        
        // When
        let event = RunStartedEvent(threadId: threadId, runId: runId)
        
        // Then
        XCTAssertEqual(event.threadId, threadId)
        XCTAssertEqual(event.runId, runId)
        XCTAssertNil(event.timestamp)
        XCTAssertNil(event.rawEvent)
    }
    
    func testInitializationWithOptionalParameters() {
        // Given
        let threadId = "thread-123"
        let runId = "run-456"
        let timestamp: Int64 = 1234567890
        let rawEvent = "{\"test\": \"data\"}".data(using: .utf8)
        
        // When
        let event = RunStartedEvent(
            threadId: threadId,
            runId: runId,
            timestamp: timestamp,
            rawEvent: rawEvent
        )
        
        // Then
        XCTAssertEqual(event.threadId, threadId)
        XCTAssertEqual(event.runId, runId)
        XCTAssertEqual(event.timestamp, timestamp)
        XCTAssertEqual(event.rawEvent, rawEvent)
    }
    
    // MARK: - EventType Tests
    
    func testEventTypeProperty() {
        // Given
        let event = RunStartedEvent(threadId: "thread-123", runId: "run-456")
        
        // When & Then
        XCTAssertEqual(event.eventType, .runStarted)
    }
    
    // MARK: - Encoding Tests
    
    func testEncoding() throws {
        // Given
        let event = RunStartedEvent(threadId: "thread-123", runId: "run-456")
        let encoder = JSONEncoder()
        
        // When
        let data = try encoder.encode(event)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        // Then
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["type"] as? String, "RUN_STARTED")
        XCTAssertEqual(json?["threadId"] as? String, "thread-123")
        XCTAssertEqual(json?["runId"] as? String, "run-456")
        XCTAssertNil(json?["rawEvent"])
        // timestamp should be nil/omitted
        if let timestamp = json?["timestamp"] {
            XCTAssertNil(timestamp as? NSNull)
        }
    }
    
    func testEncodingWithTimestamp() throws {
        // Given
        let timestamp: Int64 = 1234567890
        let event = RunStartedEvent(
            threadId: "thread-123",
            runId: "run-456",
            timestamp: timestamp
        )
        let encoder = JSONEncoder()
        
        // When
        let data = try encoder.encode(event)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        // Then
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["type"] as? String, "RUN_STARTED")
        XCTAssertEqual(json?["threadId"] as? String, "thread-123")
        XCTAssertEqual(json?["runId"] as? String, "run-456")
        XCTAssertEqual(json?["timestamp"] as? Int64, timestamp)
    }
    
    func testEncodingOmitsRawEvent() throws {
        // Given
        let rawEvent = "{\"test\": \"data\"}".data(using: .utf8)
        let event = RunStartedEvent(
            threadId: "thread-123",
            runId: "run-456",
            rawEvent: rawEvent
        )
        let encoder = JSONEncoder()
        
        // When
        let data = try encoder.encode(event)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        // Then
        XCTAssertNotNil(json)
        XCTAssertNil(json?["rawEvent"], "rawEvent should not be encoded in JSON")
    }
    
    // MARK: - Decoding Tests
    
    func testDecoding() throws {
        // Given
        let json: [String: Any] = [
            "type": "RUN_STARTED",
            "threadId": "thread-123",
            "runId": "run-456"
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        
        // When
        let event = try decoder.decode(RunStartedEvent.self, from: data)
        
        // Then
        XCTAssertEqual(event.threadId, "thread-123")
        XCTAssertEqual(event.runId, "run-456")
        XCTAssertNil(event.timestamp)
        XCTAssertNil(event.rawEvent)
        XCTAssertEqual(event.eventType, .runStarted)
    }
    
    func testDecodingWithTimestamp() throws {
        // Given
        let timestamp: Int64 = 1234567890
        let json: [String: Any] = [
            "type": "RUN_STARTED",
            "threadId": "thread-123",
            "runId": "run-456",
            "timestamp": timestamp
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        
        // When
        let event = try decoder.decode(RunStartedEvent.self, from: data)
        
        // Then
        XCTAssertEqual(event.threadId, "thread-123")
        XCTAssertEqual(event.runId, "run-456")
        XCTAssertEqual(event.timestamp, timestamp)
        XCTAssertEqual(event.eventType, .runStarted)
    }
    
    func testDecodingWithoutTimestamp() throws {
        // Given
        let json: [String: Any] = [
            "type": "RUN_STARTED",
            "threadId": "thread-123",
            "runId": "run-456"
            // timestamp is omitted
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        
        // When
        let event = try decoder.decode(RunStartedEvent.self, from: data)
        
        // Then
        XCTAssertEqual(event.threadId, "thread-123")
        XCTAssertEqual(event.runId, "run-456")
        XCTAssertNil(event.timestamp, "timestamp should be nil when omitted from JSON")
    }
    
    // MARK: - Error Handling Tests
    
    func testDecodingFailsWithWrongType() {
        // Given
        let json: [String: Any] = [
            "type": "RUN_FINISHED", // Wrong type
            "threadId": "thread-123",
            "runId": "run-456"
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        
        // When & Then
        XCTAssertThrowsError(try decoder.decode(RunStartedEvent.self, from: data)) { error in
            guard let decodingError = error as? DecodingError,
                  case .dataCorrupted(let context) = decodingError else {
                XCTFail("Expected DecodingError.dataCorruptedError")
                return
            }
            XCTAssertTrue(context.debugDescription.contains("RUN_STARTED"))
            XCTAssertTrue(context.debugDescription.contains("RUN_FINISHED"))
        }
    }
    
    func testDecodingFailsWithMissingType() {
        // Given
        let json: [String: Any] = [
            // type is missing
            "threadId": "thread-123",
            "runId": "run-456"
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        
        // When & Then
        XCTAssertThrowsError(try decoder.decode(RunStartedEvent.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError, "Should throw DecodingError")
        }
    }
    
    func testDecodingFailsWithMissingRequiredFields() {
        // Test missing threadId
        do {
            let json: [String: Any] = [
                "type": "RUN_STARTED",
                "runId": "run-456"
                // threadId is missing
            ]
            let data = try JSONSerialization.data(withJSONObject: json)
            let decoder = JSONDecoder()
            _ = try decoder.decode(RunStartedEvent.self, from: data)
            XCTFail("Should throw error when threadId is missing")
        } catch {
            XCTAssertTrue(error is DecodingError)
        }
        
        // Test missing runId
        do {
            let json: [String: Any] = [
                "type": "RUN_STARTED",
                "threadId": "thread-123"
                // runId is missing
            ]
            let data = try JSONSerialization.data(withJSONObject: json)
            let decoder = JSONDecoder()
            _ = try decoder.decode(RunStartedEvent.self, from: data)
            XCTFail("Should throw error when runId is missing")
        } catch {
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    // MARK: - Round-Trip Tests
    
    func testRoundTripEncodingDecoding() throws {
        // Given
        let originalEvent = RunStartedEvent(
            threadId: "thread-123",
            runId: "run-456",
            timestamp: 1234567890
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // When
        let encodedData = try encoder.encode(originalEvent)
        let decodedEvent = try decoder.decode(RunStartedEvent.self, from: encodedData)
        
        // Then
        XCTAssertEqual(decodedEvent.threadId, originalEvent.threadId)
        XCTAssertEqual(decodedEvent.runId, originalEvent.runId)
        XCTAssertEqual(decodedEvent.timestamp, originalEvent.timestamp)
        XCTAssertEqual(decodedEvent.eventType, originalEvent.eventType)
        // Note: rawEvent will be nil after round-trip as per implementation
    }
    
    func testRoundTripEncodingDecodingWithoutTimestamp() throws {
        // Given
        let originalEvent = RunStartedEvent(
            threadId: "thread-123",
            runId: "run-456"
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // When
        let encodedData = try encoder.encode(originalEvent)
        let decodedEvent = try decoder.decode(RunStartedEvent.self, from: encodedData)
        
        // Then
        XCTAssertEqual(decodedEvent.threadId, originalEvent.threadId)
        XCTAssertEqual(decodedEvent.runId, originalEvent.runId)
        XCTAssertNil(decodedEvent.timestamp)
        XCTAssertEqual(decodedEvent.eventType, originalEvent.eventType)
    }
}

