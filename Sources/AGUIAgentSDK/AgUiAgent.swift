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

import AGUIClient
import AGUICore
import AGUITools
import Foundation

public final class AgUiAgent: Sendable {

    // MARK: - Public properties

    public let config: AgUiAgentConfig

    // MARK: - Private state

    private let transport: any AgentTransport
    private let httpAgent: HttpAgent
    private let toolExecutionManager: ToolExecutionManager?

    // MARK: - Initialization

    public init(
        url: URL,
        configure: (inout AgUiAgentConfig) -> Void = { _ in }
    ) {
        var cfg = AgUiAgentConfig()
        configure(&cfg)
        self.config = cfg

        var httpConfig = HttpAgentConfiguration(baseURL: url)
        httpConfig.timeout = cfg.requestTimeout
        httpConfig.headers = cfg.buildHeaders()

        let agent = HttpAgent(configuration: httpConfig)
        self.httpAgent = agent
        self.transport = HttpAgentTransport(configuration: httpConfig)

        if let registry = cfg.toolRegistry {
            self.toolExecutionManager = ToolExecutionManager(
                toolRegistry: registry,
                responseHandler: ClientToolResponseHandler(httpAgent: agent)
            )
        } else {
            self.toolExecutionManager = nil
        }
    }

    public init(
        transport: any AgentTransport,
        config: AgUiAgentConfig = AgUiAgentConfig(),
        toolExecutionManager: ToolExecutionManager? = nil
    ) {
        self.config = config
        self.transport = transport
        let url = URL(string: "https://placeholder.local")!
        self.httpAgent = HttpAgent(baseURL: url)
        self.toolExecutionManager = toolExecutionManager
    }

    // MARK: - Core run method

    public func run(input: RunAgentInput) -> AsyncThrowingStream<any AGUIEvent, Error> {
        transport.run(input: input)
    }

    // MARK: - sendMessage (primary API)

    public func sendMessage(
        _ message: String,
        threadId: String = UUID().uuidString,
        state: State? = nil,
        includeSystemPrompt: Bool = true
    ) -> AsyncThrowingStream<any AGUIEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var messages: [any Message] = []

                    if includeSystemPrompt, let prompt = self.config.systemPrompt {
                        messages.append(SystemMessage(
                            id: "sys_\(UUID().uuidString)",
                            content: prompt
                        ))
                    }

                    messages.append(UserMessage(
                        id: "usr_\(UUID().uuidString)",
                        content: message
                    ))

                    var tools: [Tool] = []
                    if let registry = self.config.toolRegistry {
                        tools = await registry.allTools()
                    }

                    let input = RunAgentInput(
                        threadId: threadId,
                        runId: "run_\(UUID().uuidString)",
                        state: state ?? Data("{}".utf8),
                        messages: messages,
                        tools: tools,
                        context: self.config.context,
                        forwardedProps: self.config.forwardedProps
                    )

                    let rawStream = self.run(input: input)

                    if let manager = self.toolExecutionManager {
                        let managed = await manager.processEventStream(
                            rawStream,
                            threadId: input.threadId,
                            runId: input.runId
                        )
                        for try await event in managed {
                            continuation.yield(event)
                        }
                    } else {
                        for try await event in rawStream {
                            continuation.yield(event)
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Subscriber

    public func subscribe(_ subscriber: any AgentSubscriber) async -> any AgentSubscription {
        await httpAgent.subscribe(subscriber)
    }

    // MARK: - Lifecycle

    public func close() {
        Task {
            if let manager = self.toolExecutionManager {
                await manager.cancelAllExecutions()
            }
        }
        httpAgent.dispose()
    }
}
