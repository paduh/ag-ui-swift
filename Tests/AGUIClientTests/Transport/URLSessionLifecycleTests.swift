// Copyright (c) 2025 Perfect Aduh. MIT License. See LICENSE for details.

@testable import AGUIClient
import Foundation
import XCTest

final class URLSessionLifecycleTests: XCTestCase {
    func testCancellingConsumerStopsUnderlyingRequest() async throws {
        let scenario = StreamScenario()
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        let response = try await URLSessionHTTPClient(session: session).execute(scenario.request)
        let consumer = Task {
            for try await _ in response.bytes {}
        }
        consumer.cancel()
        _ = try? await consumer.value
        await fulfillment(of: [scenario.stopped], timeout: 2)
    }

    func testReleasingResponseStopsRequest() async throws {
        let scenario = StreamScenario()
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        var response: HTTPResponse? = try await URLSessionHTTPClient(session: session).execute(scenario.request)
        XCTAssertNotNil(response)
        response = nil
        await fulfillment(of: [scenario.stopped], timeout: 2)
    }

    func testMidStreamFailureIsReportedAsClientError() async throws {
        let scenario = StreamScenario(failsAfterBody: true)
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        let response = try await URLSessionHTTPClient(session: session).execute(scenario.request)
        do {
            for try await _ in response.bytes {}
            XCTFail("Expected a network error")
        } catch let error as ClientError {
            guard case .networkError = error else { return XCTFail("Unexpected error: \(error)") }
        }
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [LifecycleURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private final class StreamScenario: NSObject {
    let stopped = XCTestExpectation(description: "request stopped")
    let failsAfterBody: Bool

    init(failsAfterBody: Bool = false) {
        self.failsAfterBody = failsAfterBody
    }

    var request: URLRequest {
        let request = NSMutableURLRequest(url: URL(string: "https://stream.example/\(UUID().uuidString)")!)
        URLProtocol.setProperty(self, forKey: "scenario", in: request)
        return request as URLRequest
    }
}

/// Serves headers and one byte, then either fails or keeps the response open.
private final class LifecycleURLProtocol: URLProtocol {
    override class func canInit(with _: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let scenario = URLProtocol.property(forKey: "scenario", in: request) as? StreamScenario else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil,
                                       headerFields: ["Content-Type": "text/event-stream"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data([42]))
        if scenario.failsAfterBody {
            client?.urlProtocol(self, didFailWithError: URLError(.networkConnectionLost))
        }
    }

    override func stopLoading() {
        let scenario = URLProtocol.property(forKey: "scenario", in: request) as? StreamScenario
        scenario?.stopped.fulfill()
    }
}
