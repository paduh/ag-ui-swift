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

/// Event marking the end of a reasoning phase.
///
/// This event signals that the agent has completed its internal reasoning process
/// for the message identified by `messageId`. It is the replacement for the
/// deprecated ``ThinkingEndEvent``.
///
/// - SeeAlso: ``ReasoningStartEvent``, ``ReasoningMessageEndEvent``
public struct ReasoningEndEvent: AGUIEvent, Equatable, Hashable, Sendable {

    // MARK: - Properties

    /// The identifier of the message whose reasoning phase has ended.
    public let messageId: String

    /// Optional timestamp when the reasoning ended.
    ///
    /// Represented as milliseconds since Unix epoch.
    public let timestamp: Int64?

    /// Optional raw event data as received from the agent.
    public let rawEvent: Data?

    /// The type of this event (always `.reasoningEnd`).
    public var eventType: EventType { .reasoningEnd }

    // MARK: - Initialization

    /// Creates a new `ReasoningEndEvent`.
    ///
    /// - Parameters:
    ///   - messageId: The identifier of the message whose reasoning phase ended
    ///   - timestamp: Optional timestamp in milliseconds since epoch
    ///   - rawEvent: Optional raw event data as received from the agent
    public init(
        messageId: String,
        timestamp: Int64? = nil,
        rawEvent: Data? = nil
    ) {
        self.messageId = messageId
        self.timestamp = timestamp
        self.rawEvent = rawEvent
    }
}

// MARK: - CustomStringConvertible
extension ReasoningEndEvent: CustomStringConvertible {
    public var description: String {
        "ReasoningEndEvent(messageId: \"\(messageId)\", timestamp: \(timestamp?.description ?? "nil"))"
    }
}

// MARK: - CustomDebugStringConvertible
extension ReasoningEndEvent: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        ReasoningEndEvent {
            messageId: "\(messageId)"
            timestamp: \(timestamp.map(String.init) ?? "nil")
            eventType: \(eventType.rawValue)
        }
        """
    }
}
