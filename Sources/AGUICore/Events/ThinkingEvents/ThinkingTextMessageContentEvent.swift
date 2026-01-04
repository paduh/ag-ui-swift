// ThinkingTextMessageContentEvent.swift
// AGUISwift

import Foundation

/// Event containing incremental content for a thinking text message.
///
/// This event is emitted multiple times during thinking message generation, each time
/// containing a delta (incremental change) of text content. The delta must be a
/// non-empty string. These events represent the agent's internal thought process
/// and reasoning steps.
///
/// - SeeAlso: `ThinkingTextMessageStartEvent`, `ThinkingTextMessageEndEvent`
public struct ThinkingTextMessageContentEvent: AGUIEvent, Equatable, Hashable, Sendable {

    // MARK: - Properties

    /// The text content delta (incremental change).
    ///
    /// This is a non-empty string containing a chunk of the thinking message content.
    /// Multiple `ThinkingTextMessageContentEvent` instances represent the complete
    /// thinking message when concatenated.
    public let delta: String

    /// Optional timestamp when this content chunk was received.
    ///
    /// Represented as milliseconds since Unix epoch.
    public let timestamp: Int64?

    /// Optional raw event data as received from the agent.
    public let rawEvent: Data?

    /// The type of this event (always `.thinkingTextMessageContent`).
    public var eventType: EventType { .thinkingTextMessageContent }

    // MARK: - Initialization

    /// Creates a new `ThinkingTextMessageContentEvent`.
    ///
    /// - Parameters:
    ///   - delta: The text content delta (must be non-empty)
    ///   - timestamp: Optional timestamp in milliseconds since epoch
    ///   - rawEvent: Optional raw event data as received from the agent
    public init(
        delta: String,
        timestamp: Int64? = nil,
        rawEvent: Data? = nil
    ) {
        self.delta = delta
        self.timestamp = timestamp
        self.rawEvent = rawEvent
    }
}

// MARK: - CustomStringConvertible
extension ThinkingTextMessageContentEvent: CustomStringConvertible {
    public var description: String {
        "ThinkingTextMessageContentEvent(delta: \"\(delta)\", " +
        "timestamp: \(timestamp?.description ?? "nil"))"
    }
}

// MARK: - CustomDebugStringConvertible
extension ThinkingTextMessageContentEvent: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        ThinkingTextMessageContentEvent {
            delta: "\(delta)"
            timestamp: \(timestamp.map(String.init) ?? "nil")
            eventType: \(eventType.rawValue)
        }
        """
    }
}
