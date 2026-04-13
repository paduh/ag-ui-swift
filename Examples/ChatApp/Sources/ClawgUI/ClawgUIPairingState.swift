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

// MARK: - ClawgUIPairingState

/// Six-state machine mirroring the Kotlin SDK's ClawgUI pairing flow.
///
/// ```
/// idle ──[clawg-ui URL detected]──► initiating
/// initiating ──[403 + pairing info]──► pendingApproval(approvalURL)
/// initiating ──[HTTP error]──► failed(reason)
/// pendingApproval ──[user confirms]──► awaitingApproval
/// awaitingApproval ──[poll 200 OK]──► idle (connected)
/// awaitingApproval ──[poll timeout]──► retryingConnection
/// retryingConnection ──[retry succeeds]──► pendingApproval(url)
/// retryingConnection ──[max retries exhausted]──► failed(reason)
/// failed ──[user dismisses]──► idle
/// ```
enum ClawgUIPairingState: Sendable, Equatable {
    /// No pairing in progress — default state for non-ClawgUI agents.
    case idle

    /// Initial handshake request is in flight.
    case initiating

    /// Handshake returned a 403 with an approval URL; user must open it to authorize.
    case pendingApproval(approvalURL: URL)

    /// User confirmed they authorized; polling the gateway for confirmation.
    case awaitingApproval

    /// Polling timed out; user can tap Retry to re-initiate.
    case retryingConnection

    /// Terminal error state; user must dismiss and reconfigure.
    case failed(reason: String)
}
