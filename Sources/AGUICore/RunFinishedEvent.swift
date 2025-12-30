import Foundation

/// Event indicating that an agent run has completed successfully.
///
/// This event is emitted when an agent has finished processing a run request
/// and has generated all output. It signals the end of the execution lifecycle.
///
/// - Parameters:
///   - threadId: The identifier for the conversation thread
///   - runId: The unique identifier for the completed run
///   - timestamp: Optional timestamp when the run finished (milliseconds since epoch)
///   - rawEvent: Optional raw JSON representation of the event
public struct RunFinishedEvent: BaseEvent {
    /// The identifier for the conversation thread
    public let threadId: String
    
    /// The unique identifier for the completed run
    public let runId: String
    
    /// Optional timestamp indicating when the run finished.
    ///
    /// The timestamp is represented as milliseconds since epoch (Unix timestamp).
    public let timestamp: Int64?
    
    /// Optional raw JSON representation of the original event.
    ///
    /// This field preserves the original JSON structure of the event as received
    /// from the agent. It can be useful for debugging, logging, or handling
    /// protocol extensions that aren't yet supported by the typed event classes.
    public let rawEvent: Data?
    
    /// The type of this event.
    ///
    /// This is a computed property that always returns `.runFinished`.
    /// The actual "type" field in JSON is handled by the Codable implementation.
    public var eventType: EventType {
        return .runFinished
    }
    
    /// Creates a new `RunFinishedEvent`.
    ///
    /// - Parameters:
    ///   - threadId: The identifier for the conversation thread
    ///   - runId: The unique identifier for the completed run
    ///   - timestamp: Optional timestamp when the run finished (default: `nil`)
    ///   - rawEvent: Optional raw JSON representation (default: `nil`)
    public init(
        threadId: String,
        runId: String,
        timestamp: Int64? = nil,
        rawEvent: Data? = nil
    ) {
        self.threadId = threadId
        self.runId = runId
        self.timestamp = timestamp
        self.rawEvent = rawEvent
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
        try Self.verifyType(in: container, expected: .runFinished, typeKey: .type)
        
        self.threadId = try container.decode(String.self, forKey: .threadId)
        self.runId = try container.decode(String.self, forKey: .runId)
        self.timestamp = try container.decodeIfPresent(Int64.self, forKey: .timestamp)
        
        // rawEvent is typically set by EventDecoder which has access to original data
        // When decoding via Codable directly, rawEvent will be nil unless provided
        // via the public initializer
        self.rawEvent = nil
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try encodeType(to: &container, typeKey: .type)
        try container.encode(threadId, forKey: .threadId)
        try container.encode(runId, forKey: .runId)
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
    }
}
