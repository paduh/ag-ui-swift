import Foundation
@testable import AGUICore

/// Shared test data constants and factory methods for event tests
enum EventTestData {
    static let threadId = "thread-123"
    static let runId = "run-456"
    static let timestamp: Int64 = 1234567890
    
    /// Creates a JSON dictionary for event testing
    /// - Parameters:
    ///   - type: The event type string (e.g., "RUN_STARTED", "RUN_FINISHED", "RUN_ERROR")
    ///   - threadId: The thread ID (default: EventTestData.threadId, ignored if additionalFields provided)
    ///   - runId: The run ID (default: EventTestData.runId, ignored if additionalFields provided)
    ///   - timestamp: Optional timestamp
    ///   - additionalFields: Additional fields to include in JSON (overrides threadId/runId if provided)
    /// - Returns: A dictionary representing the event JSON
    static func makeJSON(
        type: String,
        threadId: String = EventTestData.threadId,
        runId: String = EventTestData.runId,
        timestamp: Int64? = nil,
        additionalFields: [String: Any]? = nil
    ) -> [String: Any] {
        var json: [String: Any] = [
            "type": type
        ]
        
        // Use additionalFields if provided, otherwise use threadId/runId
        if let additionalFields = additionalFields {
            json.merge(additionalFields) { (_, new) in new }
        } else {
            json["threadId"] = threadId
            json["runId"] = runId
        }
        
        if let timestamp = timestamp {
            json["timestamp"] = timestamp
        }
        return json
    }
}