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

/// Describes why an agent run finished.
///
/// Carried by `RunFinishedEvent` and decoded from the `"outcome"` field in the
/// AG-UI wire format. Unknown values from future protocol versions fall back to
/// `.completed`.
public enum RunFinishedOutcome: String, Equatable, Hashable, Sendable, Codable {

    /// The run completed normally with a result (or no result).
    case completed = "COMPLETED"

    /// The run was cancelled before it produced a final result.
    case cancelled = "CANCELLED"

    /// The run stopped because it reached the configured iteration ceiling.
    case maxIterationsReached = "MAX_ITERATIONS_REACHED"
}
