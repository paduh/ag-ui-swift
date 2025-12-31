import Foundation

/// Event indicating that a new execution step has started.
///
/// Steps represent discrete phases of agent execution, such as reasoning,
/// tool calling, or response generation. This event marks the beginning
/// of a named step in the agent's workflow.
///
/// - Parameters:
///   - stepName: The name of the step that has started
///   - timestamp: Optional timestamp when the step started (milliseconds since epoch)
public struct StepStartedEvent: AGUIEvent {
    /// The name of the step that has started.
    public let stepName: String
    
    /// Optional timestamp indicating when the step started.
    ///
    /// The timestamp is represented as milliseconds since epoch (Unix timestamp).
    public let timestamp: Int64?
    
    /// The type of this event.
    ///
    /// This is a computed property that always returns `.stepStarted`.
    /// The actual "type" field in JSON is handled by the Codable implementation.
    public var eventType: EventType {
        return .stepStarted
    }
    
    /// Creates a new `StepStartedEvent`.
    ///
    /// - Parameters:
    ///   - stepName: The name of the step that has started
    ///   - timestamp: Optional timestamp when the step started (default: `nil`)
    public init(
        stepName: String,
        timestamp: Int64? = nil
    ) {
        self.stepName = stepName
        self.timestamp = timestamp
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case type
        case stepName
        case timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Verify the type field matches using helper
        try Self.verifyType(in: container, expected: .stepStarted, typeKey: .type)
        
        self.stepName = try container.decode(String.self, forKey: .stepName)
        self.timestamp = try container.decodeIfPresent(Int64.self, forKey: .timestamp)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try encodeType(to: &container, typeKey: .type)
        try container.encode(stepName, forKey: .stepName)
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
    }
}


