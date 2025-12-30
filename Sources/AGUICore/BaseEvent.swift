import Foundation

/// Base protocol for all events in the AG-UI protocol.
///
/// Events represent real-time notifications from agents about their execution state,
/// message generation, tool calls, and state changes. All events follow a common
/// structure with polymorphic serialization based on the "type" field.
///
/// Key Properties:
/// - `eventType`: The specific type of event (used for pattern matching)
/// - `timestamp`: Optional timestamp of when the event occurred
/// - `rawEvent`: Optional raw JSON representation for debugging/logging
///
/// Event Categories:
/// - Lifecycle Events: Run and step start/finish/error events
/// - Text Message Events: Streaming text message generation
/// - Tool Call Events: Tool invocation and argument streaming
/// - State Management Events: State snapshots and incremental updates
/// - Special Events: Raw and custom event types
///
/// Serialization:
/// Uses polymorphic serialization where the "type" field determines which
/// specific event type to deserialize to.
///
/// - SeeAlso: `EventType`
public protocol BaseEvent: Codable {
    /// The type of this event.
    ///
    /// This property is used for pattern matching and event handling logic.
    /// The actual "type" field in JSON is used for polymorphic decoding.
    ///
    /// - SeeAlso: `EventType`
    var eventType: EventType { get }
    
    /// Optional timestamp indicating when this event occurred.
    ///
    /// The timestamp is represented as milliseconds since epoch (Unix timestamp).
    /// This field may be nil if timing information is not available or relevant.
    ///
    /// Note: The protocol specification varies between implementations regarding
    /// timestamp format, but Int64 (milliseconds) is used here for consistency
    /// with standard timestamp conventions.
    var timestamp: Int64? { get }
    
    /// Optional raw JSON representation of the original event.
    ///
    /// This field preserves the original JSON structure of the event as received
    /// from the agent. It can be useful for debugging, logging, or handling
    /// protocol extensions that aren't yet supported by the typed event classes.
    ///
    /// The raw JSON is stored as `Data` to preserve the exact structure and allow
    /// for re-parsing or inspection without losing information.
    var rawEvent: Data? { get }
}
