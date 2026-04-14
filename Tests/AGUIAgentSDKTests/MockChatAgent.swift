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
@testable import AGUIAgentSDK

/// Test double for `ChatAgent`.
///
/// Configured and read exclusively from `@MainActor` context (both test classes
/// are `@MainActor`), so `@MainActor` isolation satisfies the `Sendable` requirement
/// without locks or `@unchecked`.
@MainActor
final class MockChatAgent: ChatAgent, Sendable {

    // MARK: - Configuration (set before each test)

    /// Events that `chat()` will yield through the returned stream.
    var eventsToYield: [any AGUIEvent] = []

    /// When set, `chat()` itself throws this error before returning a stream.
    var chatThrows: Error? = nil

    /// When set, the returned stream finishes by throwing this error.
    var streamThrows: Error? = nil

    // MARK: - Captured invocations (assert after the test)

    private(set) var chatCalls: [(message: String, threadId: String)] = []
    private(set) var clearCalls: [String?] = []

    // MARK: - ChatAgent conformance

    func chat(
        message: String,
        threadId: String
    ) async throws -> AsyncThrowingStream<any AGUIEvent, Error> {
        chatCalls.append((message: message, threadId: threadId))

        if let err = chatThrows { throw err }

        let events = eventsToYield
        let streamError = streamThrows

        return AsyncThrowingStream { continuation in
            for event in events {
                continuation.yield(event)
            }
            continuation.finish(throwing: streamError)
        }
    }

    func clearHistory(threadId: String?) async {
        clearCalls.append(threadId)
    }
}
