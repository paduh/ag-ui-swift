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

/// Event containing a streaming chunk of reasoning message content.
///
/// This event delivers an incremental piece of reasoning text during a reasoning
/// message's lifecycle. It is the replacement for the deprecated
/// ``ThinkingTextMessageContentEvent``.
///
/// - SeeAlso: ``ReasoningMessageStartEvent``, ``ReasoningMessageEndEvent``
public struct ReasoningMessageContentEvent: AGUIEvent, Equatable, Hashable, Sendable {

    // MARK: - Properties

    /// The unique identifier of the reasoning message this content belongs to.
    public let messageId: String

    /// The incremental reasoning text chunk.
    ///
    /// Must be non-empty.
    public let delta: String

    /// Optional timestamp when this content chunk was received.
    ///
    /// Represented as milliseconds since Unix epoch.
    public let timestamp: Int64?

    /// Optional raw event data as received from the agent.
    public let rawEvent: Data?

    /// The type of this event (always `.reasoningMessageContent`).
    public var eventType: EventType { .reasoningMessageContent }

    // MARK: - Initialization

    /// Creates a new `ReasoningMessageContentEvent`.
    ///
    /// - Parameters:
    ///   - messageId: The unique identifier of the reasoning message
    ///   - delta: The incremental reasoning text chunk (non-empty)
    ///   - timestamp: Optional timestamp in milliseconds since epoch
    ///   - rawEvent: Optional raw event data as received from the agent
    public init(
        messageId: String,
        delta: String,
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
extension ReasoningMessageContentEvent: CustomStringConvertible {
    public var description: String {
        "ReasoningMessageContentEvent(messageId: \"\(messageId)\", delta: \"\(delta)\", timestamp: \(timestamp?.description ?? "nil"))"
    }
}

// MARK: - CustomDebugStringConvertible
extension ReasoningMessageContentEvent: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        ReasoningMessageContentEvent {
            messageId: "\(messageId)"
            delta: "\(delta)"
            timestamp: \(timestamp.map(String.init) ?? "nil")
            eventType: \(eventType.rawValue)
        }
        """
    }
}
