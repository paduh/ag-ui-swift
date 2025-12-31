import Foundation

/// Event indicating that an agent run has encountered an error.
///
/// This event is emitted when an agent run fails due to an unrecoverable error.
/// It provides error details and optional error codes for debugging and handling.
///
/// - Parameters:
///   - message: Human-readable error message describing what went wrong
///   - code: Optional error code for programmatic error handling
///   - timestamp: Optional timestamp when the error occurred (milliseconds since epoch)
public struct RunErrorEvent: AGUIEvent {
    /// Human-readable error message describing what went wrong.
    public let message: String
    
    /// Optional error code for programmatic error handling.
    ///
    /// This field can be used to identify specific error types programmatically,
    /// allowing clients to handle different error scenarios appropriately.
    public let code: String?
    
    /// Optional timestamp indicating when the error occurred.
    ///
    /// The timestamp is represented as milliseconds since epoch (Unix timestamp).
    public let timestamp: Int64?
    
    /// The type of this event.
    ///
    /// This is a computed property that always returns `.runError`.
    /// The actual "type" field in JSON is handled by the Codable implementation.
    public var eventType: EventType {
        return .runError
    }
    
    /// Creates a new `RunErrorEvent`.
    ///
    /// - Parameters:
    ///   - message: Human-readable error message describing what went wrong
    ///   - code: Optional error code for programmatic error handling (default: `nil`)
    ///   - timestamp: Optional timestamp when the error occurred (default: `nil`)
    public init(
        message: String,
        code: String? = nil,
        timestamp: Int64? = nil
    ) {
        self.message = message
        self.code = code
        self.timestamp = timestamp
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case type
        case message
        case code
        case timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Verify the type field matches using helper
        try Self.verifyType(in: container, expected: .runError, typeKey: .type)
        
        self.message = try container.decode(String.self, forKey: .message)
        self.code = try container.decodeIfPresent(String.self, forKey: .code)
        self.timestamp = try container.decodeIfPresent(Int64.self, forKey: .timestamp)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try encodeType(to: &container, typeKey: .type)
        try container.encode(message, forKey: .message)
        try container.encodeIfPresent(code, forKey: .code)
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
    }
}
