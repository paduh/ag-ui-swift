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

final class ReasoningMessageStartEventTests: XCTestCase,
                                              AGUIEventDecoderTestHelpers,
                                              EventDecodingErrorTests {

    // MARK: - EventDecodingErrorTests

    var validEventFieldsWithoutType: [String: Any] {
        ["messageId": EventTestData.messageId, "role": "reasoning"]
    }

    var eventTypeString: String { "REASONING_MESSAGE_START" }
    var expectedEventType: EventType { .reasoningMessageStart }
    var unknownEventTypeString: String { "REASONING_MESSAGE_PAUSED" }

    // MARK: - Decode

    func test_decodeValidReasoningMessageStart_returnsCorrectEvent() throws {
        let data = jsonData("""
        {
          "type": "REASONING_MESSAGE_START",
          "messageId": "\(EventTestData.messageId)",
          "role": "reasoning"
        }
        """)
        let event = try XCTUnwrap(try makeStrictDecoder().decode(data) as? ReasoningMessageStartEvent)
        XCTAssertEqual(event.eventType, .reasoningMessageStart)
        XCTAssertEqual(event.messageId, EventTestData.messageId)
        XCTAssertEqual(event.role, "reasoning")
        XCTAssertNil(event.timestamp)
    }

    func test_decodeWithTimestamp_populatesTimestamp() throws {
        let data = jsonData("""
        {
          "type": "REASONING_MESSAGE_START",
          "messageId": "\(EventTestData.messageId)",
          "role": "reasoning",
          "timestamp": \(EventTestData.timestamp)
        }
        """)
        let event = try XCTUnwrap(try makeStrictDecoder().decode(data) as? ReasoningMessageStartEvent)
        XCTAssertEqual(event.timestamp, EventTestData.timestamp)
    }

    func test_decodePreservesRawEvent() throws {
        let data = jsonData("""
        {"type":"REASONING_MESSAGE_START","messageId":"\(EventTestData.messageId)","role":"reasoning"}
        """)
        let event = try XCTUnwrap(try makeStrictDecoder().decode(data) as? ReasoningMessageStartEvent)
        XCTAssertEqual(event.rawEvent, data)
    }

    func test_missingMessageId_throwsDecodingFailed() {
        let data = jsonData("""
        {"type":"REASONING_MESSAGE_START","role":"reasoning"}
        """)
        XCTAssertThrowsError(try makeStrictDecoder().decode(data)) { error in
            guard case .decodingFailed = error as? EventDecodingError else {
                return XCTFail("Expected decodingFailed, got \(error)")
            }
        }
    }

    func test_missingRole_throwsDecodingFailed() {
        let data = jsonData("""
        {"type":"REASONING_MESSAGE_START","messageId":"\(EventTestData.messageId)"}
        """)
        XCTAssertThrowsError(try makeStrictDecoder().decode(data)) { error in
            guard case .decodingFailed = error as? EventDecodingError else {
                return XCTFail("Expected decodingFailed, got \(error)")
            }
        }
    }

    // MARK: - Model

    func test_eventTypeIsAlwaysReasoningMessageStart() {
        let event = ReasoningMessageStartEvent(messageId: EventTestData.messageId, role: "reasoning")
        XCTAssertEqual(event.eventType, .reasoningMessageStart)
    }

    func test_defaultRole_isReasoning() {
        let event = ReasoningMessageStartEvent(messageId: EventTestData.messageId)
        XCTAssertEqual(event.role, "reasoning")
    }

    func test_equatable_sameFields_areEqual() {
        let e1 = ReasoningMessageStartEvent(messageId: EventTestData.messageId, role: "reasoning")
        let e2 = ReasoningMessageStartEvent(messageId: EventTestData.messageId, role: "reasoning")
        XCTAssertEqual(e1, e2)
    }
}
