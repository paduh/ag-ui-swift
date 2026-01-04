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

    /// Optional title or description for the thinking step.
    ///
    /// Provides context about what the agent is thinking about or reasoning through.
    public let title: String?

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
    ///   - title: Optional title/description for the thinking step
    ///   - timestamp: Optional timestamp in milliseconds since epoch
    ///   - rawEvent: Optional raw event data as received from the agent
    public init(
        title: String? = nil,
        timestamp: Int64? = nil,
        rawEvent: Data? = nil
    ) {
        self.title = title
        self.timestamp = timestamp
        self.rawEvent = rawEvent
    }
}

// MARK: - CustomStringConvertible
extension ThinkingStartEvent: CustomStringConvertible {
    public var description: String {
        let titleDesc = title.map { "\"\($0)\"" } ?? "nil"
        return "ThinkingStartEvent(title: \(titleDesc), timestamp: \(timestamp?.description ?? "nil"))"
    }
}

// MARK: - CustomDebugStringConvertible
extension ThinkingStartEvent: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        ThinkingStartEvent {
            title: \(title.map { "\"\($0)\"" } ?? "nil")
            timestamp: \(timestamp.map(String.init) ?? "nil")
            eventType: \(eventType.rawValue)
        }
        """
    }
}
