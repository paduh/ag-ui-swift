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
@testable import AGUIAgentSDK

final class AgentMessageTests: XCTestCase {

    // MARK: - Initialization

    func testInit_setsAllProvidedFields() {
        let msg = AgentMessage(id: "id-123", role: .user, content: "Hello!")
        XCTAssertEqual(msg.id, "id-123")
        XCTAssertEqual(msg.role, .user)
        XCTAssertEqual(msg.content, "Hello!")
    }

    func testInit_defaultId_isNonEmpty() {
        let msg = AgentMessage(role: .assistant, content: "Hi")
        XCTAssertFalse(msg.id.isEmpty)
    }

    func testInit_twoMessagesWithDefaultId_haveUniqueIds() {
        let a = AgentMessage(role: .user, content: "A")
        let b = AgentMessage(role: .user, content: "B")
        XCTAssertNotEqual(a.id, b.id)
    }

    // MARK: - Role

    func testRole_allCasesExist() {
        let expected: [AgentMessage.Role] = [.user, .assistant, .system, .tool]
        XCTAssertEqual(AgentMessage.Role.allCases.count, expected.count)
        for role in expected {
            XCTAssertTrue(AgentMessage.Role.allCases.contains(role))
        }
    }

    func testRole_rawValues_matchProtocolNames() {
        XCTAssertEqual(AgentMessage.Role.user.rawValue, "user")
        XCTAssertEqual(AgentMessage.Role.assistant.rawValue, "assistant")
        XCTAssertEqual(AgentMessage.Role.system.rawValue, "system")
        XCTAssertEqual(AgentMessage.Role.tool.rawValue, "tool")
    }

    // MARK: - Equatable

    func testEquatable_identicalFields_areEqual() {
        let a = AgentMessage(id: "x", role: .user, content: "hello")
        let b = AgentMessage(id: "x", role: .user, content: "hello")
        XCTAssertEqual(a, b)
    }

    func testEquatable_differentId_notEqual() {
        let a = AgentMessage(id: "a", role: .user, content: "hello")
        let b = AgentMessage(id: "b", role: .user, content: "hello")
        XCTAssertNotEqual(a, b)
    }

    func testEquatable_differentRole_notEqual() {
        let a = AgentMessage(id: "x", role: .user, content: "hello")
        let b = AgentMessage(id: "x", role: .assistant, content: "hello")
        XCTAssertNotEqual(a, b)
    }

    func testEquatable_differentContent_notEqual() {
        let a = AgentMessage(id: "x", role: .user, content: "hello")
        let b = AgentMessage(id: "x", role: .user, content: "world")
        XCTAssertNotEqual(a, b)
    }

    // MARK: - Identifiable

    func testIdentifiable_idMatchesInitParameter() {
        let msg = AgentMessage(id: "unique-id", role: .assistant, content: "Hi")
        XCTAssertEqual(msg.id, "unique-id")
    }
}
