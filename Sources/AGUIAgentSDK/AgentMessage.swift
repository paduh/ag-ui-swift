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

/// A concrete, display-ready representation of a conversation message.
///
/// `AgentMessage` is the currency type between the AG-UI event pipeline and SwiftUI
/// views. Unlike `any Message` (the protocol used inside the networking layer),
/// `AgentMessage` is a concrete value type that is `Identifiable` and `Equatable`,
/// making it safe to use directly in `List`, `ForEach`, and `@Observable` properties.
///
/// ## Usage in SwiftUI
///
/// ```swift
/// List(viewModel.messages) { message in
///     MessageBubble(message: message)
/// }
/// ```
///
/// ## Relationship to the protocol layer
///
/// `AgentMessage` is built by ``AgentViewModel`` / ``AgentViewModelCompat`` as events
/// arrive from the stream. It is not decoded from the wire — it is assembled in the
/// view model from `TextMessageStartEvent`, `TextMessageContentEvent`, and
/// `TextMessageEndEvent` events.
///
/// - SeeAlso: ``AgentViewModel``, ``AgentViewModelCompat``, ``AgentError``
public struct AgentMessage: Sendable, Identifiable, Equatable {

    // MARK: - Role

    /// The speaker role for this message.
    public enum Role: String, Sendable, Equatable, CaseIterable {
        /// A message from the end-user.
        case user
        /// A message from the AI assistant.
        case assistant
        /// A system-level instruction (usually not displayed to the user).
        case system
        /// The result of a tool call.
        case tool
    }

    // MARK: - Properties

    /// Stable identifier for use with SwiftUI `List` / `ForEach` diffing.
    ///
    /// When an assistant message is updated with content deltas, the `id` does not
    /// change — only `content` grows. This lets SwiftUI animate the existing row
    /// rather than replace it.
    public let id: String

    /// The speaker role.
    public let role: Role

    /// The text content of the message.
    ///
    /// For assistant messages being streamed, this grows incrementally as
    /// `TextMessageContentEvent` deltas arrive.
    public let content: String

    // MARK: - Initialization

    /// Creates an `AgentMessage`.
    ///
    /// - Parameters:
    ///   - id: Stable identifier (defaults to a new UUID string).
    ///   - role: The speaker role.
    ///   - content: The message text.
    public init(
        id: String = UUID().uuidString,
        role: Role,
        content: String
    ) {
        self.id = id
        self.role = role
        self.content = content
    }
}

// MARK: - AgentError

/// Errors surfaced by ``AgentViewModel`` / ``AgentViewModelCompat``.
///
/// `AgentError` wraps AG-UI protocol-level errors (from `RunErrorEvent`) so callers
/// can distinguish them from transport-level failures (e.g., `URLError`, `ClientError`).
///
/// ## Example
///
/// ```swift
/// if let error = viewModel.lastError as? AgentError,
///    case .runError(let message, _) = error {
///     Text("Agent error: \(message)").foregroundColor(.red)
/// }
/// ```
public enum AgentError: Error, LocalizedError, Sendable {

    /// The agent reported an error via `RunErrorEvent`.
    ///
    /// - Parameters:
    ///   - message: Human-readable description from the agent.
    ///   - code: Optional machine-readable error code.
    case runError(message: String, code: String?)

    public var errorDescription: String? {
        switch self {
        case .runError(let message, _):
            return message
        }
    }
}
