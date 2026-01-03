import Foundation

/// Event indicating that text message generation has started.
///
/// This event is emitted when an agent begins generating a text message response.
/// It provides the message identifier that will be used to associate subsequent
/// content chunks and the end event with this message.
///
/// - SeeAlso: `TextMessageContentEvent`, `TextMessageEndEvent`, `TextMessageChunkEvent`
public struct TextMessageStartEvent: AGUIEvent, Equatable, Hashable, Sendable {

    // MARK: - Properties

    /// The unique identifier for this message.
    ///
    /// This ID is used to associate content chunks and the end event
    /// with this specific message instance.
    public let messageId: String

    /// The role of the message sender (always "assistant" for agent messages).
    public let role: String

    /// Optional timestamp when the message generation started.
    ///
    /// Represented as milliseconds since Unix epoch.
    public let timestamp: Int64?

    /// Optional raw event data as received from the agent.
    public let rawEvent: Data?

    /// The type of this event (always `.textMessageStart`).
    public var eventType: EventType { .textMessageStart }

    // MARK: - Initialization

    /// Creates a new `TextMessageStartEvent`.
    ///
    /// - Parameters:
    ///   - messageId: The unique identifier for this message
    ///   - role: The role of the message sender (typically "assistant")
    ///   - timestamp: Optional timestamp in milliseconds since epoch
    ///   - rawEvent: Optional raw event data as received from the agent
    public init(
        messageId: String,
        role: String = "assistant",
        timestamp: Int64? = nil,
        rawEvent: Data? = nil
    ) {
        self.messageId = messageId
        self.role = role
        self.timestamp = timestamp
        self.rawEvent = rawEvent
    }
}

// MARK: - CustomStringConvertible
extension TextMessageStartEvent: CustomStringConvertible {
    public var description: String {
        "TextMessageStartEvent(messageId: \(messageId), role: \(role), timestamp: \(timestamp?.description ?? "nil"))"
    }
}

// MARK: - CustomDebugStringConvertible
extension TextMessageStartEvent: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        TextMessageStartEvent {
            messageId: "\(messageId)"
            role: "\(role)"
            timestamp: \(timestamp.map(String.init) ?? "nil")
            eventType: \(eventType.rawValue)
        }
        """
    }
}
