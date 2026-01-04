// CustomEventTests.swift
// AGUISwiftTests

import XCTest
@testable import AGUICore

final class CustomEventTests: XCTestCase,
                                AGUIEventDecoderTestHelpers,
                                EventDecodingErrorTests {

    // MARK: - EventDecodingErrorTests Protocol Requirements

    var validEventFieldsWithoutType: [String: Any] {
        [
            "customType": "my.custom.event",
            "data": ["field1": "value1", "field2": 123]
        ]
    }

    var eventTypeString: String { "CUSTOM" }
    var expectedEventType: EventType { .custom }
    var unknownEventTypeString: String { "UNKNOWN_CUSTOM_EVENT" }

    // MARK: - Feature: Decode CUSTOM

    func test_decodeValidCustom_withObjectData_returnsCustomEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "CUSTOM",
          "customType": "com.example.userAction",
          "data": {
            "action": "buttonClick",
            "buttonId": "submit",
            "metadata": {
              "screen": "login"
            }
          }
        }
        """)

        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        guard let customEvent = event as? CustomEvent else {
            return XCTFail("Expected CustomEvent, got \(type(of: event))")
        }
        XCTAssertEqual(customEvent.eventType, .custom)
        XCTAssertEqual(customEvent.customType, "com.example.userAction")
        XCTAssertNil(customEvent.timestamp)

        // Verify data can be parsed
        let parsed = try customEvent.parsedData() as? [String: Any]
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?["action"] as? String, "buttonClick")
        XCTAssertEqual(parsed?["buttonId"] as? String, "submit")
    }

    func test_decodeCustom_withArrayData_handlesCorrectly() throws {
        // Given
        let data = jsonData("""
        {
          "type": "CUSTOM",
          "customType": "events.batch",
          "data": [
            {"id": 1, "value": "a"},
            {"id": 2, "value": "b"}
          ]
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let customEvent = try XCTUnwrap(event as? CustomEvent)
        XCTAssertEqual(customEvent.customType, "events.batch")
        let parsed = try customEvent.parsedData() as? [[String: Any]]
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.count, 2)
    }

    func test_decodeCustom_withPrimitiveData_handlesCorrectly() throws {
        // Given
        let data = jsonData("""
        {
          "type": "CUSTOM",
          "customType": "simple.message",
          "data": "Hello, World!"
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let customEvent = try XCTUnwrap(event as? CustomEvent)
        XCTAssertEqual(customEvent.customType, "simple.message")
        let parsed = try customEvent.parsedData() as? String
        XCTAssertEqual(parsed, "Hello, World!")
    }

    func test_decodeCustom_withNullData_handlesCorrectly() throws {
        // Given
        let data = jsonData("""
        {
          "type": "CUSTOM",
          "customType": "void.event",
          "data": null
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let customEvent = try XCTUnwrap(event as? CustomEvent)
        XCTAssertEqual(customEvent.customType, "void.event")
        let parsed = try customEvent.parsedData()
        XCTAssertTrue(parsed is NSNull)
    }

    func test_decodeCustom_withDotNotationCustomType_handlesCorrectly() throws {
        // Given
        let data = jsonData("""
        {
          "type": "CUSTOM",
          "customType": "com.myapp.analytics.pageView",
          "data": {"page": "/home"}
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let customEvent = try XCTUnwrap(event as? CustomEvent)
        XCTAssertEqual(customEvent.customType, "com.myapp.analytics.pageView")
    }

    func test_decodeCustom_withTimestamp_populatesTimestamp() throws {
        // Given
        let data = jsonData("""
        {
          "type": "CUSTOM",
          "customType": "test.event",
          "data": { "value": 123 },
          "timestamp": \(EventTestData.timestamp)
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let customEvent = try XCTUnwrap(event as? CustomEvent)
        XCTAssertEqual(customEvent.timestamp, EventTestData.timestamp)
    }

    func test_decodeCustom_preservesRawEventBytes() throws {
        // Given
        let data = jsonData("""
        {
          "type": "CUSTOM",
          "customType": "test.event",
          "data": { "key": "value" },
          "timestamp": \(EventTestData.timestamp)
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let customEvent = try XCTUnwrap(event as? CustomEvent)
        XCTAssertEqual(customEvent.rawEvent, data)
    }

    func test_decodeCustom_ignoresUnknownExtraFields() throws {
        // Given
        let data = jsonData("""
        {
          "type": "CUSTOM",
          "customType": "test.event",
          "data": { "key": "value" },
          "extraField": "ignored",
          "nested": { "x": 1 }
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let customEvent = try XCTUnwrap(event as? CustomEvent)
        let parsed = try customEvent.parsedData() as? [String: Any]
        XCTAssertEqual(parsed?["key"] as? String, "value")
    }

    // MARK: - Feature: Error handling

    func test_decodeCustom_missingCustomType_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "CUSTOM",
          "data": { "key": "value" }
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            guard case .decodingFailed(let message) = error as? EventDecodingError else {
                return XCTFail("Expected decodingFailed, got \(error)")
            }
            XCTAssertTrue(message.contains("customType") || message.contains("Missing key"))
        }
    }

    func test_decodeCustom_missingData_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "CUSTOM",
          "customType": "test.event",
          "timestamp": \(EventTestData.timestamp)
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            guard case .decodingFailed(let message) = error as? EventDecodingError else {
                return XCTFail("Expected decodingFailed, got \(error)")
            }
            XCTAssertTrue(message.contains("data") || message.contains("Missing key"))
        }
    }

    func test_decodeCustom_wrongTypeForCustomType_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "CUSTOM",
          "customType": 123,
          "data": { "key": "value" }
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            guard case .decodingFailed(let message) = error as? EventDecodingError else {
                return XCTFail("Expected decodingFailed, got \(error)")
            }
            XCTAssertTrue(message.contains("customType") || message.contains("Type mismatch"))
        }
    }

    func test_decodeCustom_wrongTypeForTimestamp_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "CUSTOM",
          "customType": "test.event",
          "data": { "key": "value" },
          "timestamp": "not-a-number"
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            guard case .decodingFailed(let message) = error as? EventDecodingError else {
                return XCTFail("Expected decodingFailed, got \(error)")
            }
            XCTAssertTrue(message.contains("timestamp") || message.contains("Type mismatch"))
        }
    }

    // MARK: - Feature: Model behaviors

    func test_customEvent_eventTypeIsAlwaysCustom() throws {
        // Given
        let eventData = try JSONSerialization.data(withJSONObject: ["key": "value"], options: [])
        let event = CustomEvent(customType: "test.event", data: eventData, timestamp: nil, rawEvent: nil)

        // Then
        XCTAssertEqual(event.eventType, .custom)
    }

    func test_customEvent_equatable_sameCustomTypeAndData_areEqual() throws {
        // Given
        let eventData = try JSONSerialization.data(withJSONObject: ["key": "value"], options: [])
        let event1 = CustomEvent(customType: "test.event", data: eventData, timestamp: EventTestData.timestamp, rawEvent: nil)
        let event2 = CustomEvent(customType: "test.event", data: eventData, timestamp: EventTestData.timestamp, rawEvent: nil)

        // Then
        XCTAssertEqual(event1, event2)
    }

    func test_customEvent_equatable_differentCustomTypes_areNotEqual() throws {
        // Given
        let eventData = try JSONSerialization.data(withJSONObject: ["key": "value"], options: [])
        let event1 = CustomEvent(customType: "test.event1", data: eventData, timestamp: EventTestData.timestamp, rawEvent: nil)
        let event2 = CustomEvent(customType: "test.event2", data: eventData, timestamp: EventTestData.timestamp, rawEvent: nil)

        // Then
        XCTAssertNotEqual(event1, event2)
    }

    func test_customEvent_equatable_differentData_areNotEqual() throws {
        // Given
        let eventData1 = try JSONSerialization.data(withJSONObject: ["key": "value1"], options: [])
        let eventData2 = try JSONSerialization.data(withJSONObject: ["key": "value2"], options: [])
        let event1 = CustomEvent(customType: "test.event", data: eventData1, timestamp: EventTestData.timestamp, rawEvent: nil)
        let event2 = CustomEvent(customType: "test.event", data: eventData2, timestamp: EventTestData.timestamp, rawEvent: nil)

        // Then
        XCTAssertNotEqual(event1, event2)
    }

    func test_customEvent_equatable_differentTimestamps_areNotEqual() throws {
        // Given
        let eventData = try JSONSerialization.data(withJSONObject: ["key": "value"], options: [])
        let event1 = CustomEvent(customType: "test.event", data: eventData, timestamp: EventTestData.timestamp, rawEvent: nil)
        let event2 = CustomEvent(customType: "test.event", data: eventData, timestamp: EventTestData.timestamp2, rawEvent: nil)

        // Then
        XCTAssertNotEqual(event1, event2)
    }

    func test_customEvent_parsedData_returnsCorrectValue() throws {
        // Given
        let originalObject: [String: Any] = ["action": "test", "count": 5]
        let eventData = try JSONSerialization.data(withJSONObject: originalObject, options: [])
        let event = CustomEvent(customType: "test.event", data: eventData, timestamp: nil, rawEvent: nil)

        // When
        let parsed = try event.parsedData() as? [String: Any]

        // Then
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?["action"] as? String, "test")
        XCTAssertEqual(parsed?["count"] as? Int, 5)
    }

    func test_customEvent_parsedData_withInvalidData_throws() throws {
        // Given
        let invalidData = Data("not json".utf8)
        let event = CustomEvent(customType: "test.event", data: invalidData, timestamp: nil, rawEvent: nil)

        // When / Then
        XCTAssertThrowsError(try event.parsedData())
    }

    func test_customEvent_parsedDataAs_withCodableType_decodesCorrectly() throws {
        // Given
        struct CustomPayload: Codable, Equatable {
            let action: String
            let userId: Int
        }

        let originalPayload = CustomPayload(action: "login", userId: 12345)
        let eventData = try JSONEncoder().encode(originalPayload)
        let event = CustomEvent(customType: "user.action", data: eventData, timestamp: nil, rawEvent: nil)

        // When
        let decoded = try event.parsedData(as: CustomPayload.self)

        // Then
        XCTAssertEqual(decoded.action, "login")
        XCTAssertEqual(decoded.userId, 12345)
    }

    func test_customEvent_description_containsKeyInformation() throws {
        // Given
        let eventData = try JSONSerialization.data(withJSONObject: ["key": "value"], options: [])
        let event = CustomEvent(customType: "test.event", data: eventData, timestamp: EventTestData.timestamp, rawEvent: nil)

        // Then
        let description = event.description
        XCTAssertTrue(description.contains("CustomEvent"))
        XCTAssertTrue(description.contains("test.event"))
        XCTAssertTrue(description.contains("timestamp"))
    }

    func test_customEvent_debugDescription_containsDetailedInformation() throws {
        // Given
        let eventData = try JSONSerialization.data(withJSONObject: ["key": "value"], options: [])
        let event = CustomEvent(customType: "test.event", data: eventData, timestamp: EventTestData.timestamp, rawEvent: nil)

        // Then
        let debugDescription = event.debugDescription
        XCTAssertTrue(debugDescription.contains("CustomEvent"))
        XCTAssertTrue(debugDescription.contains("test.event"))
        XCTAssertTrue(debugDescription.contains("data"))
    }
}
