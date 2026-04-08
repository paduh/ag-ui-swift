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

import AGUIClient
import AGUICore
import Foundation

/// Configuration for ``StatefulAgUiAgent``.
///
/// This struct provides all configuration options for creating a stateful agent,
/// including HTTP settings, conversation management, and agent behavior.
///
/// ## Example
///
/// ```swift
/// var config = StatefulAgUiAgentConfig(baseURL: agentURL)
/// config.systemPrompt = "You are a helpful AI assistant."
/// config.maxHistoryLength = 50
/// config.timeout = .seconds(60)
/// config.headers = ["Authorization": "Bearer token"]
///
/// let agent = StatefulAgUiAgent(configuration: config)
/// ```
public struct StatefulAgUiAgentConfig: Sendable {
    /// The base URL of the AG-UI agent server.
    public var baseURL: URL

    /// Initial state for the agent.
    ///
    /// This JSON-encoded state is sent with the first run and updated
    /// automatically based on state events from the agent.
    public var initialState: State

    /// Maximum number of messages to keep in conversation history.
    ///
    /// When the history exceeds this limit, older messages are trimmed
    /// while preserving the system message. Set to `0` for unlimited history.
    ///
    /// Default: `100`
    public var maxHistoryLength: Int

    /// System prompt automatically added to new conversations.
    ///
    /// When set, this message is added as the first message in a new thread's
    /// conversation history. It provides the agent with behavioral instructions.
    ///
    /// Default: `nil`
    public var systemPrompt: String?

    /// Request timeout in seconds.
    ///
    /// Maximum time to wait for the agent server to respond before timing out.
    ///
    /// Default: `120.0`
    public var timeout: TimeInterval

    /// Custom HTTP headers to include in requests.
    ///
    /// Common headers include:
    /// - Authorization: Bearer tokens or API keys
    /// - Custom tracking or correlation IDs
    ///
    /// Default: `[:]`
    public var headers: [String: String]

    /// Creates a new stateful agent configuration.
    ///
    /// - Parameter baseURL: The base URL of the AG-UI agent server
    public init(baseURL: URL) {
        self.baseURL = baseURL
        self.initialState = Data("{}".utf8)
        self.maxHistoryLength = 100
        self.systemPrompt = nil
        self.timeout = 120.0
        self.headers = [:]
    }
}
