// HttpAgentConfigurationTests.swift
// AGUISwift

import XCTest
@testable import AGUIClient

final class HttpAgentConfigurationTests: XCTestCase {
    // MARK: - Initialization Tests

    func testDefaultInitialization() {
        let url = URL(string: "https://agent.example.com")!
        let config = HttpAgentConfiguration(baseURL: url)

        XCTAssertEqual(config.baseURL, url)
        XCTAssertEqual(config.timeout, 120.0)
        XCTAssertTrue(config.headers.isEmpty)

        if case .none = config.retryPolicy {
            // Success
        } else {
            XCTFail("Expected retry policy to be .none")
        }
    }

    func testCustomTimeout() {
        let url = URL(string: "https://agent.example.com")!
        let config = HttpAgentConfiguration(baseURL: url, timeout: 60.0)

        XCTAssertEqual(config.timeout, 60.0)
    }

    func testCustomHeaders() {
        let url = URL(string: "https://agent.example.com")!
        let headers = ["Authorization": "Bearer token", "Custom-Header": "value"]
        let config = HttpAgentConfiguration(baseURL: url, headers: headers)

        XCTAssertEqual(config.headers, headers)
    }

    func testFixedRetryPolicy() {
        let url = URL(string: "https://agent.example.com")!
        let config = HttpAgentConfiguration(
            baseURL: url,
            retryPolicy: .fixed(maxAttempts: 3, delay: 1.0)
        )

        if case .fixed(let attempts, let delay) = config.retryPolicy {
            XCTAssertEqual(attempts, 3)
            XCTAssertEqual(delay, 1.0)
        } else {
            XCTFail("Expected fixed retry policy")
        }
    }

    func testExponentialBackoffRetryPolicy() {
        let url = URL(string: "https://agent.example.com")!
        let config = HttpAgentConfiguration(
            baseURL: url,
            retryPolicy: .exponentialBackoff(maxAttempts: 5, baseDelay: 2.0)
        )

        if case .exponentialBackoff(let attempts, let delay) = config.retryPolicy {
            XCTAssertEqual(attempts, 5)
            XCTAssertEqual(delay, 2.0)
        } else {
            XCTFail("Expected exponential backoff retry policy")
        }
    }

    // MARK: - Factory Method Tests

    func testCreateFromValidURLString() throws {
        let config = try HttpAgentConfiguration.create(baseURLString: "https://agent.example.com")

        XCTAssertEqual(config.baseURL.absoluteString, "https://agent.example.com")
    }

    func testCreateFromInvalidURLString() {
        // Note: URL(string:) is very permissive and creates relative URLs
        // Testing with a string that has invalid characters
        XCTAssertThrowsError(try HttpAgentConfiguration.create(baseURLString: "ht tp://invalid")) { error in
            XCTAssertEqual(error as? ClientError, ClientError.invalidURL)
        }
    }

    func testCreateFromEmptyString() {
        XCTAssertThrowsError(try HttpAgentConfiguration.create(baseURLString: "")) { error in
            XCTAssertEqual(error as? ClientError, ClientError.invalidURL)
        }
    }

    // MARK: - Mutability Tests

    func testConfigurationIsMutable() {
        let url = URL(string: "https://agent.example.com")!
        var config = HttpAgentConfiguration(baseURL: url)

        config.timeout = 30.0
        XCTAssertEqual(config.timeout, 30.0)

        config.headers["Custom"] = "Value"
        XCTAssertEqual(config.headers["Custom"], "Value")
    }

    // MARK: - Sendable Conformance

    func testConfigurationIsSendable() async {
        let url = URL(string: "https://agent.example.com")!
        let config = HttpAgentConfiguration(baseURL: url)

        // Test that config can be sent across actor boundaries
        await withCheckedContinuation { continuation in
            Task {
                _ = config  // Capture in async context
                continuation.resume()
            }
        }
    }

    // MARK: - URL Construction Tests

    func testBaseURLWithPath() {
        let url = URL(string: "https://agent.example.com/api")!
        let config = HttpAgentConfiguration(baseURL: url)

        XCTAssertEqual(config.baseURL.path, "/api")
    }

    func testBaseURLWithPort() {
        let url = URL(string: "https://agent.example.com:8080")!
        let config = HttpAgentConfiguration(baseURL: url)

        XCTAssertEqual(config.baseURL.port, 8080)
    }
}
