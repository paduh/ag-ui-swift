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
import XCTest
@testable import ChatApp

@MainActor
final class ChatAppStoreTests: XCTestCase {

    // MARK: - Helpers

    private func makeStore() -> ChatAppStore {
        // Use an isolated UserDefaults suite so tests don't share persisted state.
        let suite = UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        return ChatAppStore(defaults: defaults)
    }

    private func testConfig() -> AgentConfig {
        AgentConfig(name: "TestAgent", url: "https://test.local")
    }

    // MARK: - Text message streaming

    func test_streamingMessageReconstruction() {
        let store = makeStore()
        store.setupForTesting(agent: testConfig())

        store.processEvent(TextMessageStartEvent(messageId: "msg1", role: "assistant"))
        store.processEvent(TextMessageContentEvent(messageId: "msg1", delta: "Hello"))
        store.processEvent(TextMessageContentEvent(messageId: "msg1", delta: ", world"))
        store.processEvent(TextMessageEndEvent(messageId: "msg1"))

        XCTAssertEqual(store.state.messages.count, 1)
        let msg = store.state.messages[0]
        XCTAssertEqual(msg.content, "Hello, world")
        XCTAssertFalse(msg.isStreaming)
        XCTAssertEqual(msg.role, .assistant)
    }

    func test_multipleStreamingMessages() {
        let store = makeStore()
        store.setupForTesting(agent: testConfig())

        store.processEvent(TextMessageStartEvent(messageId: "a", role: "assistant"))
        store.processEvent(TextMessageContentEvent(messageId: "a", delta: "First"))
        store.processEvent(TextMessageEndEvent(messageId: "a"))

        store.processEvent(TextMessageStartEvent(messageId: "b", role: "assistant"))
        store.processEvent(TextMessageContentEvent(messageId: "b", delta: "Second"))
        store.processEvent(TextMessageEndEvent(messageId: "b"))

        XCTAssertEqual(store.state.messages.count, 2)
        XCTAssertEqual(store.state.messages[0].content, "First")
        XCTAssertEqual(store.state.messages[1].content, "Second")
    }

    func test_streamingIndicator_clears_onEnd() {
        let store = makeStore()
        store.setupForTesting(agent: testConfig())

        store.processEvent(TextMessageStartEvent(messageId: "m1", role: "assistant"))
        XCTAssertTrue(store.state.messages.last?.isStreaming == true)

        store.processEvent(TextMessageEndEvent(messageId: "m1"))
        XCTAssertFalse(store.state.messages.last?.isStreaming == true)
    }

    // MARK: - Tool call ephemeral banner

    func test_toolCallStart_setsEphemeralMessage() {
        let store = makeStore()
        store.setupForTesting(agent: testConfig())

        store.processEvent(ToolCallStartEvent(toolCallId: "tc1", toolCallName: "web_search"))

        XCTAssertNotNil(store.state.ephemeralMessage)
        XCTAssertEqual(store.state.ephemeralMessage?.content, "Calling web_search…")
        if case .toolCall(let name) = store.state.ephemeralMessage?.role {
            XCTAssertEqual(name, "web_search")
        } else {
            XCTFail("Expected .toolCall role")
        }
    }

    func test_toolCallEnd_schedulesEphemeralDismissal() async throws {
        let store = makeStore()
        store.setupForTesting(agent: testConfig())

        store.processEvent(ToolCallStartEvent(toolCallId: "tc1", toolCallName: "search"))
        XCTAssertNotNil(store.state.ephemeralMessage)

        store.processEvent(ToolCallEndEvent(toolCallId: "tc1"))

        // The dismissal is scheduled after 1 second — wait slightly longer.
        try await Task.sleep(for: .seconds(1.2))
        XCTAssertNil(store.state.ephemeralMessage)
    }

    // MARK: - Step events

    func test_stepStarted_setsEphemeral() {
        let store = makeStore()
        store.setupForTesting(agent: testConfig())

        store.processEvent(StepStartedEvent(stepName: "Reasoning"))

        XCTAssertNotNil(store.state.ephemeralMessage)
        XCTAssertEqual(store.state.ephemeralMessage?.content, "Reasoning")
        if case .stepInfo(let name) = store.state.ephemeralMessage?.role {
            XCTAssertEqual(name, "Reasoning")
        } else {
            XCTFail("Expected .stepInfo role")
        }
    }

    func test_stepFinished_clearsEphemeral() {
        let store = makeStore()
        store.setupForTesting(agent: testConfig())

        store.processEvent(StepStartedEvent(stepName: "Reasoning"))
        store.processEvent(StepFinishedEvent(stepName: "Reasoning"))

        XCTAssertNil(store.state.ephemeralMessage)
    }

    // MARK: - Run error

    func test_runError_setsErrorState() {
        let store = makeStore()
        store.setupForTesting(agent: testConfig())

        store.processEvent(RunErrorEvent(
            threadId: "t1",
            runId: "r1",
            error: .init(code: "TIMEOUT", message: "Request timed out")
        ))

        XCTAssertEqual(store.state.error, "Request timed out")
    }

    func test_dismissError_clearsError() {
        let store = makeStore()
        store.setupForTesting(agent: testConfig())
        store.processEvent(RunErrorEvent(
            threadId: "t1",
            runId: "r1",
            error: .init(code: "ERR", message: "boom")
        ))

        store.dismissError()

        XCTAssertNil(store.state.error)
    }

    // MARK: - Background hex (custom event)

    func test_changeBackgroundCustomEvent_setsHex() throws {
        let store = makeStore()
        store.setupForTesting(agent: testConfig())

        let payload = try JSONSerialization.data(withJSONObject: ["hex": "FF5733"])
        store.processEvent(CustomEvent(customType: "change_background", data: payload))

        XCTAssertEqual(store.state.backgroundHex, "FF5733")
    }

    // MARK: - Agent lifecycle

    func test_presentCreateAgent_setsDraft() {
        let store = makeStore()
        store.presentCreateAgent()

        XCTAssertEqual(store.formMode, .create)
        XCTAssertTrue(store.draft.name.isEmpty)
    }

    func test_saveAgent_appendsToList() {
        let store = makeStore()
        store.presentCreateAgent()
        store.draft.name = "My Agent"
        store.draft.url = "https://agent.example.com"

        store.saveAgent()

        XCTAssertEqual(store.agents.count, 1)
        XCTAssertEqual(store.agents[0].name, "My Agent")
        XCTAssertNil(store.formMode)
    }

    func test_deleteAgent_removesFromList() {
        let store = makeStore()
        store.presentCreateAgent()
        store.draft.name = "Agent A"
        store.draft.url = "https://a.example.com"
        store.saveAgent()

        let id = store.agents[0].id
        store.deleteAgent(id: id)

        XCTAssertTrue(store.agents.isEmpty)
    }
}
