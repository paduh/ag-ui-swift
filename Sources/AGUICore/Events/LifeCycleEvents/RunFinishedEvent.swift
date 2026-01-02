import Foundation

/// Event indicating that an agent run has completed successfully.
///
/// This event is emitted when an agent has finished processing a run request
/// and has generated all output. It signals the end of the execution lifecycle.
///
/// - SeeAlso: `RunStartedEvent`, `RunErroredEvent`
public struct RunFinishedEvent: AGUIEvent, Equatable, Hashable, Sendable {

    // MARK: - Properties

    /// The identifier for the conversation thread.
    public let threadId: String

    /// The unique identifier for the completed run.
    public let runId: String

    /// Optional timestamp when the run finished.
    public let timestamp: Int64?

    /// Optional raw event data as received from the agent.
    public let rawEvent: Data?

    /// The type of this event (always `.runFinished`).
    public var eventType: EventType { .runFinished }

    // MARK: - Initialization

    /// Creates a new `RunFinishedEvent`.
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

extension RunFinishedEvent: CustomStringConvertible {

    public var description: String {
        "RunFinishedEvent(threadId: \(threadId), runId: \(runId), timestamp: \(timestamp?.description ?? "nil"))"
    }
}
