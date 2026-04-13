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

import XCTest
@testable import ChatApp

final class ClawgUIDetectorTests: XCTestCase {

    // MARK: - Positive matches

    func test_matchesStandardClawgUIPath() {
        XCTAssertTrue(ClawgUIDetector.isClawgUIEndpoint("https://gateway.enterprise.com/v1/clawg-ui"))
    }

    func test_matchesClawgUIWithSubpath() {
        XCTAssertTrue(ClawgUIDetector.isClawgUIEndpoint("https://gateway.enterprise.com/v1/clawg-ui/chat"))
    }

    func test_matchesClawgUIOnLocalhost() {
        XCTAssertTrue(ClawgUIDetector.isClawgUIEndpoint("http://localhost:8080/v1/clawg-ui"))
    }

    func test_matchesClawgUIWithPort() {
        XCTAssertTrue(ClawgUIDetector.isClawgUIEndpoint("https://api.example.com:9443/v1/clawg-ui/agentic_chat"))
    }

    // MARK: - Negative matches

    func test_rejectsStandardAPIURL() {
        XCTAssertFalse(ClawgUIDetector.isClawgUIEndpoint("https://api.openai.com/v1/chat/completions"))
    }

    func test_rejectsRegularAgentURL() {
        XCTAssertFalse(ClawgUIDetector.isClawgUIEndpoint("https://my-agent.example.com/run"))
    }

    func test_rejectsEmptyString() {
        XCTAssertFalse(ClawgUIDetector.isClawgUIEndpoint(""))
    }

    func test_rejectsNearMissWithoutClawgUI() {
        XCTAssertFalse(ClawgUIDetector.isClawgUIEndpoint("https://example.com/v1/clawg"))
    }

    func test_rejectsURLWithClawgUIInHost_notPath() {
        // Only path segment /v1/clawg-ui matches — not host name
        XCTAssertFalse(ClawgUIDetector.isClawgUIEndpoint("https://clawg-ui.enterprise.com/v1/chat"))
    }

    func test_isCaseSensitive() {
        // URL paths are case-sensitive; uppercase should not match
        XCTAssertFalse(ClawgUIDetector.isClawgUIEndpoint("https://example.com/V1/CLAWG-UI"))
    }
}
