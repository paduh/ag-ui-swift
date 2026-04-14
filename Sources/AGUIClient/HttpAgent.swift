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
import Foundation

/// High-level HTTP client for AG-UI agent communication.
///
/// `HttpAgent` provides a convenient, fluent API for executing agent runs
/// and streaming AG-UI events. It wraps the lower-level transport and streaming
/// infrastructure with an easy-to-use interface.
///
/// ## Basic Usage
///
/// ```swift
/// let agent = HttpAgent(baseURL: URL(string: "https://agent.example.com")!)
///
/// let stream = try await agent.run(threadId: "thread-1", runId: "run-1") { builder in
///     builder.message(UserMessage(
///         id: "msg1",
///         content: [TextInputContent(text: "Hello!")]
///     ))
/// }
///
/// for try await event in stream {
///     switch event.eventType {
///     case .textMessageChunk:
///         let chunk = event as! TextMessageChunkEvent
///         print(chunk.delta ?? "", terminator: "")
///     case .runFinished:
///         print("\nDone!")
///     default:
///         break
///     }
/// }
/// ```
///
/// ## Advanced Usage
///
/// ```swift
/// var config = HttpAgentConfiguration(baseURL: agentURL)
/// config.timeout = 120.0
/// config.headers = ["Authorization": "Bearer token"]
///
/// let agent = HttpAgent(configuration: config)
///
/// let input = try RunAgentInput.builder()
///     .threadId("thread-1")
///     .runId("run-1")
///     .message(DeveloperMessage(
///         id: "dev1",
///         content: [TextInputContent(text: "System prompt")]
///     ))
///     .message(UserMessage(
///         id: "user1",
///         content: [TextInputContent(text: "User query")]
///     ))
///     .tool(weatherTool)
///     .context(Context(description: "timezone", value: "UTC"))
///     .build()
///
/// let stream = try await agent.run(input, endpoint: "/custom/run")
/// ```
///
/// ## Error Handling
///
/// ```swift
/// do {
///     let stream = try await agent.run(threadId: "t1", runId: "r1")
///     for try await event in stream {
///         // Process events
///     }
/// } catch ClientError.httpError(let statusCode) {
///     print("HTTP error: \(statusCode)")
/// } catch ClientError.timeout {
///     print("Request timed out")
/// } catch {
///     print("Unexpected error: \(error)")
/// }
/// ```
///
/// ## Thread Safety
///
/// `HttpAgent` is safe to use across multiple concurrent tasks. Each run
/// creates an isolated stream with its own state.
public final class HttpAgent: AbstractAgent, @unchecked Sendable {
    /// The underlying HTTP transport.
    private let transport: HttpTransport

    /// The AG-UI event decoder.
    private let decoder: AGUIEventDecoder

    /// Default endpoint for agent runs.
    private let defaultEndpoint: String

    /// Agent configuration — stored so retry helpers can read `retryPolicy`.
    private let configuration: HttpAgentConfiguration

    /// Creates a new HTTP agent with a base URL.
    ///
    /// This convenience initializer creates an agent with default configuration.
    ///
    /// - Parameter baseURL: The base URL of the AG-UI agent
    ///
    /// ## Example
    ///
    /// ```swift
    /// let agent = HttpAgent(baseURL: URL(string: "https://agent.example.com")!)
    /// ```
    public init(baseURL: URL) {
        let config = HttpAgentConfiguration(baseURL: baseURL)
        self.configuration = config
        self.transport = HttpTransport(configuration: config)
        self.decoder = AGUIEventDecoder()
        self.defaultEndpoint = "/run"
        super.init()
    }

    /// Creates a new HTTP agent with custom configuration.
    ///
    /// - Parameter configuration: The HTTP agent configuration
    ///
    /// ## Example
    ///
    /// ```swift
    /// var config = HttpAgentConfiguration(baseURL: agentURL)
    /// config.timeout = 120.0
    /// config.headers = ["Authorization": "Bearer token"]
    ///
    /// let agent = HttpAgent(configuration: config)
    /// ```
    public init(configuration: HttpAgentConfiguration) {
        self.configuration = configuration
        self.transport = HttpTransport(configuration: configuration)
        self.decoder = AGUIEventDecoder()
        self.defaultEndpoint = "/run"
        super.init(debug: configuration.debug)
    }

    /// Creates a new HTTP agent with custom HTTP client.
    ///
    /// This initializer allows dependency injection of a custom HTTP client,
    /// useful for testing or custom network implementations.
    ///
    /// - Parameters:
    ///   - configuration: The HTTP agent configuration
    ///   - httpClient: Custom HTTP client implementation
    ///
    /// ## Example
    ///
    /// ```swift
    /// let mockClient = MockHTTPClient()
    /// let agent = HttpAgent(
    ///     configuration: config,
    ///     httpClient: mockClient
    /// )
    /// ```
    public init(
        configuration: HttpAgentConfiguration,
        httpClient: any HTTPClient
    ) {
        self.configuration = configuration
        self.transport = HttpTransport(
            configuration: configuration,
            httpClient: httpClient
        )
        self.decoder = AGUIEventDecoder()
        self.defaultEndpoint = "/run"
        super.init()
    }

    /// Executes an agent run with the provided input.
    ///
    /// This is the most explicit run method, accepting a fully-configured
    /// `RunAgentInput` object.
    ///
    /// - Parameters:
    ///   - input: The run agent input
    ///   - endpoint: Custom endpoint (default: "/run")
    /// - Returns: AsyncSequence of AG-UI events
    /// - Throws: `ClientError` if the request fails
    ///
    /// ## Example
    ///
    /// ```swift
    /// let input = try RunAgentInput.builder()
    ///     .threadId("thread-1")
    ///     .runId("run-1")
    ///     .message(UserMessage(id: "msg1", content: [TextInputContent(text: "Hi")]))
    ///     .build()
    ///
    /// let stream = try await agent.run(input)
    /// for try await event in stream {
    ///     print(event)
    /// }
    /// ```
    public func run(
        _ input: RunAgentInput,
        endpoint: String? = nil
    ) async throws -> EventStream<AsyncThrowingStream<UInt8, Error>> {
        let bytes = try await transport.execute(
            endpoint: endpoint ?? defaultEndpoint,
            input: input
        )

        return EventStream(bytes: bytes, decoder: decoder)
    }

    /// Executes an agent run with builder configuration.
    ///
    /// This method provides a fluent interface for configuring the run input
    /// using a builder pattern.
    ///
    /// - Parameters:
    ///   - threadId: The thread identifier
    ///   - runId: The run identifier
    ///   - endpoint: Custom endpoint (default: "/run")
    ///   - configure: Closure to configure the input builder
    /// - Returns: AsyncSequence of AG-UI events
    /// - Throws: `ClientError` if the request fails
    ///
    /// ## Example
    ///
    /// ```swift
    /// let stream = try await agent.run(
    ///     threadId: "thread-1",
    ///     runId: "run-1"
    /// ) { builder in
    ///     builder
    ///         .message(DeveloperMessage(
    ///             id: "dev1",
    ///             content: [TextInputContent(text: "You are helpful")]
    ///         ))
    ///         .message(UserMessage(
    ///             id: "user1",
    ///             content: [TextInputContent(text: "Hello!")]
    ///         ))
    ///         .tool(weatherTool)
    ///         .context(Context(description: "timezone", value: "UTC"))
    /// }
    ///
    /// for try await event in stream {
    ///     // Process events
    /// }
    /// ```
    public func run(
        threadId: String,
        runId: String,
        endpoint: String? = nil,
        configure: (RunAgentInputBuilder) -> RunAgentInputBuilder = { $0 }
    ) async throws -> EventStream<AsyncThrowingStream<UInt8, Error>> {
        let input = try configure(
            RunAgentInput.builder()
                .threadId(threadId)
                .runId(runId)
        ).build()

        return try await run(input, endpoint: endpoint)
    }

    // MARK: - AbstractAgent override

    /// Returns a stream of raw AG-UI events with automatic retry on transient failures.
    ///
    /// This override bridges `AbstractAgent.run(input:)` to the underlying
    /// `HttpTransport` and applies the retry policy configured in
    /// `HttpAgentConfiguration.retryPolicy`. On each retry, the `Last-Event-ID`
    /// header is sent with the most recent SSE event id so compliant servers can
    /// resume the stream from where it dropped.
    ///
    /// ### Retry behaviour
    ///
    /// | Policy | Behaviour |
    /// |--------|-----------|
    /// | `.none` (default) | No retry — errors propagate immediately |
    /// | `.fixed(maxAttempts:delay:)` | Up to `maxAttempts` retries, each preceded by a fixed `delay` |
    /// | `.exponentialBackoff(maxAttempts:baseDelay:)` | Up to `maxAttempts` retries, delay doubles each attempt (capped at 60 s) |
    ///
    /// ### Retryable errors
    ///
    /// Only transient, network-level errors trigger a retry:
    /// - `ClientError.timeout`
    /// - `ClientError.networkError`
    ///
    /// Server errors (`httpError`, `invalidResponse`) are not retried.
    ///
    /// - Parameter input: The run agent input.
    /// - Returns: An `AsyncThrowingStream` of AG-UI events from the server.
    public override func run(input: RunAgentInput) -> AsyncThrowingStream<any AGUIEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                var lastEventId: String? = nil
                var attempt = 0
                // Hold a reference to the current EventStream so we can read
                // lastEventId after a mid-stream failure (the stream is a struct but
                // its lastEventIdBox is a reference type — still readable after throw).
                var currentStream: EventStream<AsyncThrowingStream<UInt8, Error>>? = nil

                while true {
                    do {
                        let bytes = try await self.transport.execute(
                            endpoint: self.defaultEndpoint,
                            input: input,
                            lastEventId: lastEventId
                        )
                        let eventStream = EventStream(bytes: bytes, decoder: self.decoder)
                        currentStream = eventStream
                        for try await event in eventStream {
                            continuation.yield(event)
                        }
                        continuation.finish()
                        return
                    } catch {
                        // Capture the last-event-id from the stream that just failed
                        // (nil when the failure happened before streaming began).
                        if let stream = currentStream {
                            lastEventId = stream.lastEventId ?? lastEventId
                        }
                        currentStream = nil

                        guard self.shouldRetry(error: error, attempt: attempt) else {
                            continuation.finish(throwing: error)
                            return
                        }

                        let delay = self.retryDelay(for: attempt)
                        attempt += 1

                        if delay > 0 {
                            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Retry helpers

    /// Returns `true` when `error` is a transient network failure and the retry
    /// policy permits another attempt.
    private func shouldRetry(error: Error, attempt: Int) -> Bool {
        guard isRetryable(error) else { return false }
        switch configuration.retryPolicy {
        case .none:
            return false
        case .fixed(let maxAttempts, _):
            return attempt < maxAttempts
        case .exponentialBackoff(let maxAttempts, _):
            return attempt < maxAttempts
        }
    }

    /// Returns `true` for errors that represent a transient network condition
    /// (not a deliberate server-side rejection).
    private func isRetryable(_ error: Error) -> Bool {
        guard let clientError = error as? ClientError else { return false }
        switch clientError {
        case .timeout, .networkError:
            return true
        default:
            return false
        }
    }

    /// Returns the sleep interval (in seconds) before attempt `attempt`.
    private func retryDelay(for attempt: Int) -> TimeInterval {
        switch configuration.retryPolicy {
        case .none:
            return 0
        case .fixed(_, let delay):
            return delay
        case .exponentialBackoff(_, let baseDelay):
            // 2^attempt * baseDelay, capped at 60 s to avoid unbounded waits
            return min(baseDelay * pow(2.0, Double(attempt)), 60.0)
        }
    }
}
