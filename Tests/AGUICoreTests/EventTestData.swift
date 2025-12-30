import Foundation
@testable import AGUICore

/// Shared test data constants and factory methods for event tests
enum EventTestData {
    static let threadId = "thread-123"
    static let runId = "run-456"
    static let timestamp: Int64 = 1234567890
    static let rawEventData = Data("{\"test\": \"data\"}".utf8)
    
    /// Creates a JSON dictionary for event testing
    /// - Parameters:
    ///   - type: The event type string (e.g., "RUN_STARTED", "RUN_FINISHED")
    ///   - threadId: The thread ID (default: EventTestData.threadId)
    ///   - runId: The run ID (default: EventTestData.runId)
    ///   - timestamp: Optional timestamp
    /// - Returns: A dictionary representing the event JSON
    static func makeJSON(
        type: String,
        threadId: String = EventTestData.threadId,
        runId: String = EventTestData.runId,
        timestamp: Int64? = nil
    ) -> [String: Any] {
        var json: [String: Any] = [
            "type": type,
            "threadId": threadId,
            "runId": runId
        ]
        if let timestamp = timestamp {
            json["timestamp"] = timestamp
        }
        return json
    }
}