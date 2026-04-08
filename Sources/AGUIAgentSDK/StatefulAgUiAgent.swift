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
import Foundation

/// Stateful AG-UI agent that automatically manages conversation history.
///
/// `StatefulAgUiAgent` provides a high-level, iOS-friendly API for building
/// conversational AI interfaces. It automatically tracks message history per thread,
/// manages state updates, and provides convenient methods for common patterns.
///
/// ## Basic Usage
///
/// ```swift
/// let agent = StatefulAgUiAgent(baseURL: URL(string: "https://agent.example.com")!)
///
/// let stream = try await agent.chat(message: "Hello!")
/// for try await event in stream {
///     if let content = event as? TextMessageContentEvent {
///         print(content.delta, terminator: "")
///     }
/// }
/// ```
///
/// ## Advanced Configuration
///
/// ```swift
/// var config = StatefulAgUiAgentConfig(baseURL: agentURL)
/// config.systemPrompt = "You are a helpful AI assistant."
/// config.maxHistoryLength = 50
/// config.timeout = .seconds(60)
///
/// let agent = StatefulAgUiAgent(configuration: config)
///
/// // Multi-turn conversation
/// _ = try await agent.chat(message: "What's the weather?")
/// _ = try await agent.chat(message: "And tomorrow?") // Maintains context
/// ```
///
/// ## Thread Management
///
/// Each conversation can have its own thread with independent history:
///
/// ```swift
/// // Conversation 1
/// let stream1 = try await agent.chat(message: "Hello", threadId: "user-123")
///
/// // Conversation 2 (separate history)
/// let stream2 = try await agent.chat(message: "Hi", threadId: "user-456")
/// ```
///
/// ## Features
///
/// - **Automatic History**: User and assistant messages are tracked automatically
/// - **System Prompts**: Configurable system message for agent behavior
/// - **History Trimming**: Keeps conversations within token limits
/// - **State Management**: Tracks and updates agent state from events
/// - **Thread Safety**: Actor-based concurrency for safe multi-threaded use
///
/// - SeeAlso: ``StatefulAgUiAgentConfig``, ``ConversationHistoryManager``
public final class StatefulAgUiAgent: Sendable {
    /// The underlying HTTP agent for communication.
    private let httpAgent: HttpAgent

    /// Manager for conversation histories across threads.
    private let historyManager: ConversationHistoryManager

    /// Configuration for this agent.
    private let config: StatefulAgUiAgentConfig

    /// Actor for managing current state (thread-safe).
    private let stateManager: StateManager

    /// Creates a new stateful agent with a base URL.
    ///
    /// - Parameter baseURL: The base URL of the AG-UI agent server
    ///
    /// ## Example
    ///
    /// ```swift
    /// let agent = StatefulAgUiAgent(baseURL: URL(string: "https://agent.example.com")!)
    /// ```
    public init(baseURL: URL) {
        var config = StatefulAgUiAgentConfig(baseURL: baseURL)
        self.config = config
        self.httpAgent = HttpAgent(configuration: HttpAgentConfiguration(
            baseURL: config.baseURL,
            timeout: config.timeout,
            headers: config.headers
        ))
        self.historyManager = ConversationHistoryManager()
        self.stateManager = StateManager(initialState: config.initialState)
    }

    /// Creates a new stateful agent with custom configuration.
    ///
    /// - Parameter configuration: The stateful agent configuration
    ///
    /// ## Example
    ///
    /// ```swift
    /// var config = StatefulAgUiAgentConfig(baseURL: agentURL)
    /// config.systemPrompt = "You are helpful"
    /// config.maxHistoryLength = 100
    ///
    /// let agent = StatefulAgUiAgent(configuration: config)
    /// ```
    public init(configuration: StatefulAgUiAgentConfig) {
        self.config = configuration
        self.httpAgent = HttpAgent(configuration: HttpAgentConfiguration(
            baseURL: configuration.baseURL,
            timeout: configuration.timeout,
            headers: configuration.headers
        ))
        self.historyManager = ConversationHistoryManager()
        self.stateManager = StateManager(initialState: configuration.initialState)
    }

    /// Sends a chat message with automatic history management.
    ///
    /// This is a convenience method that delegates to ``sendMessage(message:threadId:state:includeSystemPrompt:)``
    /// with sensible defaults for casual chat interactions.
    ///
    /// - Parameters:
    ///   - message: The user's message text
    ///   - threadId: The conversation thread ID (default: "default")
    /// - Returns: Event stream from the agent
    /// - Throws: `ClientError` if the request fails
    ///
    /// ## Example
    ///
    /// ```swift
    /// let stream = try await agent.chat(message: "Hello!")
    /// for try await event in stream {
    ///     // Process events
    /// }
    /// ```
    public func chat(
        message: String,
        threadId: String = "default"
    ) async throws -> AsyncThrowingStream<any AGUIEvent, Error> {
        let currentState = await stateManager.currentState()
        return try await sendMessage(
            message: message,
            threadId: threadId,
            state: currentState,
            includeSystemPrompt: true
        )
    }

    /// Sends a message with full control over state and system prompt.
    ///
    /// This method provides complete control over the message sending process,
    /// including custom state and system prompt inclusion.
    ///
    /// - Parameters:
    ///   - message: The user's message text
    ///   - threadId: The conversation thread ID
    ///   - state: Custom state to send (defaults to current state)
    ///   - includeSystemPrompt: Whether to add system prompt for new threads (default: true)
    /// - Returns: Event stream from the agent
    /// - Throws: `ClientError` if the request fails
    ///
    /// ## Example
    ///
    /// ```swift
    /// let customState = Data("{\"mode\":\"creative\"}".utf8)
    /// let stream = try await agent.sendMessage(
    ///     message: "Tell me a story",
    ///     threadId: "story-session",
    ///     state: customState,
    ///     includeSystemPrompt: true
    /// )
    /// ```
    public func sendMessage(
        message: String,
        threadId: String,
        state: State?,
        includeSystemPrompt: Bool
    ) async throws -> AsyncThrowingStream<any AGUIEvent, Error> {
        // Get conversation history for this thread
        var history = await historyManager.history(for: threadId)

        // Add system prompt if it's the first message and includeSystemPrompt is true
        if history.isEmpty && includeSystemPrompt, let systemPrompt = config.systemPrompt {
            let systemMessage = SystemMessage(
                id: "sys_\(UUID().uuidString)",
                content: systemPrompt
            )
            await historyManager.append(message: systemMessage, to: threadId)
            history.append(systemMessage)
        }

        // Create and add the user message
        let userMessage = UserMessage(
            id: "usr_\(UUID().uuidString)",
            content: message
        )
        await historyManager.append(message: userMessage, to: threadId)
        history.append(userMessage)

        // Apply history length limit if configured
        if config.maxHistoryLength > 0 {
            await historyManager.trim(threadId: threadId, maxLength: config.maxHistoryLength)
            history = await historyManager.history(for: threadId)
        }

        // Use the provided state or the current state
        let stateToUse: State
        if let providedState = state {
            stateToUse = providedState
        } else {
            stateToUse = await stateManager.currentState()
        }

        // Build the run input
        let input = try RunAgentInput.builder()
            .threadId(threadId)
            .runId("run_\(UUID().uuidString)")
            .messages(history)
            .state(stateToUse)
            .build()

        // Execute the run and track assistant responses
        let stream = try await httpAgent.run(input)

        // Wrap the stream to track history and state updates
        return trackHistoryAndState(stream: stream, threadId: threadId)
    }

    /// Retrieves the conversation history for a thread.
    ///
    /// - Parameter threadId: The thread ID (default: "default")
    /// - Returns: Array of messages in chronological order
    ///
    /// ## Example
    ///
    /// ```swift
    /// let history = await agent.history(for: "chat-session")
    /// print("Conversation has \(history.count) messages")
    /// ```
    public func history(for threadId: String = "default") async -> [any Message] {
        await historyManager.history(for: threadId)
    }

    /// Clears conversation history for one or all threads.
    ///
    /// - Parameter threadId: The thread ID to clear, or `nil` to clear all threads
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Clear specific thread
    /// await agent.clearHistory(threadId: "chat-1")
    ///
    /// // Clear all threads
    /// await agent.clearHistory()
    /// ```
    public func clearHistory(threadId: String? = nil) async {
        await historyManager.clear(threadId: threadId)
    }

    // MARK: - Private Helpers

    /// Wraps an event stream to track assistant messages and state updates.
    private func trackHistoryAndState(
        stream: EventStream<URLSession.AsyncBytes>,
        threadId: String
    ) -> AsyncThrowingStream<any AGUIEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                var currentAssistantMessage: AssistantMessage?

                do {
                    for try await event in stream {
                        // Yield the event downstream
                        continuation.yield(event)

                        // Track assistant messages and state
                        switch event {
                        case let start as TextMessageStartEvent:
                            // Start collecting assistant message
                            currentAssistantMessage = AssistantMessage(
                                id: start.messageId,
                                content: "",
                                toolCalls: nil
                            )

                        case let content as TextMessageContentEvent:
                            // Update the current assistant message content
                            if var msg = currentAssistantMessage, msg.id == content.messageId {
                                let updatedContent = (msg.content ?? "") + content.delta
                                msg = AssistantMessage(
                                    id: msg.id,
                                    content: updatedContent,
                                    name: msg.name,
                                    toolCalls: msg.toolCalls
                                )
                                currentAssistantMessage = msg
                            }

                        case let end as TextMessageEndEvent:
                            // Finalize and save the assistant message
                            if let msg = currentAssistantMessage, msg.id == end.messageId {
                                await self.historyManager.append(message: msg, to: threadId)
                                currentAssistantMessage = nil
                            }

                        case let snapshot as StateSnapshotEvent:
                            // Update current state
                            await self.stateManager.updateState(snapshot.snapshot)

                        default:
                            break
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// MARK: - StateManager

/// Thread-safe actor for managing agent state.
private actor StateManager {
    private var currentStateValue: State

    init(initialState: State) {
        self.currentStateValue = initialState
    }

    func currentState() -> State {
        currentStateValue
    }

    func updateState(_ newState: State) {
        currentStateValue = newState
    }
}
