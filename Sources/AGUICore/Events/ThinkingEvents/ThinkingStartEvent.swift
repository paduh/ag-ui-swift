import Foundation

/// Event indicating the start of a thinking step.
///
/// This event marks the beginning of the agent's internal reasoning or thinking
/// process. During thinking, the agent may generate internal thoughts that are
/// not immediately shown to the user but help guide its decision-making.
///
/// - SeeAlso: `ThinkingEndEvent`, `ThinkingTextMessageStartEvent`
public struct ThinkingStartEvent: AGUIEvent, Equatable, Hashable, Sendable {

    // MARK: - Properties

    /// Optional timestamp when the thinking started.
    ///
    /// Represented as milliseconds since Unix epoch.
    public let timestamp: Int64?

    /// Optional raw event data as received from the agent.
    public let rawEvent: Data?

    /// The type of this event (always `.thinkingStart`).
    public var eventType: EventType { .thinkingStart }

    // MARK: - Initialization

    /// Creates a new `ThinkingStartEvent`.
    ///
    /// - Parameters:
    ///   - timestamp: Optional timestamp in milliseconds since epoch
    ///   - rawEvent: Optional raw event data as received from the agent
    public init(
        timestamp: Int64? = nil,
        rawEvent: Data? = nil
    ) {
        self.timestamp = timestamp
        self.rawEvent = rawEvent
    }
}

// MARK: - CustomStringConvertible
extension ThinkingStartEvent: CustomStringConvertible {
    public var description: String {
        "ThinkingStartEvent(timestamp: \(timestamp?.description ?? "nil"))"
    }
}

// MARK: - CustomDebugStringConvertible
extension ThinkingStartEvent: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        ThinkingStartEvent {
            timestamp: \(timestamp.map(String.init) ?? "nil")
            eventType: \(eventType.rawValue)
        }
        """
    }
}
