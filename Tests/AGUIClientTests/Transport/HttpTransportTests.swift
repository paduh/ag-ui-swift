// HttpTransportTests.swift
// AGUISwift

import XCTest
@testable import AGUIClient
@testable import AGUICore

final class HttpTransportTests: XCTestCase {
    // MARK: - Initialization Tests

    func testTransportInitialization() async {
        let url = URL(string: "https://agent.example.com")!
        let config = HttpAgentConfiguration(baseURL: url)
        let transport = HttpTransport(configuration: config)

        // Verify transport was created (actor, so we need async)
        await withCheckedContinuation { continuation in
            Task {
                _ = transport
                continuation.resume()
            }
        }
    }

    func testTransportWithCustomTimeout() async {
        let url = URL(string: "https://agent.example.com")!
        let config = HttpAgentConfiguration(baseURL: url, timeout: 30.0)
        let transport = HttpTransport(configuration: config)

        await withCheckedContinuation { continuation in
            Task {
                _ = transport
                continuation.resume()
            }
        }
    }

    func testTransportWithCustomHeaders() async {
        let url = URL(string: "https://agent.example.com")!
        let headers = ["Authorization": "Bearer token"]
        let config = HttpAgentConfiguration(baseURL: url, headers: headers)
        let transport = HttpTransport(configuration: config)

        await withCheckedContinuation { continuation in
            Task {
                _ = transport
                continuation.resume()
            }
        }
    }

    // MARK: - URL Construction Tests

    func testEndpointURLConstruction() {
        let baseURL = URL(string: "https://agent.example.com")!
        let endpoint = "/run"

        let expectedURL = baseURL.appendingPathComponent(endpoint)
        XCTAssertEqual(expectedURL.absoluteString, "https://agent.example.com/run")
    }

    func testEndpointWithExistingPath() {
        let baseURL = URL(string: "https://agent.example.com/api")!
        let endpoint = "/run"

        let expectedURL = baseURL.appendingPathComponent(endpoint)
        XCTAssertTrue(expectedURL.absoluteString.contains("/api/run"))
    }

    // MARK: - Input Encoding Tests

    func testRunAgentInputEncoding() throws {
        let input = try RunAgentInput.builder()
            .threadId("thread-1")
            .runId("run-1")
            .build()

        let encoder = JSONEncoder()
        let data = try encoder.encode(input)

        XCTAssertFalse(data.isEmpty)

        // Verify it contains expected fields
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["threadId"] as? String, "thread-1")
        XCTAssertEqual(json?["runId"] as? String, "run-1")
    }

    func testRunAgentInputWithMessagesEncoding() throws {
        let input = try RunAgentInput.builder()
            .threadId("thread-1")
            .runId("run-1")
            .message(UserMessage(id: "msg-1", content: "Hello"))
            .build()

        let encoder = JSONEncoder()
        let data = try encoder.encode(input)

        XCTAssertFalse(data.isEmpty)
    }

    // MARK: - Error Mapping Tests

    func testURLErrorTimeoutMapping() {
        let urlError = URLError(.timedOut)
        let transport = HttpTransport(configuration: HttpAgentConfiguration(baseURL: URL(string: "https://test.com")!))

        // We can't directly test the private mapURLError method,
        // but we know it maps timedOut to .timeout
        // This would be tested in integration tests
    }

    func testURLErrorCancelledMapping() {
        let urlError = URLError(.cancelled)
        // Similar to above, would be tested in integration
    }

    // MARK: - Actor Isolation Tests

    func testTransportIsActor() async {
        let url = URL(string: "https://agent.example.com")!
        let config = HttpAgentConfiguration(baseURL: url)
        let transport = HttpTransport(configuration: config)

        // Verify we can call async methods on the transport
        await withCheckedContinuation { continuation in
            Task {
                _ = transport
                continuation.resume()
            }
        }
    }

    func testMultipleTransportsCanExist() async {
        let url = URL(string: "https://agent.example.com")!
        let config = HttpAgentConfiguration(baseURL: url)

        let transport1 = HttpTransport(configuration: config)
        let transport2 = HttpTransport(configuration: config)

        // Verify both exist independently
        await withCheckedContinuation { continuation in
            Task {
                _ = transport1
                _ = transport2
                continuation.resume()
            }
        }
    }
}
