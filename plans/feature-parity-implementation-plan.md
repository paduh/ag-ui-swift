# AGUISwift Feature Parity Implementation Plan

## Executive Summary

This plan implements 4 critical missing features to bring AGUISwift to feature parity with AGUIKotlin. Total estimated effort: **3-4 weeks** for a senior Swift engineer using TDD (Test-Driven Development).

**Missing Features (verified from source code analysis):**
1. **AGUITools Module** (~800 LOC) - Complete tool execution framework
2. **Chunk Transformation** (~250 LOC) - Automatic chunk aggregation
3. **AgentSubscriber** (~140 LOC) - Lifecycle hooks
4. **StatefulAgUiAgent** (~200 LOC) - Conversation history management

**Reference:** Kotlin SDK cloned at `/tmp/claude/ag-ui-kotlin/sdks/community/kotlin/library/`

---

## Implementation Strategy

### Dependency Order (Sequential)

```
Phase 1: AGUITools (7 days)
    ↓
Phase 2: ChunkTransformation (2 days)
    ↓
Phase 3: AgentSubscriber (3 days)
    ↓
Phase 4: StatefulAgUiAgent (4 days)
```

**Why this order?**
- AGUITools is foundational and largest (7 days)
- ChunkTransformation is independent and needed for message assembly
- AgentSubscriber depends on proper event handling
- StatefulAgUiAgent depends on all previous features

---

## PHASE 1: AGUITools Module (Week 1: 7 days)

### Overview
Implement complete tool execution framework matching Kotlin's `tools/` module.

### 1.1 Core Protocols & Types (Day 1-2)

**TDD Red - Write Failing Tests:**
- `Tests/AGUIToolsTests/Core/ToolExecutorTests.swift`
- `Tests/AGUIToolsTests/Core/ToolExecutionResultTests.swift`
- `Tests/AGUIToolsTests/Core/ToolExecutionContextTests.swift`

**TDD Green - Implement:**

Create `Sources/AGUITools/Core/ToolExecutor.swift`:
```swift
/// Protocol for executing tools with validation and timeout support
public protocol ToolExecutor: Sendable {
    var tool: Tool { get }
    func execute(context: ToolExecutionContext) async throws -> ToolExecutionResult
    func validate(toolCall: ToolCall) -> ToolValidationResult
    func maximumExecutionTime() -> Duration?
}
```

Create `Sources/AGUITools/Core/ToolExecutionResult.swift`:
```swift
/// Result of tool execution with success status and optional data
public struct ToolExecutionResult: Sendable, Equatable {
    public let success: Bool
    public let result: Data?  // JSON data
    public let message: String?
}
```

Create `Sources/AGUITools/Core/ToolExecutionContext.swift`:
```swift
/// Context provided to tool executors
public struct ToolExecutionContext: Sendable {
    public let toolCall: ToolCall
    public let threadId: String?
    public let runId: String?
    public let metadata: [String: String]
}
```

**Reference:** `/tmp/claude/ag-ui-kotlin/sdks/community/kotlin/library/tools/src/commonMain/kotlin/com/agui/tools/ToolExecutor.kt`

**Architectural Decisions:**
- Use `Duration` instead of milliseconds (Swift native)
- Use `Data` for JSON results (consistent with existing `Tool.parameters`)
- All types are `Sendable` structs (value semantics)

### 1.2 ToolRegistry Implementation (Day 3-4)

**TDD Red - Write Failing Tests:**
- `Tests/AGUIToolsTests/Registry/ToolRegistryTests.swift`
- `Tests/AGUIToolsTests/Registry/ToolExecutionStatsTests.swift`
- `Tests/AGUIToolsTests/Registry/ToolRegistryConcurrencyTests.swift`

**TDD Green - Implement:**

Create `Sources/AGUITools/Registry/ToolRegistry.swift`:
```swift
/// Protocol for managing tool executors
public protocol ToolRegistry: Sendable {
    func register(executor: any ToolExecutor) async throws
    func unregister(toolName: String) async -> Bool
    func executor(for toolName: String) async -> (any ToolExecutor)?
    func allTools() async -> [Tool]
    func execute(context: ToolExecutionContext) async throws -> ToolExecutionResult
    func stats(for toolName: String) async -> ToolExecutionStats?
    func clearStats() async
}
```

Create `Sources/AGUITools/Registry/DefaultToolRegistry.swift`:
```swift
/// Thread-safe tool registry using actor isolation
public actor DefaultToolRegistry: ToolRegistry {
    private var executors: [String: any ToolExecutor] = [:]
    private var stats: [String: MutableToolExecutionStats] = [:]

    public init() {}

    public func register(executor: any ToolExecutor) async throws {
        let toolName = executor.tool.name
        guard !toolName.isEmpty else {
            throw ToolRegistryError.emptyToolName
        }
        executors[toolName] = executor
        stats[toolName] = MutableToolExecutionStats()
    }

    public func execute(context: ToolExecutionContext) async throws -> ToolExecutionResult {
        let toolName = context.toolCall.function.name
        guard let executor = executors[toolName] else {
            throw ToolRegistryError.toolNotFound(toolName)
        }

        let startTime = ContinuousClock.now
        let result: ToolExecutionResult

        do {
            if let maxTime = executor.maximumExecutionTime() {
                result = try await withTimeout(maxTime) {
                    try await executor.execute(context: context)
                }
            } else {
                result = try await executor.execute(context: context)
            }
        } catch {
            // Update failure stats
            stats[toolName]?.recordFailure(duration: startTime.duration(to: .now))
            throw error
        }

        // Update success stats
        stats[toolName]?.recordSuccess(duration: startTime.duration(to: .now))
        return result
    }
}
```

**Reference:** `/tmp/claude/ag-ui-kotlin/sdks/community/kotlin/library/tools/src/commonMain/kotlin/com/agui/tools/ToolRegistry.kt`

**Architectural Decisions:**
- Actor for automatic thread safety (vs Kotlin's Mutex)
- Type-erased `any ToolExecutor` for heterogeneous storage
- `Duration` for timing (use `ContinuousClock`)

### 1.3 Error Handling & Circuit Breaker (Day 5-6)

**TDD Red - Write Failing Tests:**
- `Tests/AGUIToolsTests/ErrorHandling/ToolErrorHandlerTests.swift`
- `Tests/AGUIToolsTests/ErrorHandling/CircuitBreakerTests.swift`
- `Tests/AGUIToolsTests/ErrorHandling/RetryStrategyTests.swift`

**TDD Green - Implement:**

Create `Sources/AGUITools/ErrorHandling/CircuitBreaker.swift`:
```swift
/// Circuit breaker for preventing cascading failures
public actor CircuitBreaker {
    private var state: CircuitBreakerState
    private var failures: Int = 0
    private var successes: Int = 0
    private var lastFailureTime: ContinuousClock.Instant?
    private let config: CircuitBreakerConfig

    public init(config: CircuitBreakerConfig = .init()) {
        self.config = config
        self.state = .closed
    }

    public func isOpen() -> Bool {
        switch state {
        case .open:
            // Check if recovery timeout expired
            if let lastFailure = lastFailureTime,
               lastFailure.duration(to: .now) > config.recoveryTimeout {
                state = .halfOpen
                return false
            }
            return true
        case .halfOpen, .closed:
            return false
        }
    }

    public func recordFailure() {
        failures += 1
        lastFailureTime = .now

        switch state {
        case .closed where failures >= config.failureThreshold:
            state = .open
        case .halfOpen:
            state = .open
        default:
            break
        }
    }

    public func recordSuccess() {
        switch state {
        case .closed:
            failures = 0
        case .halfOpen:
            successes += 1
            if successes >= config.successThreshold {
                state = .closed
                failures = 0
                successes = 0
            }
        case .open:
            state = .closed
            failures = 0
            successes = 0
        }
    }
}

public enum CircuitBreakerState: Sendable {
    case closed, open, halfOpen
}

public struct CircuitBreakerConfig: Sendable {
    public var failureThreshold: Int = 5
    public var recoveryTimeout: Duration = .seconds(60)
    public var successThreshold: Int = 2
}
```

Create `Sources/AGUITools/ErrorHandling/ToolErrorHandler.swift`:
```swift
/// Handles tool execution errors with retry strategies
public actor ToolErrorHandler {
    private var executionHistory: [String: [ToolExecutionAttempt]] = [:]
    private var circuitBreakers: [String: CircuitBreaker] = [:]
    private let config: ToolErrorConfig

    public init(config: ToolErrorConfig = .init()) {
        self.config = config
    }

    public func handleError(
        error: Error,
        context: ToolExecutionContext,
        attempt: Int
    ) async -> ToolErrorDecision {
        let toolName = context.toolCall.function.name

        // Check circuit breaker
        let circuitBreaker = circuitBreakers[toolName] ?? CircuitBreaker(config: config.circuitBreakerConfig)
        circuitBreakers[toolName] = circuitBreaker

        if await circuitBreaker.isOpen() {
            return .fail(
                message: "Tool '\(toolName)' temporarily unavailable",
                shouldReport: false
            )
        }

        // Determine retry eligibility
        if shouldRetry(error: error, attempt: attempt) {
            let delay = calculateRetryDelay(attempt: attempt)
            return .retry(delay: delay, maxAttempts: config.maxRetryAttempts)
        } else {
            await circuitBreaker.recordFailure()
            let category = categorize(error: error)
            return .fail(
                message: generateUserMessage(error: error, category: category, toolName: toolName),
                shouldReport: category.shouldReport
            )
        }
    }

    private func shouldRetry(error: Error, attempt: Int) -> Bool {
        guard attempt < config.maxRetryAttempts else { return false }

        switch error {
        case is ToolNotFoundException, is ToolValidationException:
            return false
        case is ToolTimeoutException, is ToolNetworkException:
            return true
        case is ToolResourceException:
            return config.retryOnResourceErrors
        default:
            return config.retryOnUnknownErrors
        }
    }

    private func calculateRetryDelay(attempt: Int) -> Duration {
        switch config.retryStrategy {
        case .fixed:
            return config.baseRetryDelay
        case .linear:
            return config.baseRetryDelay * attempt
        case .exponential:
            let delay = config.baseRetryDelay * (1 << (attempt - 1))
            return min(delay, config.maxRetryDelay)
        case .exponentialJitter:
            let delay = config.baseRetryDelay * (1 << (attempt - 1))
            let jitter = Double.random(in: 0...0.1) * Double(delay.components.seconds)
            return min(delay + .seconds(jitter), config.maxRetryDelay)
        }
    }
}

public enum RetryStrategy: Sendable {
    case fixed, linear, exponential, exponentialJitter
}

public enum ToolErrorDecision {
    case retry(delay: Duration, maxAttempts: Int)
    case fail(message: String, shouldReport: Bool)
}
```

**Reference:** `/tmp/claude/ag-ui-kotlin/sdks/community/kotlin/library/tools/src/commonMain/kotlin/com/agui/tools/ToolErrorHandling.kt`

**Architectural Decisions:**
- Actor-based for thread safety
- `Duration` for all time values (not milliseconds)
- Swift native error types (not exceptions)

### 1.4 Integration & Testing (Day 7)

**Create Mock Implementations:**

`Tests/AGUIToolsTests/Mocks/MockToolExecutor.swift`:
```swift
public actor MockToolExecutor: ToolExecutor {
    public let tool: Tool
    public var executeCallCount: Int = 0
    public var resultToReturn: ToolExecutionResult?
    public var errorToThrow: Error?

    public init(tool: Tool) {
        self.tool = tool
    }

    public func execute(context: ToolExecutionContext) async throws -> ToolExecutionResult {
        executeCallCount += 1
        if let error = errorToThrow {
            throw error
        }
        return resultToReturn ?? ToolExecutionResult(success: true, result: nil, message: nil)
    }

    public func validate(toolCall: ToolCall) -> ToolValidationResult {
        .valid
    }

    public func maximumExecutionTime() -> Duration? {
        nil
    }
}
```

**Integration Tests:**
- End-to-end tool registration → execution → statistics
- Circuit breaker state transitions
- Retry strategy verification
- Concurrent tool execution

**Validation Checklist:**
- [ ] `swift test` passes (all tests green)
- [ ] `swift build` succeeds
- [ ] `swiftformat` applied
- [ ] `swiftlint` passes
- [ ] All public types are `Sendable`
- [ ] Documentation complete

---

## PHASE 2: Chunk Transformation (Week 1-2: 2 days)

### Overview
Transform TEXT_MESSAGE_CHUNK and TOOL_CALL_CHUNK events into structured start/content/end sequences.

### 2.1 Core Transformer (Day 1)

**TDD Red - Write Failing Tests:**
- `Tests/AGUIClientTests/Streaming/ChunkTransformTests.swift`
- `Tests/AGUIClientTests/Streaming/ChunkRolePreservationTests.swift`

**TDD Green - Implement:**

Create `Sources/AGUIClient/Streaming/ChunkTransformer.swift`:
```swift
/// Transforms chunk events into structured sequences
public struct ChunkTransformer {
    private enum ChunkMode {
        case text, tool
    }

    private struct TextState {
        let messageId: String
        var fromChunk: Bool
    }

    private struct ToolState {
        let toolCallId: String
        var fromChunk: Bool
    }

    /// Transform a stream of events, converting chunks to start/content/end sequences
    public func transform<S: AsyncSequence>(
        _ events: S
    ) -> AsyncThrowingStream<any AGUIEvent, Error> where S.Element == any AGUIEvent {
        AsyncThrowingStream { continuation in
            Task {
                var mode: ChunkMode?
                var textState: TextState?
                var toolState: ToolState?

                func closeText(_ event: any AGUIEvent) {
                    if let state = textState, state.fromChunk {
                        continuation.yield(TextMessageEndEvent(
                            messageId: state.messageId,
                            timestamp: event.timestamp,
                            rawEvent: event.rawEvent
                        ))
                    }
                    textState = nil
                    if mode == .text { mode = nil }
                }

                func closeTool(_ event: any AGUIEvent) {
                    if let state = toolState, state.fromChunk {
                        continuation.yield(ToolCallEndEvent(
                            toolCallId: state.toolCallId,
                            timestamp: event.timestamp,
                            rawEvent: event.rawEvent
                        ))
                    }
                    toolState = nil
                    if mode == .tool { mode = nil }
                }

                do {
                    for try await event in events {
                        switch event {
                        case let chunk as TextMessageChunkEvent:
                            let messageId = chunk.messageId

                            if mode != .text || (messageId != nil && messageId != textState?.messageId) {
                                closeText(event)
                                closeTool(event)

                                guard let id = messageId else {
                                    throw ChunkTransformError.missingMessageId
                                }

                                continuation.yield(TextMessageStartEvent(
                                    messageId: id,
                                    role: chunk.role ?? .assistant,
                                    timestamp: chunk.timestamp,
                                    rawEvent: chunk.rawEvent
                                ))

                                mode = .text
                                textState = TextState(messageId: id, fromChunk: true)
                            }

                            if let delta = chunk.delta, !delta.isEmpty {
                                continuation.yield(TextMessageContentEvent(
                                    messageId: textState!.messageId,
                                    delta: delta,
                                    timestamp: chunk.timestamp,
                                    rawEvent: chunk.rawEvent
                                ))
                            }

                        case let chunk as ToolCallChunkEvent:
                            let toolId = chunk.toolCallId
                            let toolName = chunk.toolCallName

                            if mode != .tool || (toolId != nil && toolId != toolState?.toolCallId) {
                                closeText(event)
                                closeTool(event)

                                guard let id = toolId, let name = toolName else {
                                    throw ChunkTransformError.missingToolCallInfo
                                }

                                continuation.yield(ToolCallStartEvent(
                                    toolCallId: id,
                                    toolCallName: name,
                                    parentMessageId: chunk.parentMessageId,
                                    timestamp: chunk.timestamp,
                                    rawEvent: chunk.rawEvent
                                ))

                                mode = .tool
                                toolState = ToolState(toolCallId: id, fromChunk: true)
                            }

                            if let delta = chunk.delta, !delta.isEmpty {
                                continuation.yield(ToolCallArgsEvent(
                                    toolCallId: toolState!.toolCallId,
                                    delta: delta,
                                    timestamp: chunk.timestamp,
                                    rawEvent: chunk.rawEvent
                                ))
                            }

                        case is TextMessageStartEvent, is TextMessageContentEvent, is TextMessageEndEvent,
                             is ToolCallStartEvent, is ToolCallArgsEvent, is ToolCallEndEvent:
                            closeText(event)
                            closeTool(event)
                            continuation.yield(event)

                        default:
                            closeText(event)
                            closeTool(event)
                            continuation.yield(event)
                        }
                    }

                    // Close any pending state
                    if textState != nil || toolState != nil {
                        let finalEvent = RunFinishedEvent(threadId: "", runId: "", timestamp: nil, rawEvent: nil)
                        closeText(finalEvent)
                        closeTool(finalEvent)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

public enum ChunkTransformError: Error {
    case missingMessageId
    case missingToolCallInfo
}
```

**Extension on EventStream:**
```swift
extension EventStream {
    /// Apply chunk transformation to the event stream
    public func transformChunks() -> AsyncThrowingStream<any AGUIEvent, Error> {
        ChunkTransformer().transform(self)
    }
}
```

**Reference:** `/tmp/claude/ag-ui-kotlin/sdks/community/kotlin/library/client/src/commonMain/kotlin/com/agui/client/chunks/ChunkTransform.kt`

### 2.2 Testing & Edge Cases (Day 2)

**Test Coverage:**
- Interleaved TEXT/TOOL chunks
- Missing messageId/toolCallId handling
- Empty delta handling
- Stream completion with pending state
- Role preservation across chunks

**Validation Checklist:**
- [ ] All chunk transformation tests pass
- [ ] Edge cases handled (interleaved, missing IDs)
- [ ] Documentation complete
- [ ] Integration with EventStream verified

---

## PHASE 3: AgentSubscriber Lifecycle Hooks (Week 2: 3 days)

### Overview
Implement lifecycle hooks for observing and mutating agent runs.

### 3.1 Subscriber Protocol & Types (Day 1-2)

**TDD Red - Write Failing Tests:**
- `Tests/AGUIClientTests/Subscriber/AgentSubscriberTests.swift`
- `Tests/AGUIClientTests/Subscriber/AgentStateMutationTests.swift`
- `Tests/AGUIClientTests/Subscriber/SubscriberChainTests.swift`

**TDD Green - Implement:**

Create `Sources/AGUIClient/Subscriber/AgentSubscriber.swift`:
```swift
/// Observes and optionally mutates agent lifecycle events
public protocol AgentSubscriber: Sendable {
    /// Called when a run is initialized
    func onRunInitialized(params: AgentSubscriberParams) async -> AgentStateMutation?

    /// Called when a run fails with error
    func onRunFailed(params: AgentRunFailureParams) async -> AgentStateMutation?

    /// Called when a run completes successfully
    func onRunFinalized(params: AgentSubscriberParams) async -> AgentStateMutation?

    /// Called for each event in the stream
    func onEvent(params: AgentEventParams) async -> AgentStateMutation?

    /// Called when messages change
    func onMessagesChanged(params: AgentStateChangedParams) async

    /// Called when state changes
    func onStateChanged(params: AgentStateChangedParams) async
}

/// Default implementations (all hooks are optional)
extension AgentSubscriber {
    public func onRunInitialized(params: AgentSubscriberParams) async -> AgentStateMutation? { nil }
    public func onRunFailed(params: AgentRunFailureParams) async -> AgentStateMutation? { nil }
    public func onRunFinalized(params: AgentSubscriberParams) async -> AgentStateMutation? { nil }
    public func onEvent(params: AgentEventParams) async -> AgentStateMutation? { nil }
    public func onMessagesChanged(params: AgentStateChangedParams) async {}
    public func onStateChanged(params: AgentStateChangedParams) async {}
}
```

Create `Sources/AGUIClient/Subscriber/AgentStateMutation.swift`:
```swift
/// Mutation that subscribers can apply to agent state
public struct AgentStateMutation: Sendable {
    public let messages: [any Message]?
    public let state: State?
    public let stopPropagation: Bool

    public init(
        messages: [any Message]? = nil,
        state: State? = nil,
        stopPropagation: Bool = false
    ) {
        self.messages = messages
        self.state = state
        self.stopPropagation = stopPropagation
    }
}

/// Parameters shared across subscriber callbacks
public struct AgentSubscriberParams: Sendable {
    public let messages: [any Message]
    public let state: State
    public let input: RunAgentInput
}

public struct AgentEventParams: Sendable {
    public let event: any AGUIEvent
    public let messages: [any Message]
    public let state: State
    public let input: RunAgentInput
}

public struct AgentRunFailureParams: Sendable {
    public let error: Error
    public let messages: [any Message]
    public let state: State
    public let input: RunAgentInput
}

public struct AgentStateChangedParams: Sendable {
    public let messages: [any Message]
    public let state: State
    public let input: RunAgentInput
}
```

Create `Sources/AGUIClient/Subscriber/AgentSubscription.swift`:
```swift
/// Handle for managing subscriber lifecycle
public protocol AgentSubscription: Sendable {
    func unsubscribe() async
}

/// Default implementation
actor DefaultAgentSubscription: AgentSubscription {
    private var isActive: Bool = true
    private let onUnsubscribe: @Sendable () async -> Void

    init(onUnsubscribe: @escaping @Sendable () async -> Void) {
        self.onUnsubscribe = onUnsubscribe
    }

    func unsubscribe() async {
        guard isActive else { return }
        isActive = false
        await onUnsubscribe()
    }
}
```

**Reference:** `/tmp/claude/ag-ui-kotlin/sdks/community/kotlin/library/client/src/commonMain/kotlin/com/agui/client/agent/AgentSubscriber.kt`

### 3.2 Integration with HttpAgent (Day 3)

**TDD Red - Write Failing Tests:**
- `Tests/AGUIClientTests/HttpAgentSubscriberTests.swift`
- `Tests/AGUIClientTests/SubscriberMutationTests.swift`

**TDD Green - Implement:**

Extend `Sources/AGUIClient/HttpAgent.swift`:
```swift
// Add to HttpAgent
private actor SubscriberManager {
    private var subscribers: [UUID: any AgentSubscriber] = [:]

    func subscribe(_ subscriber: any AgentSubscriber) -> UUID {
        let id = UUID()
        subscribers[id] = subscriber
        return id
    }

    func unsubscribe(_ id: UUID) {
        subscribers.removeValue(forKey: id)
    }

    func allSubscribers() -> [any AgentSubscriber] {
        Array(subscribers.values)
    }
}

extension HttpAgent {
    public func subscribe(_ subscriber: any AgentSubscriber) -> any AgentSubscription {
        let manager = self.subscriberManager
        let id = await manager.subscribe(subscriber)
        return DefaultAgentSubscription {
            await manager.unsubscribe(id)
        }
    }
}
```

**Validation Checklist:**
- [ ] Subscriber registration works
- [ ] Mutations propagate correctly
- [ ] stopPropagation works
- [ ] Multiple subscribers execute in order
- [ ] Unsubscribe cleans up properly

---

## PHASE 4: StatefulAgUiAgent (Week 2-3: 4 days)

### Overview
High-level API with automatic conversation history management.

### 4.1 Core Stateful Agent (Day 1-2)

**TDD Red - Write Failing Tests:**
- `Tests/AGUIAgentSDKTests/StatefulAgUiAgentTests.swift`
- `Tests/AGUIAgentSDKTests/ConversationHistoryTests.swift`
- `Tests/AGUIAgentSDKTests/HistoryTrimmingTests.swift`

**TDD Green - Implement:**

Create `Sources/AGUIAgentSDK/StatefulAgUiAgent.swift`:
```swift
/// Stateful agent that maintains conversation history
public final class StatefulAgUiAgent: Sendable {
    private let httpAgent: HttpAgent
    private let historyManager: ConversationHistoryManager
    private let config: StatefulAgUiAgentConfig

    public init(
        baseURL: URL,
        configure: (inout StatefulAgUiAgentConfig) -> Void = { _ in }
    ) {
        var config = StatefulAgUiAgentConfig(baseURL: baseURL)
        configure(&config)
        self.config = config

        self.httpAgent = HttpAgent(
            configuration: HttpAgentConfiguration(
                baseURL: baseURL,
                timeout: config.timeout,
                headers: config.headers
            )
        )
        self.historyManager = ConversationHistoryManager()
    }

    /// Convenience method for chat-style interactions
    public func chat(
        message: String,
        threadId: String = "default"
    ) async throws -> AsyncThrowingStream<any AGUIEvent, Error> {
        try await sendMessage(
            message: message,
            threadId: threadId,
            state: config.initialState,
            includeSystemPrompt: true
        )
    }

    /// Send a message with full control
    public func sendMessage(
        message: String,
        threadId: String,
        state: State?,
        includeSystemPrompt: Bool
    ) async throws -> AsyncThrowingStream<any AGUIEvent, Error> {
        // Get or create history
        var history = await historyManager.history(for: threadId)

        // Add system prompt if first message
        if history.isEmpty && includeSystemPrompt, let systemPrompt = config.systemPrompt {
            let systemMessage = SystemMessage(
                id: "sys_\(UUID().uuidString)",
                content: [TextInputContent(text: systemPrompt)]
            )
            history.append(systemMessage)
            await historyManager.append(message: systemMessage, to: threadId)
        }

        // Add user message
        let userMessage = UserMessage(
            id: "user_\(UUID().uuidString)",
            content: [TextInputContent(text: message)]
        )
        history.append(userMessage)
        await historyManager.append(message: userMessage, to: threadId)

        // Trim if needed
        if config.maxHistoryLength > 0 {
            await historyManager.trim(threadId: threadId, maxLength: config.maxHistoryLength)
            history = await historyManager.history(for: threadId)
        }

        // Build input
        let input = try RunAgentInput.builder()
            .threadId(threadId)
            .runId("run_\(UUID().uuidString)")
            .messages(history)
            .state(state ?? config.initialState)
            .build()

        // Execute and track assistant responses
        let stream = try await httpAgent.run(input)

        return AsyncThrowingStream { continuation in
            Task {
                var currentAssistantMessage: AssistantMessage?

                do {
                    for try await event in stream {
                        continuation.yield(event)

                        // Track assistant messages in history
                        switch event {
                        case let start as TextMessageStartEvent:
                            currentAssistantMessage = AssistantMessage(
                                id: start.messageId,
                                content: [],
                                toolCalls: nil
                            )

                        case let content as TextMessageContentEvent:
                            if var msg = currentAssistantMessage, msg.id == content.messageId {
                                let existing = (msg.content?.first as? TextInputContent)?.text ?? ""
                                msg.content = [TextInputContent(text: existing + content.delta)]
                                currentAssistantMessage = msg
                            }

                        case let end as TextMessageEndEvent:
                            if let msg = currentAssistantMessage, msg.id == end.messageId {
                                await historyManager.append(message: msg, to: threadId)
                                currentAssistantMessage = nil
                            }

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

    /// Get conversation history for a thread
    public func history(for threadId: String = "default") async -> [any Message] {
        await historyManager.history(for: threadId)
    }

    /// Clear conversation history
    public func clearHistory(threadId: String? = nil) async {
        await historyManager.clear(threadId: threadId)
    }
}
```

Create `Sources/AGUIAgentSDK/ConversationHistoryManager.swift`:
```swift
/// Manages conversation history per thread
actor ConversationHistoryManager {
    private var threadHistories: [String: [any Message]] = [:]

    func append(message: any Message, to threadId: String) {
        threadHistories[threadId, default: []].append(message)
    }

    func trim(threadId: String, maxLength: Int) {
        guard var history = threadHistories[threadId], history.count > maxLength else {
            return
        }

        // Preserve system message if present
        let hasSystemMessage = history.first is SystemMessage
        if hasSystemMessage && history.count > 1 {
            let systemMessage = history.first!
            let trimmed = Array(history.dropFirst().suffix(maxLength - 1))
            threadHistories[threadId] = [systemMessage] + trimmed
        } else {
            threadHistories[threadId] = Array(history.suffix(maxLength))
        }
    }

    func history(for threadId: String) -> [any Message] {
        threadHistories[threadId] ?? []
    }

    func clear(threadId: String?) {
        if let threadId = threadId {
            threadHistories.removeValue(forKey: threadId)
        } else {
            threadHistories.removeAll()
        }
    }
}
```

**Reference:** `/tmp/claude/ag-ui-kotlin/sdks/community/kotlin/library/client/src/commonMain/kotlin/com/agui/client/StatefulAgUiAgent.kt`

### 4.2 Configuration & Builder (Day 3)

**TDD Red - Write Failing Tests:**
- `Tests/AGUIAgentSDKTests/StatefulAgUiAgentConfigTests.swift`
- `Tests/AGUIAgentSDKTests/StatefulAgentBuilderTests.swift`

**TDD Green - Implement:**

Create `Sources/AGUIAgentSDK/StatefulAgUiAgentConfig.swift`:
```swift
/// Configuration for StatefulAgUiAgent
public struct StatefulAgUiAgentConfig: Sendable {
    public var baseURL: URL
    public var initialState: State
    public var maxHistoryLength: Int
    public var systemPrompt: String?
    public var timeout: Duration
    public var headers: [String: String]

    public init(baseURL: URL) {
        self.baseURL = baseURL
        self.initialState = Data("{}".utf8)
        self.maxHistoryLength = 100
        self.systemPrompt = nil
        self.timeout = .seconds(120)
        self.headers = [:]
    }
}
```

### 4.3 Integration Testing (Day 4)

**End-to-End Tests:**
- Multi-turn conversation
- History trimming in realistic scenarios
- State updates across conversation
- Concurrent multi-thread conversations

**Validation Checklist:**
- [ ] All tests pass
- [ ] Documentation complete
- [ ] Examples added
- [ ] Integration with chunk transformer works
- [ ] Integration with subscribers works (if implemented)

---

## Critical Files Created/Modified

### New Files (17 files):

**AGUITools Module (8 files):**
1. `Sources/AGUITools/Core/ToolExecutor.swift`
2. `Sources/AGUITools/Core/ToolExecutionResult.swift`
3. `Sources/AGUITools/Core/ToolExecutionContext.swift`
4. `Sources/AGUITools/Registry/ToolRegistry.swift`
5. `Sources/AGUITools/Registry/DefaultToolRegistry.swift`
6. `Sources/AGUITools/ErrorHandling/CircuitBreaker.swift`
7. `Sources/AGUITools/ErrorHandling/ToolErrorHandler.swift`
8. `Sources/AGUITools/Errors/ToolErrors.swift`

**AGUIClient Extensions (5 files):**
9. `Sources/AGUIClient/Streaming/ChunkTransformer.swift`
10. `Sources/AGUIClient/Subscriber/AgentSubscriber.swift`
11. `Sources/AGUIClient/Subscriber/AgentStateMutation.swift`
12. `Sources/AGUIClient/Subscriber/AgentSubscription.swift`
13. Modified: `Sources/AGUIClient/HttpAgent.swift` (add subscriber support)

**AGUIAgentSDK (4 files):**
14. `Sources/AGUIAgentSDK/StatefulAgUiAgent.swift`
15. `Sources/AGUIAgentSDK/ConversationHistoryManager.swift`
16. `Sources/AGUIAgentSDK/StatefulAgUiAgentConfig.swift`
17. Modified: `Sources/AGUIAgentSDK/AGUIAgentSDK.swift` (export new types)

---

## Verification & Testing Strategy

### Per-Phase Verification

After each phase, verify:
1. **Build**: `swift build` succeeds without warnings
2. **Tests**: `swift test --parallel` all pass
3. **Format**: `swift package plugin --allow-writing-to-package-directory swiftformat`
4. **Lint**: `swiftlint lint` passes
5. **Concurrency**: All public types are `Sendable`
6. **Documentation**: All public APIs documented

### Final Integration Tests

Create `Tests/IntegrationTests/FeatureParityTests.swift`:
```swift
final class FeatureParityTests: XCTestCase {
    func testEndToEndToolExecution() async throws {
        // Test complete tool flow: register → execute → stats
    }

    func testChunkTransformationInRealStream() async throws {
        // Test chunk transformation with real event stream
    }

    func testSubscriberLifecycle() async throws {
        // Test subscriber hooks throughout agent run
    }

    func testStatefulConversationFlow() async throws {
        // Test multi-turn conversation with history
    }
}
```

---

## Risk Mitigation

### Phase 1 (AGUITools) - Highest Risk
**Risk:** Complex concurrency, circuit breakers, retry logic
**Mitigation:**
- Leverage Swift actors for automatic thread safety
- Extensive unit tests for state machines
- Reference Kotlin implementation closely
- Start with simplest components first

### Phase 2 (Chunk Transform) - Low Risk
**Risk:** Subtle state machine bugs
**Mitigation:**
- Comprehensive state transition tests
- Test interleaved scenarios
- Add debug logging mode

### Phase 3 (AgentSubscriber) - Medium Risk
**Risk:** Integration complexity with HttpAgent
**Mitigation:**
- Protocol-first approach
- Incremental integration
- Test mutation chaining thoroughly

### Phase 4 (StatefulAgent) - Medium Risk
**Risk:** Depends on all previous phases
**Mitigation:**
- Don't start until Phases 1-3 complete
- Use mocks extensively
- Incremental feature addition

---

## Timeline Summary

| Phase | Feature | Days | Risk | Dependencies |
|-------|---------|------|------|--------------|
| 1 | AGUITools | 7 | High | None |
| 2 | ChunkTransform | 2 | Low | None |
| 3 | AgentSubscriber | 3 | Medium | Phase 2 |
| 4 | StatefulAgent | 4 | Medium | Phases 1-3 |
| **Total** | | **16 days** | | |

**Buffer:** +20% = **19-20 days (4 weeks)**

---

## Success Criteria

Upon completion, AGUISwift will have:
- ✅ Complete tool execution framework with circuit breakers
- ✅ Automatic chunk transformation
- ✅ Lifecycle hooks for observability
- ✅ Stateful agent with conversation management
- ✅ Feature parity with AGUIKotlin
- ✅ 100% test coverage for new features
- ✅ All code formatted and linted
- ✅ Comprehensive documentation

---

## Next Steps After Plan Approval

1. **Week 1**: Implement Phase 1 (AGUITools)
2. **Week 1-2**: Implement Phases 2-3 (Chunks + Subscribers)
3. **Week 2-3**: Implement Phase 4 (StatefulAgent)
4. **Week 3-4**: Integration testing, documentation, polish
5. **Release**: Tag v1.0.0 with feature parity achieved
