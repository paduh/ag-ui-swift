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

import Foundation

/// A convenience event that streams a chunk of reasoning message data.
///
/// `ReasoningMessageChunkEvent` is a combined event that can carry both a `messageId`
/// and a `delta`, enabling servers to stream reasoning content without emitting separate
/// start/content/end events. Both fields are optional; at least one should be non-nil
/// for the event to be meaningful.
///
/// - SeeAlso: ``ReasoningMessageStartEvent``, ``ReasoningMessageContentEvent``, ``ReasoningMessageEndEvent``
public struct ReasoningMessageChunkEvent: AGUIEvent, Equatable, Hashable, Sendable {

    // MARK: - Properties

    /// The optional identifier of the reasoning message this chunk belongs to.
    public let messageId: String?

    /// The optional incremental reasoning text chunk.
    public let delta: String?

    /// Optional timestamp when this chunk was received.
    ///
    /// Represented as milliseconds since Unix epoch.
    public let timestamp: Int64?

    /// Optional raw event data as received from the agent.
    public let rawEvent: Data?

    /// The type of this event (always `.reasoningMessageChunk`).
    public var eventType: EventType { .reasoningMessageChunk }

    // MARK: - Initialization

    /// Creates a new `ReasoningMessageChunkEvent`.
    ///
    /// - Parameters:
    ///   - messageId: Optional identifier of the reasoning message
    ///   - delta: Optional incremental reasoning text chunk
    ///   - timestamp: Optional timestamp in milliseconds since epoch
    ///   - rawEvent: Optional raw event data as received from the agent
    public init(
        messageId: String? = nil,
        delta: String? = nil,
        timestamp: Int64? = nil,
        rawEvent: Data? = nil
    ) {
        self.messageId = messageId
        self.delta = delta
        self.timestamp = timestamp
        self.rawEvent = rawEvent
    }
}

// MARK: - CustomStringConvertible
extension ReasoningMessageChunkEvent: CustomStringConvertible {
    public var description: String {
        let msgId = messageId.map { "\"\($0)\"" } ?? "nil"
        let d = delta.map { "\"\($0)\"" } ?? "nil"
        return "ReasoningMessageChunkEvent(messageId: \(msgId), delta: \(d), timestamp: \(timestamp?.description ?? "nil"))"
    }
}

// MARK: - CustomDebugStringConvertible
extension ReasoningMessageChunkEvent: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        ReasoningMessageChunkEvent {
            messageId: \(messageId.map { "\"\($0)\"" } ?? "nil")
            delta: \(delta.map { "\"\($0)\"" } ?? "nil")
            timestamp: \(timestamp.map(String.init) ?? "nil")
            eventType: \(eventType.rawValue)
        }
        """
    }
}
