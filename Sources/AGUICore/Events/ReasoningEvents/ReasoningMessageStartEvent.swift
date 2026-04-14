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

/// Event indicating the start of a streaming reasoning message.
///
/// This event marks the beginning of a reasoning message within a reasoning phase.
/// The `role` field will always be `"reasoning"`. It is the replacement for the
/// deprecated ``ThinkingTextMessageStartEvent``.
///
/// - SeeAlso: ``ReasoningMessageContentEvent``, ``ReasoningMessageEndEvent``
public struct ReasoningMessageStartEvent: AGUIEvent, Equatable, Hashable, Sendable {

    // MARK: - Properties

    /// The unique identifier of the reasoning message.
    public let messageId: String

    /// The role of this message. Always `"reasoning"`.
    public let role: String

    /// Optional timestamp when the reasoning message generation started.
    ///
    /// Represented as milliseconds since Unix epoch.
    public let timestamp: Int64?

    /// Optional raw event data as received from the agent.
    public let rawEvent: Data?

    /// The type of this event (always `.reasoningMessageStart`).
    public var eventType: EventType { .reasoningMessageStart }

    // MARK: - Initialization

    /// Creates a new `ReasoningMessageStartEvent`.
    ///
    /// - Parameters:
    ///   - messageId: The unique identifier of the reasoning message
    ///   - role: The message role (always `"reasoning"`)
    ///   - timestamp: Optional timestamp in milliseconds since epoch
    ///   - rawEvent: Optional raw event data as received from the agent
    public init(
        messageId: String,
        role: String = "reasoning",
        timestamp: Int64? = nil,
        rawEvent: Data? = nil
    ) {
        self.messageId = messageId
        self.role = role
        self.timestamp = timestamp
        self.rawEvent = rawEvent
    }
}

// MARK: - CustomStringConvertible
extension ReasoningMessageStartEvent: CustomStringConvertible {
    public var description: String {
        "ReasoningMessageStartEvent(messageId: \"\(messageId)\", role: \"\(role)\", timestamp: \(timestamp?.description ?? "nil"))"
    }
}

// MARK: - CustomDebugStringConvertible
extension ReasoningMessageStartEvent: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        ReasoningMessageStartEvent {
            messageId: "\(messageId)"
            role: "\(role)"
            timestamp: \(timestamp.map(String.init) ?? "nil")
            eventType: \(eventType.rawValue)
        }
        """
    }
}
