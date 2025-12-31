import Foundation

/// Event indicating that a new agent run has started.
///
/// This event is emitted when an agent begins processing a new run request.
/// It provides the thread and run identifiers that will be used throughout
/// the execution lifecycle.
///
/// - Parameters:
///   - threadId: The identifier for the conversation thread
///   - runId: The unique identifier for this specific run
///   - timestamp: Optional timestamp when the run started (milliseconds since epoch)
public struct RunStartedEvent: AGUIEvent {
    /// The identifier for the conversation thread
    public let threadId: String
    
    /// The unique identifier for this specific run
    public let runId: String
    
    /// Optional timestamp indicating when the run started.
    ///
    /// The timestamp is represented as milliseconds since epoch (Unix timestamp).
    public let timestamp: Int64?
    
    /// The type of this event.
    ///
    /// This is a computed property that always returns `.runStarted`.
    /// The actual "type" field in JSON is handled by the Codable implementation.
    public var eventType: EventType {
        return .runStarted
    }
    
    /// Creates a new `RunStartedEvent`.
    ///
    /// - Parameters:
    ///   - threadId: The identifier for the conversation thread
    ///   - runId: The unique identifier for this specific run
    ///   - timestamp: Optional timestamp when the run started (default: `nil`)
    public init(
        threadId: String,
        runId: String,
        timestamp: Int64? = nil
    ) {
        self.threadId = threadId
        self.runId = runId
        self.timestamp = timestamp
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case type
        case threadId
        case runId
        case timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Verify the type field matches using helper
        try Self.verifyType(in: container, expected: .runStarted, typeKey: .type)
        
        self.threadId = try container.decode(String.self, forKey: .threadId)
        self.runId = try container.decode(String.self, forKey: .runId)
        self.timestamp = try container.decodeIfPresent(Int64.self, forKey: .timestamp)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try encodeType(to: &container, typeKey: .type)
        try container.encode(threadId, forKey: .threadId)
        try container.encode(runId, forKey: .runId)
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
    }
}
