import Foundation

/// Event indicating the start of a thinking text message.
///
/// This event marks the beginning of a thinking message generation during the agent's
/// internal reasoning process. Thinking messages contain the agent's internal thoughts
/// that may be shown to help users understand the reasoning process.
///
/// - SeeAlso: `ThinkingTextMessageContentEvent`, `ThinkingTextMessageEndEvent`
public struct ThinkingTextMessageStartEvent: AGUIEvent, Equatable, Hashable, Sendable {

    // MARK: - Properties

    /// Optional timestamp when the thinking message generation started.
    ///
    /// Represented as milliseconds since Unix epoch.
    public let timestamp: Int64?

    /// Optional raw event data as received from the agent.
    public let rawEvent: Data?

    /// The type of this event (always `.thinkingTextMessageStart`).
    public var eventType: EventType { .thinkingTextMessageStart }

    // MARK: - Initialization

    /// Creates a new `ThinkingTextMessageStartEvent`.
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
extension ThinkingTextMessageStartEvent: CustomStringConvertible {
    public var description: String {
        "ThinkingTextMessageStartEvent(timestamp: \(timestamp?.description ?? "nil"))"
    }
}

// MARK: - CustomDebugStringConvertible
extension ThinkingTextMessageStartEvent: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        ThinkingTextMessageStartEvent {
            timestamp: \(timestamp.map(String.init) ?? "nil")
            eventType: \(eventType.rawValue)
        }
        """
    }
}
