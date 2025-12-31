import Foundation

/// Enumeration of all event types in the AG-UI protocol that can be received from or sent to an AG-UI agent.
///
/// Each case corresponds to a specific event type in the protocol specification.
/// The raw value is the exact string used in the JSON "type" field.
///
/// ## Event Categories
/// - **Lifecycle**: `runStarted`, `runFinished`, `runError`, `stepStarted`, `stepFinished`
/// - **Text Messages**: `textMessageStarted`, `textMessageChunk`, `textMessageFinished`
/// - **Tool Calls**: `toolCallStarted`, `toolCallArgumentChunk`, `toolCallFinished`, `toolCallResult`, `toolCallErrored`
/// - **State**: `stateSnapshot`, `stateUpdate`
/// - **Special**: `rawEvent`, `customEvent`

@frozen
public enum EventType: String, Codable, CaseIterable, Sendable {
    // MARK: - Lifecycle Events (5)
    
    /// Agent run has started
    case runStarted = "RUN_STARTED"
    
    /// Agent run has completed successfully
    case runFinished = "RUN_FINISHED"
    
    /// Agent run encountered an error
    case runError = "RUN_ERROR"
    
    /// Agent step has started
    case stepStarted = "STEP_STARTED"
    
    /// Agent step has finished
    case stepFinished = "STEP_FINISHED"
    
    // MARK: - Text Message Events (3)
    
    /// Text message generation started
    case textMessageStarted = "TEXT_MESSAGE_STARTED"
    
    /// Chunk of text message received
    case textMessageChunk = "TEXT_MESSAGE_CHUNK"
    
    /// Text message generation finished
    case textMessageFinished = "TEXT_MESSAGE_FINISHED"
    
    // MARK: - Tool Call Events (5)
    
    /// Tool call started
    case toolCallStarted = "TOOL_CALL_STARTED"
    
    /// Tool call argument chunk received
    case toolCallArgumentChunk = "TOOL_CALL_ARGUMENT_CHUNK"
    
    /// Tool call finished
    case toolCallFinished = "TOOL_CALL_FINISHED"
    
    /// Tool call result received
    case toolCallResult = "TOOL_CALL_RESULT"
    
    /// Tool call encountered an error
    case toolCallErrored = "TOOL_CALL_ERRORED"
    
    // MARK: - State Management Events (2)
    
    /// State snapshot received
    case stateSnapshot = "STATE_SNAPSHOT"
    
    /// Incremental state update received
    case stateUpdate = "STATE_UPDATE"
    
    // MARK: - Special Events (2)
    
    /// Raw untyped event
    case rawEvent = "RAW_EVENT"
    
    /// Custom event type
    case customEvent = "CUSTOM_EVENT"
}