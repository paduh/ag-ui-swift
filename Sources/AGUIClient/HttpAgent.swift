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
public struct HttpAgent: Sendable {
    /// The underlying HTTP transport.
    private let transport: HttpTransport

    /// The AG-UI event decoder.
    private let decoder: AGUIEventDecoder

    /// Default endpoint for agent runs.
    private let defaultEndpoint: String

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
        self.init(configuration: HttpAgentConfiguration(baseURL: baseURL))
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
        self.transport = HttpTransport(configuration: configuration)
        self.decoder = AGUIEventDecoder()
        self.defaultEndpoint = "/run"
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
        self.transport = HttpTransport(
            configuration: configuration,
            httpClient: httpClient
        )
        self.decoder = AGUIEventDecoder()
        self.defaultEndpoint = "/run"
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
    ) async throws -> EventStream<URLSession.AsyncBytes> {
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
    ) async throws -> EventStream<URLSession.AsyncBytes> {
        let input = try configure(
            RunAgentInput.builder()
                .threadId(threadId)
                .runId(runId)
        ).build()

        return try await run(input, endpoint: endpoint)
    }
}
