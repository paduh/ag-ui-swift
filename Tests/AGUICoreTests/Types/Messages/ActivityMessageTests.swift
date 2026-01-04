// ActivityMessageTests.swift
// AGUISwift

import XCTest
@testable import AGUICore

/// Tests for the ActivityMessage type
final class ActivityMessageTests: XCTestCase {
    // MARK: - Initialization Tests

    func testInitWithBasicActivity() {
        let content = Data("""
        {
            "text": "Processing request..."
        }
        """.utf8)

        let message = ActivityMessage(
            id: "activity-1",
            activityType: "progress",
            activityContent: content
        )

        XCTAssertEqual(message.id, "activity-1")
        XCTAssertEqual(message.activityType, "progress")
        XCTAssertEqual(message.role, .activity)
        XCTAssertNil(message.content)
        XCTAssertNil(message.name)
    }

    func testInitWithComplexActivity() {
        let content = Data("""
        {
            "type": "chart",
            "data": {
                "labels": ["Jan", "Feb", "Mar"],
                "values": [10, 20, 30]
            }
        }
        """.utf8)

        let message = ActivityMessage(
            id: "activity-2",
            activityType: "visualization",
            activityContent: content
        )

        XCTAssertEqual(message.activityType, "visualization")
        XCTAssertNotNil(message.activityContent)
    }

    // MARK: - Message Protocol Conformance Tests

    func testConformsToMessageProtocol() {
        let content = Data("{}".utf8)
        let message: any Message = ActivityMessage(
            id: "activity-3",
            activityType: "status",
            activityContent: content
        )

        XCTAssertEqual(message.id, "activity-3")
        XCTAssertEqual(message.role, .activity)
        XCTAssertNil(message.content)
        XCTAssertNil(message.name)
    }

    func testRoleIsAlwaysActivity() {
        let content = Data("{}".utf8)
        let message = ActivityMessage(
            id: "1",
            activityType: "test",
            activityContent: content
        )

        XCTAssertEqual(message.role, .activity)
    }

    // MARK: - Encoding Tests

    func testEncodingBasicActivity() throws {
        let content = Data("""
        {"status": "running"}
        """.utf8)

        let message = ActivityMessage(
            id: "activity-encode-1",
            activityType: "progress",
            activityContent: content
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let encoded = try encoder.encode(message)
        let json = String(data: encoded, encoding: .utf8)

        XCTAssertNotNil(json)
        XCTAssertTrue(json?.contains("\"id\"") ?? false)
        XCTAssertTrue(json?.contains("\"role\"") ?? false)
        XCTAssertTrue(json?.contains("\"activity\"") ?? false)
        XCTAssertTrue(json?.contains("\"activityType\"") ?? false)
        XCTAssertTrue(json?.contains("\"activityContent\"") ?? false)
    }

    func testEncodedStructure() throws {
        let content = Data("""
        {"value": 42}
        """.utf8)

        let message = ActivityMessage(
            id: "activity-encode-2",
            activityType: "metric",
            activityContent: content
        )

        let encoded = try JSONEncoder().encode(message)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]

        XCTAssertEqual(json?["role"] as? String, "activity")
        XCTAssertEqual(json?["id"] as? String, "activity-encode-2")
        XCTAssertEqual(json?["activityType"] as? String, "metric")

        let activityContent = json?["activityContent"] as? [String: Any]
        XCTAssertEqual(activityContent?["value"] as? Int, 42)
    }

    // MARK: - Decoding Tests

    func testDecodingBasicActivity() throws {
        let json = """
        {
            "id": "activity-decode-1",
            "role": "activity",
            "activityType": "progress",
            "activityContent": {
                "percent": 75
            }
        }
        """

        let decoder = JSONDecoder()
        let message = try decoder.decode(ActivityMessage.self, from: Data(json.utf8))

        XCTAssertEqual(message.id, "activity-decode-1")
        XCTAssertEqual(message.role, .activity)
        XCTAssertEqual(message.activityType, "progress")
        XCTAssertNil(message.content)
        XCTAssertNil(message.name)

        let activityContent = try JSONSerialization.jsonObject(with: message.activityContent) as? [String: Any]
        XCTAssertEqual(activityContent?["percent"] as? Int, 75)
    }

    func testDecodingComplexActivity() throws {
        let json = """
        {
            "id": "activity-decode-2",
            "role": "activity",
            "activityType": "visualization",
            "activityContent": {
                "type": "chart",
                "data": {
                    "labels": ["A", "B", "C"],
                    "values": [1, 2, 3]
                }
            }
        }
        """

        let decoder = JSONDecoder()
        let message = try decoder.decode(ActivityMessage.self, from: Data(json.utf8))

        XCTAssertEqual(message.activityType, "visualization")

        let content = try JSONSerialization.jsonObject(with: message.activityContent) as? [String: Any]
        XCTAssertEqual(content?["type"] as? String, "chart")

        let data = content?["data"] as? [String: Any]
        let labels = data?["labels"] as? [String]
        XCTAssertEqual(labels, ["A", "B", "C"])
    }

    func testDecodingFailsWithoutId() {
        let json = """
        {
            "role": "activity",
            "activityType": "test",
            "activityContent": {}
        }
        """

        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(ActivityMessage.self, from: Data(json.utf8))) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testDecodingFailsWithoutActivityType() {
        let json = """
        {
            "id": "activity-1",
            "role": "activity",
            "activityContent": {}
        }
        """

        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(ActivityMessage.self, from: Data(json.utf8))) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testDecodingFailsWithoutActivityContent() {
        let json = """
        {
            "id": "activity-1",
            "role": "activity",
            "activityType": "test"
        }
        """

        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(ActivityMessage.self, from: Data(json.utf8))) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    // MARK: - Round-trip Tests

    func testRoundTripBasicActivity() throws {
        let content = Data("""
        {"status": "complete"}
        """.utf8)

        let original = ActivityMessage(
            id: "activity-rt-1",
            activityType: "status",
            activityContent: content
        )

        let encoder = JSONEncoder()
        let encoded = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ActivityMessage.self, from: encoded)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.activityType, original.activityType)
        XCTAssertEqual(decoded.role, original.role)

        let originalContent = try JSONSerialization.jsonObject(with: original.activityContent) as? [String: Any]
        let decodedContent = try JSONSerialization.jsonObject(with: decoded.activityContent) as? [String: Any]
        XCTAssertEqual(originalContent?["status"] as? String, decodedContent?["status"] as? String)
    }

    // MARK: - Equatable Tests

    func testEquality() {
        let content1 = Data("""
        {"value": 1}
        """.utf8)

        let content2 = Data("""
        {"value": 1}
        """.utf8)

        let content3 = Data("""
        {"value": 2}
        """.utf8)

        let message1 = ActivityMessage(id: "1", activityType: "test", activityContent: content1)
        let message2 = ActivityMessage(id: "1", activityType: "test", activityContent: content2)
        let message3 = ActivityMessage(id: "2", activityType: "test", activityContent: content1)
        let message4 = ActivityMessage(id: "1", activityType: "other", activityContent: content1)
        let message5 = ActivityMessage(id: "1", activityType: "test", activityContent: content3)

        XCTAssertEqual(message1, message2)
        XCTAssertNotEqual(message1, message3)
        XCTAssertNotEqual(message1, message4)
        XCTAssertNotEqual(message1, message5)
    }

    // MARK: - Hashable Tests

    func testHashable() {
        let content1 = Data("""
        {"id": 1}
        """.utf8)

        let content2 = Data("""
        {"id": 2}
        """.utf8)

        let message1 = ActivityMessage(id: "1", activityType: "test", activityContent: content1)
        let message2 = ActivityMessage(id: "2", activityType: "test", activityContent: content2)

        let set: Set<ActivityMessage> = [message1, message2]
        XCTAssertEqual(set.count, 2)
        XCTAssertTrue(set.contains(message1))
        XCTAssertTrue(set.contains(message2))
    }

    // MARK: - Sendable Tests

    func testSendableConformance() {
        let content = Data("{}".utf8)
        let message = ActivityMessage(
            id: "activity-concurrent",
            activityType: "test",
            activityContent: content
        )

        Task {
            let capturedMessage = message
            XCTAssertEqual(capturedMessage.id, "activity-concurrent")
        }
    }

    // MARK: - Real-world Usage Tests

    func testProgressIndicator() {
        let content = Data("""
        {
            "percent": 50,
            "message": "Processing files...",
            "current": 5,
            "total": 10
        }
        """.utf8)

        let progress = ActivityMessage(
            id: "progress-1",
            activityType: "progress",
            activityContent: content
        )

        XCTAssertEqual(progress.activityType, "progress")
        XCTAssertEqual(progress.role, .activity)
    }

    func testA2UISurface() {
        let content = Data("""
        {
            "surfaceType": "form",
            "fields": [
                {"name": "email", "type": "text"},
                {"name": "submit", "type": "button"}
            ]
        }
        """.utf8)

        let surface = ActivityMessage(
            id: "surface-1",
            activityType: "a2ui-form",
            activityContent: content
        )

        XCTAssertEqual(surface.activityType, "a2ui-form")
    }

    func testVisualization() {
        let content = Data("""
        {
            "chartType": "bar",
            "data": {
                "labels": ["Q1", "Q2", "Q3", "Q4"],
                "datasets": [
                    {"label": "Sales", "values": [100, 150, 120, 180]}
                ]
            }
        }
        """.utf8)

        let chart = ActivityMessage(
            id: "viz-1",
            activityType: "chart",
            activityContent: content
        )

        XCTAssertEqual(chart.activityType, "chart")
    }

    func testStatusUpdate() {
        let content = Data("""
        {
            "status": "running",
            "step": "validation",
            "timestamp": "2024-01-01T12:00:00Z"
        }
        """.utf8)

        let status = ActivityMessage(
            id: "status-1",
            activityType: "status",
            activityContent: content
        )

        XCTAssertEqual(status.activityType, "status")
        XCTAssertNil(status.content)
    }
}
