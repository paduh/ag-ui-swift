// ThinkingEndEvent.swift
// AGUISwift

import Foundation

/// Event indicating the end of a thinking step.
///
/// This event marks the completion of the agent's internal reasoning or thinking
/// process. It signals that the agent has finished generating internal thoughts
/// for the current thinking step.
///
/// - SeeAlso: `ThinkingStartEvent`, `ThinkingTextMessageEndEvent`
public struct ThinkingEndEvent: AGUIEvent, Equatable, Hashable, Sendable {

    // MARK: - Properties

    /// Optional timestamp when the thinking ended.
    ///
    /// Represented as milliseconds since Unix epoch.
    public let timestamp: Int64?

    /// Optional raw event data as received from the agent.
    public let rawEvent: Data?

    /// The type of this event (always `.thinkingEnd`).
    public var eventType: EventType { .thinkingEnd }

    // MARK: - Initialization

    /// Creates a new `ThinkingEndEvent`.
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
extension ThinkingEndEvent: CustomStringConvertible {
    public var description: String {
        "ThinkingEndEvent(timestamp: \(timestamp?.description ?? "nil"))"
    }
}

// MARK: - CustomDebugStringConvertible
extension ThinkingEndEvent: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        ThinkingEndEvent {
            timestamp: \(timestamp.map(String.init) ?? "nil")
            eventType: \(eventType.rawValue)
        }
        """
    }
}
