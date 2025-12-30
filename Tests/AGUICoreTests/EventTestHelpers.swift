import XCTest
@testable import AGUICore

/// Shared helper methods for event tests
extension XCTestCase {
    
    /// Asserts that an event's properties match expected values
    /// - Parameters:
    ///   - event: The event to verify
    ///   - expectedThreadId: Expected thread ID
    ///   - expectedRunId: Expected run ID
    ///   - expectedTimestamp: Expected timestamp (nil if not set)
    ///   - expectedRawEvent: Expected raw event data (nil if not set)
    ///   - file: File name for error reporting
    ///   - line: Line number for error reporting
    func assertEventProperties(
        _ event: BaseEvent,
        expectedThreadId: String,
        expectedRunId: String,
        expectedTimestamp: Int64? = nil,
        expectedRawEvent: Data? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        // Use reflection or type casting to access properties
        // Since BaseEvent protocol doesn't expose these directly, we'll need to check the concrete type
        if let runStartedEvent = event as? RunStartedEvent {
            XCTAssertEqual(
                runStartedEvent.threadId,
                expectedThreadId,
                "threadId should match expected value",
                file: file,
                line: line
            )
            XCTAssertEqual(
                runStartedEvent.runId,
                expectedRunId,
                "runId should match expected value",
                file: file,
                line: line
            )
            XCTAssertEqual(
                runStartedEvent.timestamp,
                expectedTimestamp,
                "timestamp should match expected value",
                file: file,
                line: line
            )
            XCTAssertEqual(
                runStartedEvent.rawEvent,
                expectedRawEvent,
                "rawEvent should match expected value",
                file: file,
                line: line
            )
        } else if let runFinishedEvent = event as? RunFinishedEvent {
            XCTAssertEqual(
                runFinishedEvent.threadId,
                expectedThreadId,
                "threadId should match expected value",
                file: file,
                line: line
            )
            XCTAssertEqual(
                runFinishedEvent.runId,
                expectedRunId,
                "runId should match expected value",
                file: file,
                line: line
            )
            XCTAssertEqual(
                runFinishedEvent.timestamp,
                expectedTimestamp,
                "timestamp should match expected value",
                file: file,
                line: line
            )
            XCTAssertEqual(
                runFinishedEvent.rawEvent,
                expectedRawEvent,
                "rawEvent should match expected value",
                file: file,
                line: line
            )
        } else {
            XCTFail(
                "Event type not supported by assertEventProperties helper",
                file: file,
                line: line
            )
        }
    }
    
    /// Asserts the structure of a JSON dictionary representing an event
    /// - Parameters:
    ///   - json: The JSON dictionary to verify
    ///   - expectedType: Expected event type string
    ///   - expectedThreadId: Expected thread ID
    ///   - expectedRunId: Expected run ID
    ///   - expectedTimestamp: Expected timestamp (nil if not present)
    ///   - shouldOmitTimestamp: Whether timestamp should be omitted from JSON
    ///   - file: File name for error reporting
    ///   - line: Line number for error reporting
    func assertJSONStructure(
        _ json: [String: Any],
        expectedType: String,
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
        
        XCTAssertNil(
            json["rawEvent"],
            "rawEvent should not be encoded in JSON",
            file: file,
            line: line
        )
    }
    
    /// Asserts that an error is a DecodingError
    /// - Parameters:
    ///   - error: The error to verify
    ///   - file: File name for error reporting
    ///   - line: Line number for error reporting
    func assertDecodingError(
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

