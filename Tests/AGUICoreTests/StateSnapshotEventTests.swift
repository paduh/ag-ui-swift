import XCTest
@testable import AGUICore

final class StateSnapshotEventTests: XCTestCase {

    // MARK: - Feature: Decode STATE_SNAPSHOT

    func test_decodeValidStateSnapshot_withObjectSnapshot_returnsStateSnapshotEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "STATE_SNAPSHOT",
          "snapshot": {
            "users": ["alice", "bob"],
            "count": 2,
            "active": true
          }
        }
        """)

        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        guard let stateSnapshot = event as? StateSnapshotEvent else {
            return XCTFail("Expected StateSnapshotEvent, got \(type(of: event))")
        }
        XCTAssertEqual(stateSnapshot.eventType, .stateSnapshot)
        XCTAssertNil(stateSnapshot.timestamp)

        // Verify snapshot can be parsed
        let parsed = try stateSnapshot.parsedSnapshot() as? [String: Any]
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?["count"] as? Int, 2)
        XCTAssertEqual(parsed?["active"] as? Bool, true)
    }

    func test_decodeStateSnapshot_withArraySnapshot_handlesCorrectly() throws {
        // Given
        let data = jsonData("""
        {
          "type": "STATE_SNAPSHOT",
          "snapshot": [1, 2, 3, "four", true]
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let stateSnapshot = try XCTUnwrap(event as? StateSnapshotEvent)
        let parsed = try stateSnapshot.parsedSnapshot() as? [Any]
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.count, 5)
    }

    func test_decodeStateSnapshot_withPrimitiveSnapshot_handlesCorrectly() throws {
        // Given
        let data = jsonData("""
        {
          "type": "STATE_SNAPSHOT",
          "snapshot": "simple string state"
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let stateSnapshot = try XCTUnwrap(event as? StateSnapshotEvent)
        let parsed = try stateSnapshot.parsedSnapshot() as? String
        XCTAssertEqual(parsed, "simple string state")
    }

    func test_decodeStateSnapshot_withNumberSnapshot_handlesCorrectly() throws {
        // Given
        let data = jsonData("""
        {
          "type": "STATE_SNAPSHOT",
          "snapshot": 42
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let stateSnapshot = try XCTUnwrap(event as? StateSnapshotEvent)
        let parsed = try stateSnapshot.parsedSnapshot() as? Int
        XCTAssertEqual(parsed, 42)
    }

    func test_decodeStateSnapshot_withBooleanSnapshot_handlesCorrectly() throws {
        // Given
        let data = jsonData("""
        {
          "type": "STATE_SNAPSHOT",
          "snapshot": false
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let stateSnapshot = try XCTUnwrap(event as? StateSnapshotEvent)
        let parsed = try stateSnapshot.parsedSnapshot() as? Bool
        XCTAssertEqual(parsed, false)
    }

    func test_decodeStateSnapshot_withNullSnapshot_handlesCorrectly() throws {
        // Given
        let data = jsonData("""
        {
          "type": "STATE_SNAPSHOT",
          "snapshot": null
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let stateSnapshot = try XCTUnwrap(event as? StateSnapshotEvent)
        let parsed = try stateSnapshot.parsedSnapshot()
        XCTAssertTrue(parsed is NSNull)
    }

    func test_decodeStateSnapshot_withTimestamp_populatesTimestamp() throws {
        // Given
        let data = jsonData("""
        {
          "type": "STATE_SNAPSHOT",
          "snapshot": { "value": 123 },
          "timestamp": 1704067200000
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let stateSnapshot = try XCTUnwrap(event as? StateSnapshotEvent)
        XCTAssertEqual(stateSnapshot.timestamp, 1704067200000)
    }

    func test_decodeStateSnapshot_preservesRawEventBytes() throws {
        // Given
        let data = jsonData("""
        {
          "type": "STATE_SNAPSHOT",
          "snapshot": { "key": "value" },
          "timestamp": 1704067200000
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let stateSnapshot = try XCTUnwrap(event as? StateSnapshotEvent)
        XCTAssertEqual(stateSnapshot.rawEvent, data)
    }

    func test_decodeStateSnapshot_ignoresUnknownExtraFields() throws {
        // Given
        let data = jsonData("""
        {
          "type": "STATE_SNAPSHOT",
          "snapshot": { "key": "value" },
          "extraField": "ignored",
          "nested": { "x": 1 }
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let stateSnapshot = try XCTUnwrap(event as? StateSnapshotEvent)
        let parsed = try stateSnapshot.parsedSnapshot() as? [String: Any]
        XCTAssertEqual(parsed?["key"] as? String, "value")
    }

    func test_decodeStateSnapshot_withComplexNestedSnapshot_handlesCorrectly() throws {
        // Given
        let data = jsonData("""
        {
          "type": "STATE_SNAPSHOT",
          "snapshot": {
            "users": [
              { "id": 1, "name": "Alice", "roles": ["admin", "user"] },
              { "id": 2, "name": "Bob", "roles": ["user"] }
            ],
            "metadata": {
              "version": "1.0",
              "timestamp": 1234567890
            }
          }
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let stateSnapshot = try XCTUnwrap(event as? StateSnapshotEvent)
        let parsed = try stateSnapshot.parsedSnapshot() as? [String: Any]
        let users = parsed?["users"] as? [[String: Any]]
        XCTAssertEqual(users?.count, 2)
        XCTAssertEqual(users?[0]["name"] as? String, "Alice")
    }

    func test_decodeStateSnapshot_withUnicodeInSnapshot_handlesCorrectly() throws {
        // Given
        let data = jsonData("""
        {
          "type": "STATE_SNAPSHOT",
          "snapshot": {
            "message": "Hello, 🌍! 你好",
            "city": "北京"
          }
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let stateSnapshot = try XCTUnwrap(event as? StateSnapshotEvent)
        let parsed = try stateSnapshot.parsedSnapshot() as? [String: Any]
        XCTAssertEqual(parsed?["message"] as? String, "Hello, 🌍! 你好")
        XCTAssertEqual(parsed?["city"] as? String, "北京")
    }

    func test_decodeStateSnapshot_withEmptyObjectSnapshot_handlesCorrectly() throws {
        // Given
        let data = jsonData("""
        {
          "type": "STATE_SNAPSHOT",
          "snapshot": {}
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let stateSnapshot = try XCTUnwrap(event as? StateSnapshotEvent)
        let parsed = try stateSnapshot.parsedSnapshot() as? [String: Any]
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.count, 0)
    }

    func test_decodeStateSnapshot_withEmptyArraySnapshot_handlesCorrectly() throws {
        // Given
        let data = jsonData("""
        {
          "type": "STATE_SNAPSHOT",
          "snapshot": []
        }
        """)
        let decoder = makeStrictDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let stateSnapshot = try XCTUnwrap(event as? StateSnapshotEvent)
        let parsed = try stateSnapshot.parsedSnapshot() as? [Any]
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.count, 0)
    }

    // MARK: - Feature: Error handling

    func test_decodeMissingType_throwsMissingTypeField() {
        // Given
        let data = jsonData("""
        {
          "snapshot": { "key": "value" }
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            XCTAssertEqual(error as? EventDecodingError, .missingTypeField)
        }
    }

    func test_decodeUnknownType_inStrictMode_throwsUnknownEventType() {
        // Given
        let data = jsonData("""
        {
          "type": "UNKNOWN_STATE_EVENT",
          "snapshot": { "key": "value" }
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            guard case .unknownEventType(let type) = error as? EventDecodingError else {
                return XCTFail("Expected unknownEventType, got \(error)")
            }
            XCTAssertEqual(type, "UNKNOWN_STATE_EVENT")
        }
    }

    func test_decodeUnknownType_inTolerantMode_returnsUnknownEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "UNKNOWN_STATE_EVENT",
          "snapshot": { "key": "value" }
        }
        """)
        let decoder = makeTolerantDecoder()

        // When
        let event = try decoder.decode(data)

        // Then
        let unknown = try XCTUnwrap(event as? UnknownEvent)
        XCTAssertEqual(unknown.typeRaw, "UNKNOWN_STATE_EVENT")
        XCTAssertEqual(unknown.rawEvent, data)
    }

    func test_decodeKnownTypeButNoHandler_inStrictMode_throwsUnsupportedEventType() {
        // Given
        let data = jsonData("""
        {
          "type": "STATE_SNAPSHOT",
          "snapshot": { "key": "value" }
        }
        """)

        // registry intentionally empty -> handler missing
        let decoder = makeStrictDecoder(registry: [:])

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            XCTAssertEqual(error as? EventDecodingError, .unsupportedEventType(.stateSnapshot))
        }
    }

    func test_decodeKnownTypeButNoHandler_inTolerantMode_returnsUnknownEvent() throws {
        // Given
        let data = jsonData("""
        {
          "type": "STATE_SNAPSHOT",
          "snapshot": { "key": "value" }
        }
        """)
        let decoder = makeTolerantDecoder(registry: [:])

        // When
        let event = try decoder.decode(data)

        // Then
        let unknown = try XCTUnwrap(event as? UnknownEvent)
        XCTAssertEqual(unknown.typeRaw, "STATE_SNAPSHOT")
        XCTAssertEqual(unknown.rawEvent, data)
    }

    func test_decodeStateSnapshot_missingSnapshot_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "STATE_SNAPSHOT",
          "timestamp": 1704067200000
        }
        """)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            guard case .decodingFailed(let message) = error as? EventDecodingError else {
                return XCTFail("Expected decodingFailed, got \(error)")
            }
            XCTAssertTrue(message.contains("snapshot") || message.contains("Missing key"))
        }
    }

    func test_decodeStateSnapshot_wrongTypeForTimestamp_throwsDecodingFailed() {
        // Given
        let data = jsonData("""
        {
          "type": "STATE_SNAPSHOT",
          "snapshot": { "key": "value" },
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

    func test_decodeInvalidJSON_throwsInvalidJSON() {
        // Given
        let data = Data("invalid json".utf8)
        let decoder = makeStrictDecoder()

        // When / Then
        XCTAssertThrowsError(try decoder.decode(data)) { error in
            XCTAssertEqual(error as? EventDecodingError, .invalidJSON)
        }
    }

    // MARK: - Feature: Model behaviors

    func test_stateSnapshotEvent_eventTypeIsAlwaysStateSnapshot() {
        // Given
        let snapshotData = try! JSONSerialization.data(withJSONObject: ["key": "value"], options: [])
        let event = StateSnapshotEvent(snapshot: snapshotData, timestamp: nil, rawEvent: nil)

        // Then
        XCTAssertEqual(event.eventType, .stateSnapshot)
    }

    func test_stateSnapshotEvent_equatable_sameSnapshots_areEqual() throws {
        // Given
        let snapshotData = try! JSONSerialization.data(withJSONObject: ["key": "value"], options: [])
        let a = StateSnapshotEvent(snapshot: snapshotData, timestamp: 1, rawEvent: nil)
        let b = StateSnapshotEvent(snapshot: snapshotData, timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertEqual(a, b)
    }

    func test_stateSnapshotEvent_equatable_differentSnapshots_areNotEqual() throws {
        // Given
        let snapshotData1 = try! JSONSerialization.data(withJSONObject: ["key": "value1"], options: [])
        let snapshotData2 = try! JSONSerialization.data(withJSONObject: ["key": "value2"], options: [])
        let a = StateSnapshotEvent(snapshot: snapshotData1, timestamp: 1, rawEvent: nil)
        let b = StateSnapshotEvent(snapshot: snapshotData2, timestamp: 1, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_stateSnapshotEvent_equatable_differentTimestamps_areNotEqual() throws {
        // Given
        let snapshotData = try! JSONSerialization.data(withJSONObject: ["key": "value"], options: [])
        let a = StateSnapshotEvent(snapshot: snapshotData, timestamp: 1, rawEvent: nil)
        let b = StateSnapshotEvent(snapshot: snapshotData, timestamp: 2, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_stateSnapshotEvent_equatable_oneWithTimestampOneWithout_areNotEqual() throws {
        // Given
        let snapshotData = try! JSONSerialization.data(withJSONObject: ["key": "value"], options: [])
        let a = StateSnapshotEvent(snapshot: snapshotData, timestamp: 1, rawEvent: nil)
        let b = StateSnapshotEvent(snapshot: snapshotData, timestamp: nil, rawEvent: nil)

        // Then
        XCTAssertNotEqual(a, b)
    }

    func test_stateSnapshotEvent_parsedSnapshot_returnsCorrectValue() throws {
        // Given
        let originalObject: [String: Any] = ["key": "value", "number": 42]
        let snapshotData = try JSONSerialization.data(withJSONObject: originalObject, options: [])
        let event = StateSnapshotEvent(snapshot: snapshotData, timestamp: nil, rawEvent: nil)

        // When
        let parsed = try event.parsedSnapshot() as? [String: Any]

        // Then
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?["key"] as? String, "value")
        XCTAssertEqual(parsed?["number"] as? Int, 42)
    }

    func test_stateSnapshotEvent_parsedSnapshot_withInvalidData_throws() throws {
        // Given
        let invalidData = Data("not json".utf8)
        let event = StateSnapshotEvent(snapshot: invalidData, timestamp: nil, rawEvent: nil)

        // When / Then
        XCTAssertThrowsError(try event.parsedSnapshot())
    }

    func test_stateSnapshotEvent_parsedSnapshotAs_withCodableType_decodesCorrectly() throws {
        // Given
        struct AppState: Codable {
            let users: [String]
            let count: Int
            let active: Bool
        }

        let originalState = AppState(users: ["alice", "bob"], count: 2, active: true)
        let snapshotData = try JSONEncoder().encode(originalState)
        let event = StateSnapshotEvent(snapshot: snapshotData, timestamp: nil, rawEvent: nil)

        // When
        let decoded = try event.parsedSnapshot(as: AppState.self)

        // Then
        XCTAssertEqual(decoded.users, ["alice", "bob"])
        XCTAssertEqual(decoded.count, 2)
        XCTAssertEqual(decoded.active, true)
    }

    func test_stateSnapshotEvent_parsedSnapshotAs_withWrongType_throws() throws {
        // Given
        struct AppState: Codable {
            let users: [String]
        }

        struct WrongState: Decodable {
            let wrongField: String
        }

        let originalState = AppState(users: ["alice"])
        let snapshotData = try JSONEncoder().encode(originalState)
        let event = StateSnapshotEvent(snapshot: snapshotData, timestamp: nil, rawEvent: nil)

        // When / Then
        XCTAssertThrowsError(try event.parsedSnapshot(as: WrongState.self)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    // MARK: - Helper Methods

    private func makeStrictDecoder(registry: [EventType: AGUIEventDecoder.DecodeHandler] = AGUIEventDecoder.defaultRegistry()) -> AGUIEventDecoder {
        var config = AGUIEventDecoder.Configuration()
        config.unknownEventStrategy = .throwError
        return AGUIEventDecoder(config: config, registry: registry)
    }

    private func makeTolerantDecoder(registry: [EventType: AGUIEventDecoder.DecodeHandler] = AGUIEventDecoder.defaultRegistry()) -> AGUIEventDecoder {
        var config = AGUIEventDecoder.Configuration()
        config.unknownEventStrategy = .returnUnknown
        return AGUIEventDecoder(config: config, registry: registry)
    }

    private func jsonData(_ jsonString: String) -> Data {
        jsonString.data(using: .utf8)!
    }
}

