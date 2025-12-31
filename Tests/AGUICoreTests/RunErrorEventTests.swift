import XCTest
@testable import AGUICore

final class RunErrorEventTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        // Given
        let message = "An error occurred"
        
        // When
        let event = RunErrorEvent(message: message)
        
        // Then
        assertRunErrorEventProperties(
            event,
            expectedMessage: message,
            expectedCode: nil,
            expectedTimestamp: nil,
        )
    }
    
    func testInitializationWithOptionalParameters() {
        // Given
        let message = "An error occurred"
        let code = "ERROR_CODE_123"
        let timestamp = EventTestData.timestamp
        // When
        let event = RunErrorEvent(
            message: message,
            code: code,
            timestamp: timestamp
        )
        
        // Then
        assertRunErrorEventProperties(
            event,
            expectedMessage: message,
            expectedCode: code,
            expectedTimestamp: timestamp
        )
    }
    
    func testInitializationWithEmptyMessage() {
        // Given
        let message = ""
        
        // When
        let event = RunErrorEvent(message: message)
        
        // Then
        XCTAssertEqual(event.message, message, "Should accept empty message")
    }
    
    func testInitializationWithUnicodeCharacters() {
        // Given
        let message = "错误发生: 🚨"
        let code = "错误代码-测试"
        
        // When
        let event = RunErrorEvent(message: message, code: code)
        
        // Then
        assertRunErrorEventProperties(
            event,
            expectedMessage: message,
            expectedCode: code,
            expectedTimestamp: nil,
        )
    }
    
    // MARK: - EventType Tests
    
    func testEventTypeProperty() {
        // Given
        let event = makeEvent()
        
        // When & Then
        XCTAssertEqual(
            event.eventType,
            .runError,
            "eventType should always return .runError"
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
        assertRunErrorEventJSONStructure(json, expectedType: "RUN_ERROR", shouldOmitTimestamp: true)
    }
    
    func testEncodingWithAllFields() throws {
        // Given
        let message = "An error occurred"
        let code = "ERROR_CODE_123"
        let timestamp = EventTestData.timestamp
        let event = makeEvent(message: message, code: code, timestamp: timestamp)
        let encoder = JSONEncoder()
        
        // When
        let data = try encoder.encode(event)
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any],
            "JSON should be valid dictionary"
        )
        
        // Then
        assertRunErrorEventJSONStructure(
            json,
            expectedType: "RUN_ERROR",
            expectedMessage: message,
            expectedCode: code,
            expectedTimestamp: timestamp
        )
    }
    
    func testEncodingOmitsNilCode() throws {
        // Given
        let event = makeEvent(code: nil)
        let encoder = JSONEncoder()
        
        // When
        let data = try encoder.encode(event)
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any],
            "JSON should be valid dictionary"
        )
        
        // Then
        XCTAssertNil(
            json["code"],
            "code should be omitted when nil"
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
        assertRunErrorEventJSONStructure(json, expectedType: "RUN_ERROR", expectedTimestamp: timestamp)
    }
    
    func testEncodingWithUnicodeMessage() throws {
        // Given
        let message = "错误发生: 🚨"
        let code = "错误代码"
        let event = makeEvent(message: message, code: code)
        let encoder = JSONEncoder()
        
        // When
        let data = try encoder.encode(event)
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any],
            "JSON should be valid dictionary"
        )
        
        // Then
        assertRunErrorEventJSONStructure(
            json,
            expectedType: "RUN_ERROR",
            expectedMessage: message,
            expectedCode: code,
            shouldOmitTimestamp: true
        )
    }
    
    // MARK: - Decoding Tests
    
    func testDecoding() throws {
        // Given
        let message = "An error occurred"
        let json = EventTestData.makeJSON(type: "RUN_ERROR", additionalFields: ["message": message])
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        
        // When
        let event = try decoder.decode(RunErrorEvent.self, from: data)
        
        // Then
        assertRunErrorEventProperties(
            event,
            expectedMessage: message,
            expectedCode: nil,
            expectedTimestamp: nil,
        )
        XCTAssertEqual(event.eventType, .runError, "eventType should be .runError")
    }
    
    func testDecodingWithAllFields() throws {
        // Given
        let message = "An error occurred"
        let code = "ERROR_CODE_123"
        let timestamp = EventTestData.timestamp
        let json = EventTestData.makeJSON(
            type: "RUN_ERROR",
            timestamp: timestamp,
            additionalFields: [
                "message": message,
                "code": code
            ]
        )
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        
        // When
        let event = try decoder.decode(RunErrorEvent.self, from: data)
        
        // Then
        assertRunErrorEventProperties(
            event,
            expectedMessage: message,
            expectedCode: code,
            expectedTimestamp: timestamp,
        )
        XCTAssertEqual(event.eventType, .runError, "eventType should be .runError")
    }
    
    func testDecodingWithCode() throws {
        // Given
        let message = "An error occurred"
        let code = "ERROR_CODE_123"
        let json = EventTestData.makeJSON(
            type: "RUN_ERROR",
            additionalFields: [
                "message": message,
                "code": code
            ]
        )
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        
        // When
        let event = try decoder.decode(RunErrorEvent.self, from: data)
        
        // Then
        assertRunErrorEventProperties(
            event,
            expectedMessage: message,
            expectedCode: code,
            expectedTimestamp: nil,
        )
    }
    
    func testDecodingWithZeroTimestamp() throws {
        // Given
        let message = "An error occurred"
        let timestamp: Int64 = 0
        let json = EventTestData.makeJSON(
            type: "RUN_ERROR",
            timestamp: timestamp,
            additionalFields: ["message": message]
        )
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        
        // When
        let event = try decoder.decode(RunErrorEvent.self, from: data)
        
        // Then
        XCTAssertEqual(
            event.timestamp,
            timestamp,
            "Should decode zero timestamp correctly"
        )
    }
    
    func testDecodingWithUnicodeMessage() throws {
        // Given
        let message = "错误发生: 🚨"
        let code = "错误代码"
        let json = EventTestData.makeJSON(
            type: "RUN_ERROR",
            additionalFields: [
                "message": message,
                "code": code
            ]
        )
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        
        // When
        let event = try decoder.decode(RunErrorEvent.self, from: data)
        
        // Then
        assertRunErrorEventProperties(
            event,
            expectedMessage: message,
            expectedCode: code,
            expectedTimestamp: nil,
        )
    }
    
    // MARK: - Error Handling Tests
    
    func testDecodingFailsWithWrongType() {
        // Given
        let json = EventTestData.makeJSON(
            type: "RUN_STARTED",
            additionalFields: ["message": "An error occurred"]
        )
        guard let data = try? JSONSerialization.data(withJSONObject: json) else {
            XCTFail("Failed to create JSON data")
            return
        }
        let decoder = JSONDecoder()
        
        // When & Then
        XCTAssertThrowsError(
            try decoder.decode(RunErrorEvent.self, from: data),
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
                context.debugDescription.contains("RUN_ERROR"),
                "Error should mention expected type RUN_ERROR"
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
            "message": "An error occurred"
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: json) else {
            XCTFail("Failed to create JSON data")
            return
        }
        let decoder = JSONDecoder()
        
        // When & Then
        XCTAssertThrowsError(
            try decoder.decode(RunErrorEvent.self, from: data),
            "Should throw error when type field is missing"
        ) { error in
            assertDecodingError(error)
        }
    }
    
    func testDecodingFailsWithMissingMessage() {
        // Given
        let json: [String: Any] = [
            "type": "RUN_ERROR"
            // message is intentionally missing
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        
        // When & Then
        XCTAssertThrowsError(
            try decoder.decode(RunErrorEvent.self, from: data),
            "Should throw error when message is missing"
        ) { error in
            assertDecodingError(error)
        }
    }
    
    func testDecodingFailsWithInvalidTimestampType() {
        // Given
        let json: [String: Any] = [
            "type": "RUN_ERROR",
            "message": "An error occurred",
            "timestamp": "invalid" // Should be Int64, not String
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: json) else {
            XCTFail("Failed to create JSON data")
            return
        }
        let decoder = JSONDecoder()
        
        // When & Then
        XCTAssertThrowsError(
            try decoder.decode(RunErrorEvent.self, from: data),
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
            try decoder.decode(RunErrorEvent.self, from: malformedData),
            "Should throw error when JSON is malformed"
        ) { error in
            assertDecodingError(error)
        }
    }
    
    // MARK: - Round-Trip Tests
    
    func testRoundTripEncodingDecoding() throws {
        // Given
        let originalEvent = makeEvent(
            message: "An error occurred",
            code: "ERROR_CODE_123",
            timestamp: EventTestData.timestamp
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // When
        let encodedData = try encoder.encode(originalEvent)
        let decodedEvent = try decoder.decode(RunErrorEvent.self, from: encodedData)
        
        // Then
        assertRunErrorEventProperties(
            decodedEvent,
            expectedMessage: originalEvent.message,
            expectedCode: originalEvent.code,
            expectedTimestamp: originalEvent.timestamp
        )
        XCTAssertEqual(
            decodedEvent.eventType,
            originalEvent.eventType,
            "eventType should match after round-trip"
        )
    }
    
    func testRoundTripEncodingDecodingWithoutOptionalFields() throws {
        // Given
        let originalEvent = makeEvent(message: "An error occurred")
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // When
        let encodedData = try encoder.encode(originalEvent)
        let decodedEvent = try decoder.decode(RunErrorEvent.self, from: encodedData)
        
        // Then
        assertRunErrorEventProperties(
            decodedEvent,
            expectedMessage: originalEvent.message,
            expectedCode: nil,
            expectedTimestamp: nil,
        )
        XCTAssertEqual(
            decodedEvent.eventType,
            originalEvent.eventType,
            "eventType should match after round-trip"
        )
    }
    
    func testRoundTripWithUnicodeMessage() throws {
        // Given
        let message = "错误发生: 🚨"
        let code = "错误代码"
        let originalEvent = makeEvent(message: message, code: code)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // When
        let encodedData = try encoder.encode(originalEvent)
        let decodedEvent = try decoder.decode(RunErrorEvent.self, from: encodedData)
        
        // Then
        assertRunErrorEventProperties(
            decodedEvent,
            expectedMessage: originalEvent.message,
            expectedCode: originalEvent.code,
            expectedTimestamp: nil,
        )
    }
    
    // MARK: - Event-Specific Factory Methods
    
    private func makeEvent(
        message: String = "An error occurred",
        code: String? = nil,
        timestamp: Int64? = nil,
    ) -> RunErrorEvent {
        RunErrorEvent(
            message: message,
            code: code,
            timestamp: timestamp,
        )
    }
    
    // MARK: - Event-Specific Helper Methods
    
    private func assertRunErrorEventProperties(
        _ event: RunErrorEvent,
        expectedMessage: String,
        expectedCode: String? = nil,
        expectedTimestamp: Int64? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            event.message,
            expectedMessage,
            "message should match expected value",
            file: file,
            line: line
        )
        XCTAssertEqual(
            event.code,
            expectedCode,
            "code should match expected value",
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
    
    private func assertRunErrorEventJSONStructure(
        _ json: [String: Any],
        expectedType: String,
        expectedMessage: String? = nil,
        expectedCode: String? = nil,
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
        
        if let expectedMessage = expectedMessage {
            XCTAssertEqual(
                json["message"] as? String,
                expectedMessage,
                "message should match expected value",
                file: file,
                line: line
            )
        }
        
        if let expectedCode = expectedCode {
            XCTAssertEqual(
                json["code"] as? String,
                expectedCode,
                "code should match expected value",
                file: file,
                line: line
            )
        } else {
            // Code should be omitted or NSNull when not expected
            // If code exists in JSON, it should be NSNull (not a String value)
            if let codeValue = json["code"] {
                XCTAssertTrue(
                    codeValue is NSNull,
                    "code should be omitted or NSNull when not expected, but found: \(codeValue)",
                    file: file,
                    line: line
                )
            }
            // If code doesn't exist, that's also fine - no assertion needed
        }
        
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

