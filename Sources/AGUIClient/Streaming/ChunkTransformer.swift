/*
 * MIT License
 *
 * Copyright (c) 2025 Perfect Aduh
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import AGUICore
import Foundation

// MARK: - ChunkTransformError

/// Errors that can occur during chunk transformation.
public enum ChunkTransformError: Error, Sendable {
    /// A text chunk is missing the required messageId.
    case missingMessageId

    /// A tool call chunk is missing required information (toolCallId or toolCallName).
    case missingToolCallInfo
}

// MARK: - ChunkTransformer

/// Transforms chunk events into structured start/content/end sequences.
///
/// `ChunkTransformer` converts `TEXT_MESSAGE_CHUNK` and `TOOL_CALL_CHUNK` events
/// into complete protocol sequences with explicit start, content, and end events.
/// This ensures downstream processing can rely on standard event sequences regardless
/// of the upstream stream shape.
///
/// ## Behavior
///
/// - **Text Chunks**: Transformed into TextMessageStart → TextMessageContent(s) → TextMessageEnd
/// - **Tool Chunks**: Transformed into ToolCallStart → ToolCallArgs(s) → ToolCallEnd
/// - **Existing Events**: Pass through unchanged
/// - **Mode Switching**: Automatically closes pending sequences when switching between text/tool modes
///
/// ## Usage
///
/// ```swift
/// let transformed = events.transformChunks()
/// for try await event in transformed {
///     // Process structured events
/// }
/// ```
///
/// - SeeAlso: ``ChunkTransformError``
public struct ChunkTransformer {
    /// Creates a new chunk transformer.
    public init() {}

    /// Transforms a stream of events, converting chunks to structured sequences.
    ///
    /// - Parameter events: The source event stream
    /// - Returns: Transformed event stream with structured sequences
    /// - Throws: ``ChunkTransformError`` if chunks are malformed
    public func transform<S: AsyncSequence>(
        _ events: S
    ) -> AsyncThrowingStream<any AGUIEvent, Error> where S.Element == any AGUIEvent {
        AsyncThrowingStream { continuation in
            Task {
                var mode: ChunkMode?
                var textState: TextState?
                var toolState: ToolState?

                func closeText(_ event: any AGUIEvent) {
                    if let state = textState, state.fromChunk {
                        continuation.yield(TextMessageEndEvent(
                            messageId: state.messageId,
                            timestamp: event.timestamp,
                            rawEvent: event.rawEvent
                        ))
                    }
                    textState = nil
                    if mode == .text {
                        mode = nil
                    }
                }

                func closeTool(_ event: any AGUIEvent) {
                    if let state = toolState, state.fromChunk {
                        continuation.yield(ToolCallEndEvent(
                            toolCallId: state.toolCallId,
                            timestamp: event.timestamp,
                            rawEvent: event.rawEvent
                        ))
                    }
                    toolState = nil
                    if mode == .tool {
                        mode = nil
                    }
                }

                func closePending(_ event: any AGUIEvent) {
                    closeText(event)
                    closeTool(event)
                }

                do {
                    for try await event in events {
                        switch event {
                        case let chunk as TextMessageChunkEvent:
                            let messageId = chunk.messageId

                            // Check if we need to start a new message
                            if mode != .text || (messageId != nil && messageId != textState?.messageId) {
                                closePending(event)

                                guard let id = messageId else {
                                    throw ChunkTransformError.missingMessageId
                                }

                                continuation.yield(TextMessageStartEvent(
                                    messageId: id,
                                    role: chunk.role ?? "assistant",
                                    timestamp: chunk.timestamp,
                                    rawEvent: chunk.rawEvent
                                ))

                                mode = .text
                                textState = TextState(messageId: id, fromChunk: true)
                            }

                            // Emit content if delta is present and non-empty
                            if let delta = chunk.delta, !delta.isEmpty {
                                continuation.yield(TextMessageContentEvent(
                                    messageId: textState!.messageId,
                                    delta: delta,
                                    timestamp: chunk.timestamp,
                                    rawEvent: chunk.rawEvent
                                ))
                            }

                        case let chunk as ToolCallChunkEvent:
                            let toolId = chunk.toolCallId
                            let toolName = chunk.toolCallName

                            // Check if we need to start a new tool call
                            if mode != .tool || (toolId != nil && toolId != toolState?.toolCallId) {
                                closePending(event)

                                guard let id = toolId, let name = toolName else {
                                    throw ChunkTransformError.missingToolCallInfo
                                }

                                continuation.yield(ToolCallStartEvent(
                                    toolCallId: id,
                                    toolCallName: name,
                                    parentMessageId: chunk.parentMessageId,
                                    timestamp: chunk.timestamp,
                                    rawEvent: chunk.rawEvent
                                ))

                                mode = .tool
                                toolState = ToolState(toolCallId: id, fromChunk: true)
                            }

                            // Emit args if delta is present and non-empty
                            if let delta = chunk.delta, !delta.isEmpty {
                                continuation.yield(ToolCallArgsEvent(
                                    toolCallId: toolState!.toolCallId,
                                    delta: delta,
                                    timestamp: chunk.timestamp,
                                    rawEvent: chunk.rawEvent
                                ))
                            }

                        case is TextMessageStartEvent:
                            closePending(event)
                            mode = .text
                            if let start = event as? TextMessageStartEvent {
                                textState = TextState(messageId: start.messageId, fromChunk: false)
                            }
                            continuation.yield(event)

                        case is TextMessageContentEvent:
                            mode = .text
                            if let content = event as? TextMessageContentEvent {
                                textState = TextState(messageId: content.messageId, fromChunk: false)
                            }
                            continuation.yield(event)

                        case is TextMessageEndEvent:
                            textState = nil
                            if mode == .text {
                                mode = nil
                            }
                            continuation.yield(event)

                        case is ToolCallStartEvent:
                            closePending(event)
                            mode = .tool
                            if let start = event as? ToolCallStartEvent {
                                toolState = ToolState(toolCallId: start.toolCallId, fromChunk: false)
                            }
                            continuation.yield(event)

                        case is ToolCallArgsEvent:
                            mode = .tool
                            if let args = event as? ToolCallArgsEvent {
                                if toolState?.toolCallId == args.toolCallId {
                                    toolState?.fromChunk = false
                                } else {
                                    toolState = ToolState(toolCallId: args.toolCallId, fromChunk: false)
                                }
                            }
                            continuation.yield(event)

                        case is ToolCallEndEvent:
                            toolState = nil
                            if mode == .tool {
                                mode = nil
                            }
                            continuation.yield(event)

                        default:
                            // Close pending state for other events
                            closePending(event)
                            continuation.yield(event)
                        }
                    }

                    // Close any pending state at end of stream
                    if textState != nil || toolState != nil {
                        let finalEvent = RunFinishedEvent(
                            threadId: "",
                            runId: "",
                            timestamp: nil,
                            rawEvent: nil
                        )
                        closePending(finalEvent)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// MARK: - Internal State Types

private enum ChunkMode {
    case text
    case tool
}

private struct TextState {
    let messageId: String
    var fromChunk: Bool
}

private struct ToolState {
    let toolCallId: String
    var fromChunk: Bool
}

// MARK: - AsyncSequence Extension

extension AsyncSequence where Element == any AGUIEvent {
    /// Apply chunk transformation to the event stream.
    ///
    /// This method transforms `TEXT_MESSAGE_CHUNK` and `TOOL_CALL_CHUNK` events
    /// into structured start/content/end sequences.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let eventStream = httpAgent.run(input)
    /// let transformed = eventStream.transformChunks()
    ///
    /// for try await event in transformed {
    ///     switch event {
    ///     case let start as TextMessageStartEvent:
    ///         print("Message started: \(start.messageId)")
    ///     case let content as TextMessageContentEvent:
    ///         print("Content: \(content.delta)")
    ///     case let end as TextMessageEndEvent:
    ///         print("Message ended: \(end.messageId)")
    ///     default:
    ///         break
    ///     }
    /// }
    /// ```
    ///
    /// - Returns: Transformed event stream with structured sequences
    /// - Throws: ``ChunkTransformError`` if chunks are malformed
    public func transformChunks() -> AsyncThrowingStream<any AGUIEvent, Error> {
        ChunkTransformer().transform(self)
    }
}
