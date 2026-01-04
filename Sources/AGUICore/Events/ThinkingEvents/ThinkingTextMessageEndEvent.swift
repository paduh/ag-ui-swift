// ThinkingTextMessageEndEvent.swift
// AGUISwift

import Foundation

/// Event indicating the completion of a thinking text message.
///
/// This event marks the end of a thinking message generation during the agent's
/// internal reasoning process. It signals that all content for this thinking message
/// has been delivered and no more `ThinkingTextMessageContentEvent` events will follow
/// for this message.
///
/// - SeeAlso: `ThinkingTextMessageStartEvent`, `ThinkingTextMessageContentEvent`
public struct ThinkingTextMessageEndEvent: AGUIEvent, Equatable, Hashable, Sendable {

    // MARK: - Properties

    /// Optional timestamp when the thinking message generation completed.
    ///
    /// Represented as milliseconds since Unix epoch.
    public let timestamp: Int64?

    /// Optional raw event data as received from the agent.
    public let rawEvent: Data?

    /// The type of this event (always `.thinkingTextMessageEnd`).
    public var eventType: EventType { .thinkingTextMessageEnd }

    // MARK: - Initialization

    /// Creates a new `ThinkingTextMessageEndEvent`.
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
extension ThinkingTextMessageEndEvent: CustomStringConvertible {
    public var description: String {
        "ThinkingTextMessageEndEvent(timestamp: \(timestamp?.description ?? "nil"))"
    }
}

// MARK: - CustomDebugStringConvertible
extension ThinkingTextMessageEndEvent: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        ThinkingTextMessageEndEvent {
            timestamp: \(timestamp.map(String.init) ?? "nil")
            eventType: \(eventType.rawValue)
        }
        """
    }
}
