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
@testable import AGUICore

final class MessageEncoderTests: XCTestCase {

    private let encoder = MessageEncoder()

    // MARK: - ReasoningMessage encoding

    func test_encodeReasoningMessage_producesCorrectJSON() throws {
        let message = ReasoningMessage(
            id: "reasoning-1",
            content: "Let me think step by step."
        )

        let data = try encoder.encode(message)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["id"] as? String, "reasoning-1")
        XCTAssertEqual(json["role"] as? String, "reasoning")
        XCTAssertEqual(json["content"] as? String, "Let me think step by step.")
    }

    func test_encodeReasoningMessage_withEncryptedValue() throws {
        let message = ReasoningMessage(
            id: "reasoning-2",
            content: "Analysing inputs...",
            encryptedValue: "enc-token-abc"
        )

        let data = try encoder.encode(message)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["encryptedValue"] as? String, "enc-token-abc")
    }

    func test_encodeReasoningMessage_nameAlwaysOmitted() throws {
        // ReasoningMessage.name is always nil per protocol spec — must not appear in JSON
        let message = ReasoningMessage(id: "reasoning-3", content: "Reasoning...")

        let data = try encoder.encode(message)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertNil(json["name"])
    }

    func test_encodeReasoningMessage_nilEncryptedValue_omittedFromJSON() throws {
        let message = ReasoningMessage(id: "reasoning-4", content: "Thinking...")

        let data = try encoder.encode(message)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertNil(json["encryptedValue"])
    }

    // MARK: - Unsupported role

    func test_unsupportedRole_throws() {
        // Build a registry with no handlers to guarantee an unsupported role error
        let emptyEncoder = MessageEncoder(registry: [:])
        let message = ReasoningMessage(id: "r-1", content: "test")

        XCTAssertThrowsError(try emptyEncoder.encode(message)) { error in
            guard case MessageEncodingError.unsupportedRole(let role) = error else {
                return XCTFail("Expected unsupportedRole, got \(error)")
            }
            XCTAssertEqual(role, .reasoning)
        }
    }
}
