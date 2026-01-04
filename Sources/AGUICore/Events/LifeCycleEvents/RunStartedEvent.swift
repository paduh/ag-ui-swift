// RunStartedEvent.swift
// AGUISwift

import Foundation

/// Event indicating that a new agent run has started.
///
/// This event is emitted when an agent begins processing a new run request.
/// It provides the thread and run identifiers that will be used throughout
/// the execution lifecycle.
/// - SeeAlso: `RunFinishedEvent`, `RunErrorEvent`
public struct RunStartedEvent: AGUIEvent, Equatable, Hashable, Sendable {

    // MARK: - Properties

    /// The identifier for the conversation thread.
    ///
    /// Matches the AG-UI protocol field exactly.
    public let threadId: String

    /// The unique identifier for this specific run.
    ///
    /// Matches the AG-UI protocol field exactly.
    public let runId: String

    /// Optional timestamp when the run started.
    ///
    /// Represented as milliseconds since Unix epoch.
    public let timestamp: Int64?

    /// Optional raw event data as received from the agent.
    public let rawEvent: Data?

    /// The type of this event (always `.runStarted`).
    public var eventType: EventType { .runStarted }

    // MARK: - Initialization

    /// Creates a new `RunStartedEvent`.
    ///
    /// - Parameters:
    ///   - threadId: The conversation thread identifier
    ///   - runId: The unique run identifier
    ///   - timestamp: Optional timestamp in milliseconds since epoch
    ///   - rawEvent: Optional raw event data as received from the agent
    public init(
        threadId: String,
        runId: String,
        timestamp: Int64? = nil,
        rawEvent: Data? = nil
    ) {
        self.threadId = threadId
        self.runId = runId
        self.timestamp = timestamp
        self.rawEvent = rawEvent
    }
}

// MARK: - CustomStringConvertible
extension RunStartedEvent: CustomStringConvertible {
    public var description: String {
        "RunStartedEvent(threadId: \(threadId), runId: \(runId), timestamp: \(timestamp?.description ?? "nil"))"
    }
}

// MARK: - CustomDebugStringConvertible
extension RunStartedEvent: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        RunStartedEvent {
            threadId: "\(threadId)"
            runId: "\(runId)"
            timestamp: \(timestamp.map(String.init) ?? "nil")
            eventType: \(eventType.rawValue)
        }
        """
    }
}
