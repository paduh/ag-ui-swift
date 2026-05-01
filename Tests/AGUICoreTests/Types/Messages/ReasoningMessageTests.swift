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

final class ReasoningMessageTests: XCTestCase {

    private let messageId = "msg-reasoning-1"
    private let content = "Let me think step by step..."

    // MARK: - Role

    func test_roleIsAlwaysReasoning() {
        let message = ReasoningMessage(id: messageId, content: content)
        XCTAssertEqual(message.role, .reasoning)
    }

    // MARK: - Initialization

    func test_initWithContent_storesContent() {
        let message = ReasoningMessage(id: messageId, content: content)
        XCTAssertEqual(message.id, messageId)
        XCTAssertEqual(message.content, content)
        XCTAssertNil(message.encryptedValue)
    }

    func test_initWithEncryptedValue_storesEncryptedValue() {
        let token = "enc-abc-token"
        let message = ReasoningMessage(id: messageId, content: content, encryptedValue: token)
        XCTAssertEqual(message.encryptedValue, token)
    }

    func test_nameIsAlwaysNil() {
        let message = ReasoningMessage(id: messageId, content: content)
        XCTAssertNil(message.name)
    }

    // MARK: - Equatable / Hashable

    func test_equatable_sameFields_areEqual() {
        let m1 = ReasoningMessage(id: messageId, content: content)
        let m2 = ReasoningMessage(id: messageId, content: content)
        XCTAssertEqual(m1, m2)
    }

    func test_equatable_differentContent_notEqual() {
        let m1 = ReasoningMessage(id: messageId, content: "a")
        let m2 = ReasoningMessage(id: messageId, content: "b")
        XCTAssertNotEqual(m1, m2)
    }

    func test_equatable_differentId_notEqual() {
        let m1 = ReasoningMessage(id: "id-1", content: content)
        let m2 = ReasoningMessage(id: "id-2", content: content)
        XCTAssertNotEqual(m1, m2)
    }

    func test_equatable_differentEncryptedValue_notEqual() {
        let m1 = ReasoningMessage(id: messageId, content: content, encryptedValue: "token-a")
        let m2 = ReasoningMessage(id: messageId, content: content, encryptedValue: "token-b")
        XCTAssertNotEqual(m1, m2)
    }

    func test_hashable_equalMessagesHaveSameHash() {
        let m1 = ReasoningMessage(id: messageId, content: content)
        let m2 = ReasoningMessage(id: messageId, content: content)
        XCTAssertEqual(m1.hashValue, m2.hashValue)
    }

    func test_hashable_canBeUsedInSet() {
        let m1 = ReasoningMessage(id: messageId, content: content)
        let m2 = ReasoningMessage(id: messageId, content: content)
        let set: Set<ReasoningMessage> = [m1, m2]
        XCTAssertEqual(set.count, 1)
    }
}
