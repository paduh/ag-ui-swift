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

/// Defines the minimal surface an agent must expose to be driven by
/// ``AgentViewModel`` or ``AgentViewModelCompat``.
///
/// Conforming to `ChatAgent` decouples the view-model tier from any specific
/// agent implementation and makes both the view models and any custom agent
/// implementations fully testable through mocks.
///
/// ## Built-in conformances
///
/// ``StatefulAgUiAgent`` conforms to `ChatAgent` out of the box via a retroactive
/// extension in this file.
///
/// ## Custom agents
///
/// ```swift
/// struct MockChatAgent: ChatAgent {
///     func chat(message: String, threadId: String) async throws
///         -> AsyncThrowingStream<any AGUIEvent, Error>
///     {
///         // Return test events
///     }
///
///     func clearHistory(threadId: String?) async {}
/// }
/// ```
///
/// - SeeAlso: ``AgentViewModel``, ``AgentViewModelCompat``, ``StatefulAgUiAgent``
public protocol ChatAgent: Sendable {

    /// Sends a user message and returns the resulting AG-UI event stream.
    ///
    /// - Parameters:
    ///   - message: The user's text.
    ///   - threadId: The conversation thread identifier.
    /// - Returns: An `AsyncThrowingStream` of AG-UI events for this run.
    /// - Throws: A transport-level error if the request fails before streaming begins.
    func chat(
        message: String,
        threadId: String
    ) async throws -> AsyncThrowingStream<any AGUIEvent, Error>

    /// Clears the conversation history for the given thread, or all threads when `nil`.
    ///
    /// - Parameter threadId: The thread to clear, or `nil` for all threads.
    func clearHistory(threadId: String?) async
}

// MARK: - StatefulAgUiAgent conformance

extension StatefulAgUiAgent: ChatAgent {}
