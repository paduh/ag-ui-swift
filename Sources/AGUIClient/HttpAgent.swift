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

public final class HttpAgent: Sendable {
    private let abstractAgent: AbstractAgent
    private let httpTransport: HttpTransport
    private let decoder: AGUIEventDecoder
    private let defaultEndpoint: String

    public init(baseURL: URL) {
        let config = HttpAgentConfiguration(baseURL: baseURL)
        let agentTransport = HttpAgentTransport(configuration: config)
        self.abstractAgent = AbstractAgent(transport: agentTransport, debug: config.debug)
        self.httpTransport = HttpTransport(configuration: config)
        self.decoder = AGUIEventDecoder()
        self.defaultEndpoint = "/run"
    }

    public init(configuration: HttpAgentConfiguration) {
        let agentTransport = HttpAgentTransport(configuration: configuration)
        self.abstractAgent = AbstractAgent(transport: agentTransport, debug: configuration.debug)
        self.httpTransport = HttpTransport(configuration: configuration)
        self.decoder = AGUIEventDecoder()
        self.defaultEndpoint = "/run"
    }

    public init(
        configuration: HttpAgentConfiguration,
        httpClient: any HTTPClient
    ) {
        let agentTransport = HttpAgentTransport(configuration: configuration, httpClient: httpClient)
        self.abstractAgent = AbstractAgent(transport: agentTransport, debug: configuration.debug)
        self.httpTransport = HttpTransport(configuration: configuration, httpClient: httpClient)
        self.decoder = AGUIEventDecoder()
        self.defaultEndpoint = "/run"
    }

    public func run(
        _ input: RunAgentInput,
        endpoint: String? = nil
    ) async throws -> EventStream<AsyncThrowingStream<UInt8, Error>> {
        let bytes = try await httpTransport.execute(
            endpoint: endpoint ?? defaultEndpoint,
            input: input
        )
        return EventStream(bytes: bytes, decoder: decoder)
    }

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

    public func run(input: RunAgentInput) -> AsyncThrowingStream<any AGUIEvent, Error> {
        abstractAgent.run(input: input)
    }

    public func runAgent(
        parameters: RunAgentParameters? = nil,
        subscriber: (any AgentSubscriber)? = nil
    ) async throws {
        try await abstractAgent.runAgent(parameters: parameters, subscriber: subscriber)
    }

    public func runAgentObservable(
        input: RunAgentInput
    ) -> AsyncThrowingStream<any AGUIEvent, Error> {
        abstractAgent.runAgentObservable(input: input)
    }

    public var messages: [any Message] { get async { await abstractAgent.messages } }
    public var state: State { get async { await abstractAgent.state } }
    public var rawEvents: [RawEvent] { get async { await abstractAgent.rawEvents } }
    public var customEvents: [CustomEvent] { get async { await abstractAgent.customEvents } }
    public var thinking: ThinkingTelemetryState? { get async { await abstractAgent.thinking } }

    public func abortRun() async {
        await abstractAgent.abortRun()
    }

    public func dispose() async {
        await abstractAgent.dispose()
    }

    public func subscribe(_ subscriber: any AgentSubscriber) async -> any AgentSubscription {
        await abstractAgent.subscribe(subscriber)
    }
}
