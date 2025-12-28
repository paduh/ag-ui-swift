import Foundation

/// Event types for the AG-UI protocol
/// 
/// Represents all possible event types that can be received from or sent to an AG-UI agent.
public enum EventType: String, Codable {
    // MARK: - Lifecycle Events
    
    case runStarted = "RUN_STARTED"
    case runFinished = "RUN_FINISHED"
    case runError = "RUN_ERROR"
    case stepStarted = "STEP_STARTED"
    case stepFinished = "STEP_FINISHED"
    
    // MARK: - Text Message Events
    
    case textMessageStart = "TEXT_MESSAGE_START"
    case textMessageContent = "TEXT_MESSAGE_CONTENT"
    case textMessageEnd = "TEXT_MESSAGE_END"
    
    // MARK: - Tool Call Events
    
    case toolCallStart = "TOOL_CALL_START"
    case toolCallArgs = "TOOL_CALL_ARGS"
    case toolCallEnd = "TOOL_CALL_END"
    
    // MARK: - State Management Events
    
    case stateSnapshot = "STATE_SNAPSHOT"
    case stateDelta = "STATE_DELTA"
    case messagesSnapshot = "MESSAGES_SNAPSHOT"
    
    // MARK: - Special Events
    
    case raw = "RAW"
    case custom = "CUSTOM"
    
    // Note: The protocol definitions (i.e., events.py and events.ts) in the current version of
    // the official AG-UI Python and TypeScript SDKs have several additional event types. Specifically:
    //
    // TEXT_MESSAGE_CHUNK
    // TOOL_CALL_CHUNK
    // THINKING_TEXT_MESSAGE_START
    // THINKING_TEXT_MESSAGE_CONTENT
    // THINKING_TEXT_MESSAGE_END
    // THINKING_START
    // THINKING_END
    //
    // These are left out for now as they do not appear in the actual protocol documentation,
    // but could be added if needed.
}

