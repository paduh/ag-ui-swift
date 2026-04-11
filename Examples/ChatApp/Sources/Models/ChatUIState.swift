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

/// Snapshot of the chat UI that `ChatAppStore` publishes to SwiftUI views.
struct ChatUIState: Sendable {
    var messages: [DisplayMessage]
    /// Shown in the ephemeral banner strip above the input — not in the message list.
    var ephemeralMessage: DisplayMessage?
    var isLoading: Bool
    /// `true` when an active agent is configured and ready to receive messages.
    var isConnected: Bool
    var error: String?
    /// Hex color string for the chat background (e.g. `"FF5733"` or `"FF5733CC"`).
    var backgroundHex: String?
    var activeAgent: AgentConfig?

    init(
        messages: [DisplayMessage] = [],
        ephemeralMessage: DisplayMessage? = nil,
        isLoading: Bool = false,
        isConnected: Bool = false,
        error: String? = nil,
        backgroundHex: String? = nil,
        activeAgent: AgentConfig? = nil
    ) {
        self.messages = messages
        self.ephemeralMessage = ephemeralMessage
        self.isLoading = isLoading
        self.isConnected = isConnected
        self.error = error
        self.backgroundHex = backgroundHex
        self.activeAgent = activeAgent
    }
}
