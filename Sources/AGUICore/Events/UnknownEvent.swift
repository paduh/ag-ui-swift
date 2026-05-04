// Copyright (c) 2025 Perfect Aduh. MIT License. See LICENSE for details.

import Foundation

/// Event representing an unknown or unsupported event type.
///
/// `UnknownEvent` is returned by `AGUIEventDecoder` when operating in tolerant mode
/// (`unknownEventStrategy = .returnUnknown`) and encounters an event that cannot be
/// decoded into a known event type.
///
public struct UnknownEvent: AGUIEvent, Sendable {

    // MARK: - Properties

    /// The raw string value of the "type" field from the JSON event.
    ///
    /// This contains the exact type string as received from the agent, which may be:
    /// - A future event type not yet in the `EventType` enum
    /// - A custom event type defined by the agent implementation
    /// - A known event type that has no registered decoder handler
    public let typeRaw: String

    /// The complete original JSON data for this event.
    ///
    /// This preserves the full event payload, allowing you to:
    /// - Inspect the event structure for debugging
    /// - Forward the event to other systems that might understand it
    /// - Log the event for later analysis
    ///
    /// The data is guaranteed to be valid JSON (otherwise decoding would have failed earlier).
    public let rawEvent: Data?

    /// The type of this event (always `.unknown`).
    ///
    /// Unknown events return the sentinel `.unknown` case, which is distinct from
    /// the genuine `.raw` wire-format event type. This allows consumers to
    /// differentiate between a real `RAW` event sent by an agent and an event
    /// whose type string was not recognised by the decoder.
    public var eventType: EventType { .unknown }

    /// Optional timestamp when the event occurred (always `nil`).
    ///
    /// Since unknown events cannot be fully decoded, timestamp information
    /// is not available. If you need the timestamp, you can parse the `rawEvent`
    /// JSON data directly.
    public var timestamp: Int64? { nil }

    // MARK: - Initialization

    /// Creates a new `UnknownEvent`.
    ///
    /// - Parameters:
    ///   - typeRaw: The raw string value of the "type" field from the JSON
    ///   - rawEvent: The complete original JSON data for this event
    public init(typeRaw: String, rawEvent: Data) {
        self.typeRaw = typeRaw
        self.rawEvent = rawEvent
    }
}
