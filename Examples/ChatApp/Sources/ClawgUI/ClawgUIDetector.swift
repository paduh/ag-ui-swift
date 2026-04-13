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

// MARK: - ClawgUIDetector

/// Identifies whether a URL string points to a ClawgUI enterprise gateway endpoint.
///
/// Mirrors the detection logic from the Kotlin SDK reference implementation.
/// A URL is considered a ClawgUI endpoint when its path contains `/v1/clawg-ui`.
enum ClawgUIDetector {

    /// Returns `true` when `urlString` contains the `/v1/clawg-ui` path segment.
    ///
    /// The check is case-sensitive — URL paths are case-sensitive by convention.
    static func isClawgUIEndpoint(_ urlString: String) -> Bool {
        urlString.range(
            of: #"/v1/clawg-ui"#,
            options: .regularExpression
        ) != nil
    }
}
