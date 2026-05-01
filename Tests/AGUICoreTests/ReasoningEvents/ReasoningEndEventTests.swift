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

final class ReasoningEndEventTests: XCTestCase,
                                     AGUIEventDecoderTestHelpers,
                                     EventDecodingErrorTests {

    // MARK: - EventDecodingErrorTests

    var validEventFieldsWithoutType: [String: Any] {
        ["messageId": EventTestData.messageId]
    }

    var eventTypeString: String { "REASONING_END" }
    var expectedEventType: EventType { .reasoningEnd }
    var unknownEventTypeString: String { "REASONING_CANCELLED" }

    // MARK: - Decode

    func test_decodeValidReasoningEnd_returnsCorrectEvent() throws {
        let data = jsonData("""
        {"type":"REASONING_END","messageId":"\(EventTestData.messageId)"}
        """)
        let event = try XCTUnwrap(try makeStrictDecoder().decode(data) as? ReasoningEndEvent)
        XCTAssertEqual(event.eventType, .reasoningEnd)
        XCTAssertEqual(event.messageId, EventTestData.messageId)
        XCTAssertNil(event.timestamp)
    }

    func test_decodeWithTimestamp_populatesTimestamp() throws {
        let data = jsonData("""
        {"type":"REASONING_END","messageId":"\(EventTestData.messageId)","timestamp":\(EventTestData.timestamp)}
        """)
        let event = try XCTUnwrap(try makeStrictDecoder().decode(data) as? ReasoningEndEvent)
        XCTAssertEqual(event.timestamp, EventTestData.timestamp)
    }

    func test_decodePreservesRawEvent() throws {
        let data = jsonData("""
        {"type":"REASONING_END","messageId":"\(EventTestData.messageId)"}
        """)
        let event = try XCTUnwrap(try makeStrictDecoder().decode(data) as? ReasoningEndEvent)
        XCTAssertEqual(event.rawEvent, data)
    }

    func test_missingMessageId_throwsDecodingFailed() {
        let data = jsonData("""
        {"type":"REASONING_END"}
        """)
        XCTAssertThrowsError(try makeStrictDecoder().decode(data)) { error in
            guard case .decodingFailed = error as? EventDecodingError else {
                return XCTFail("Expected decodingFailed, got \(error)")
            }
        }
    }

    // MARK: - Model

    func test_eventTypeIsAlwaysReasoningEnd() {
        let event = ReasoningEndEvent(messageId: EventTestData.messageId)
        XCTAssertEqual(event.eventType, .reasoningEnd)
    }

    func test_equatable_sameFields_areEqual() {
        let e1 = ReasoningEndEvent(messageId: EventTestData.messageId, timestamp: EventTestData.timestamp)
        let e2 = ReasoningEndEvent(messageId: EventTestData.messageId, timestamp: EventTestData.timestamp)
        XCTAssertEqual(e1, e2)
    }

    func test_equatable_differentMessageIds_notEqual() {
        let e1 = ReasoningEndEvent(messageId: EventTestData.messageId)
        let e2 = ReasoningEndEvent(messageId: EventTestData.messageId2)
        XCTAssertNotEqual(e1, e2)
    }
}
