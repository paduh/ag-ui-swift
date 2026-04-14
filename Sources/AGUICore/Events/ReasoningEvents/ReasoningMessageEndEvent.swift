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

/// Event indicating the end of a streaming reasoning message.
///
/// This event marks the completion of a reasoning message within a reasoning phase.
/// It is the replacement for the deprecated ``ThinkingTextMessageEndEvent``.
///
/// - SeeAlso: ``ReasoningMessageStartEvent``, ``ReasoningMessageContentEvent``
public struct ReasoningMessageEndEvent: AGUIEvent, Equatable, Hashable, Sendable {

    // MARK: - Properties

    /// The unique identifier of the reasoning message that has ended.
    public let messageId: String

    /// Optional timestamp when the reasoning message generation finished.
    ///
    /// Represented as milliseconds since Unix epoch.
    public let timestamp: Int64?

    /// Optional raw event data as received from the agent.
    public let rawEvent: Data?

    /// The type of this event (always `.reasoningMessageEnd`).
    public var eventType: EventType { .reasoningMessageEnd }

    // MARK: - Initialization

    /// Creates a new `ReasoningMessageEndEvent`.
    ///
    /// - Parameters:
    ///   - messageId: The unique identifier of the reasoning message that ended
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
extension ReasoningMessageEndEvent: CustomStringConvertible {
    public var description: String {
        "ReasoningMessageEndEvent(messageId: \"\(messageId)\", timestamp: \(timestamp?.description ?? "nil"))"
    }
}

// MARK: - CustomDebugStringConvertible
extension ReasoningMessageEndEvent: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        ReasoningMessageEndEvent {
            messageId: "\(messageId)"
            timestamp: \(timestamp.map(String.init) ?? "nil")
            eventType: \(eventType.rawValue)
        }
        """
    }
}
