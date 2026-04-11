# ag-ui-swift: Feature Parity Implementation Plan

> **Goal**: Bring `ag-ui-swift` to full feature parity with `ag-ui/sdks/community/kotlin`.
> **Reference**: All gaps were identified by direct source comparison of both codebases.

---

## Architecture Overview

The plan follows the same layered architecture as Kotlin:

```
AGUICore          ← Protocol types, events, messages  (no changes)
     ↓
AGUIClient        ← Transport, streaming, AbstractAgent, state pipeline
     ↓
AGUITools         ← Tool execution  (ToolResponseHandler interface added)
     ↓
AGUIAgentSDK      ← AgUiAgent, StatefulAgUiAgent, ClientToolResponseHandler bridge
```

**One `Package.swift` change required**: add `AGUITools` to `AGUIAgentSDK`'s dependencies so the SDK layer can bridge tools with the HTTP client.

**Swift design decisions applied throughout:**
- `AbstractAgent` is an `open class: @unchecked Sendable` with an internal `actor` for mutable state — actors cannot be subclassed in Swift, so composition is used
- All new pipeline stages are `AsyncSequence` extensions (parallel to Kotlin's `Flow` extensions), consistent with the existing `transformChunks()` pattern
- `@frozen` enums and `Sendable` structs for all new value types
- TDD: tests are written before implementation for each phase

---

## Gap Summary

| Feature | Kotlin | Swift | Priority |
|---|---|---|---|
| All 26 event types | ✅ | ✅ | — |
| All 7 message types | ✅ | ✅ | — |
| ChunkTransformer | ✅ | ✅ | — |
| StateManager (snapshot + delta) | ✅ | ✅ | — |
| AgentSubscriber (6 hooks) | ✅ | ✅ | — |
| ToolExecutor / DefaultToolRegistry | ✅ | ✅ | — |
| StatefulAgUiAgent (basic chat) | ✅ | ✅ | — |
| **EventVerifier** | ✅ | ❌ | 🔴 Critical |
| **defaultApplyEvents pipeline** | ✅ | ❌ | 🔴 Critical |
| **AbstractAgent (extensible base)** | ✅ | ❌ | 🔴 Critical |
| **AgentState / ThinkingTelemetryState types** | ✅ | ❌ | 🟠 Important |
| **ToolExecutionManager** | ✅ | ❌ | 🟠 Important |
| **ToolResponseHandler + ClientToolResponseHandler** | ✅ | ❌ | 🟠 Important |
| **StateDeltaEvent in StatefulAgUiAgent** | ✅ | ❌ | 🟠 Important |
| **ToolCall events in StatefulAgUiAgent history** | ✅ | ❌ | 🟠 Important |
| **ToolRegistry wired into agents** | ✅ | ❌ | 🟠 Important |
| ToolErrorHandler (circuit breaker, retry) | ✅ | ❌ | 🟡 Moderate |
| dispose() / abortRun() | ✅ | ❌ | 🟡 Moderate |
| AgUiAgent sendMessage() convenience | ✅ | ❌ | 🟡 Moderate |
| Auth helpers (bearerToken, apiKey) | ✅ | ❌ | 🟡 Moderate |
| debug mode | ✅ | ❌ | 🟡 Moderate |
| ToolRegistry.getAllExecutors() | ✅ | ❌ | 🟡 Moderate |

---

## Phase 1 — Foundation Types

**Objective**: Add `AgentState` and `ThinkingTelemetryState` — required by every subsequent phase.

### Files to Create

```
Sources/AGUIClient/State/AgentState.swift
Sources/AGUIClient/State/ThinkingTelemetryState.swift
```

### Implementation

`AgentState` is the output type of the state pipeline. Each emission represents a diff — only fields that changed are non-nil:

```swift
// AgentState.swift
public struct AgentState: Sendable {
    public var messages: [any Message]?
    public var thinking: ThinkingTelemetryState?
    public var state: State?                   // Data (JSON)
    public var rawEvents: [RawEvent]?
    public var customEvents: [CustomEvent]?
}

// ThinkingTelemetryState.swift
public struct ThinkingTelemetryState: Sendable {
    public var isThinking: Bool
    public var title: String?
    public var messages: [String]              // completed thinking text segments
}
```

### Tests

`AGUIClientTests` — verify `Sendable` conformance compiles clean. These are pure value types; no behaviour to unit test yet.

### Dependencies

None. No existing files modified.

---

## Phase 2 — EventVerifier (Protocol State Machine)

**Objective**: Implement the AG-UI protocol state machine that validates event sequences before they reach the state pipeline.

### Files to Create

```
Sources/AGUIClient/Streaming/EventVerifier.swift
Tests/AGUIClientTests/EventVerifierTests.swift
```

### Design

An `AsyncSequence` extension that mirrors the existing `transformChunks()` pattern. Internally uses a class (not actor) to hold mutable verification state because all access is serialised in a single `Task`:

```swift
// Public API — identical pattern to transformChunks()
extension AsyncSequence where Element == any AGUIEvent {
    public func verifyEvents(debug: Bool = false) -> AsyncThrowingStream<any AGUIEvent, Error>
}

// Thrown error type
public struct AGUIProtocolError: Error, Sendable {
    public let message: String
}
```

### Internal State

| Variable | Type | Purpose |
|---|---|---|
| `firstEventReceived` | `Bool` | First event must be `RUN_STARTED` |
| `runStarted` | `Bool` | A run is currently active |
| `runFinished` | `Bool` | Run completed — allows new `RUN_STARTED` |
| `runError` | `Bool` | Terminal — no further events allowed |
| `activeMessages` | `[String: Bool]` | `messageId → active` |
| `activeToolCalls` | `[String: Bool]` | `toolCallId → active` |
| `activeSteps` | `[String: Bool]` | `stepName → active` |
| `activeThinkingStep` | `Bool` | Inside `THINKING_START/END` block |
| `activeThinkingMessage` | `Bool` | Inside `THINKING_TEXT_MESSAGE_START/END` block |

### Validation Rules

| Rule | Violation Message |
|---|---|
| First event must be `RUN_STARTED` or `RUN_ERROR` | `"First event must be 'RUN_STARTED'"` |
| No events allowed after `RUN_ERROR` | `"Cannot send event type '…': The run has already errored"` |
| No events after `RUN_FINISHED` (except new `RUN_STARTED`) | `"Cannot send event type '…': The run has already finished"` |
| No duplicate `TEXT_MESSAGE_START` for same `messageId` | `"A text message with ID '…' is already in progress"` |
| `TEXT_MESSAGE_CONTENT` requires active `TEXT_MESSAGE_START` | `"No active text message found with ID '…'"` |
| `TEXT_MESSAGE_END` requires active `TEXT_MESSAGE_START` | `"No active text message found with ID '…'"` |
| No duplicate `TOOL_CALL_START` for same `toolCallId` | `"A tool call with ID '…' is already in progress"` |
| `TOOL_CALL_ARGS/END` requires active `TOOL_CALL_START` | `"No active tool call found with ID '…'"` |
| `STEP_FINISHED` requires prior `STEP_STARTED` for same `stepName` | `"Cannot send 'STEP_FINISHED' for step '…' that was not started"` |
| `THINKING_TEXT_MESSAGE_*` must be inside `THINKING_START/END` | `"No active thinking step found"` |
| `RUN_FINISHED` requires all messages, tool calls, steps closed | `"Cannot send 'RUN_FINISHED' while … are still active"` |

**Multi-run support**: When `RUN_STARTED` arrives after `runFinished == true`, clear all active tracking maps and reset `runFinished = false`. This enables sequential runs in a single stream.

### Tests (write first — TDD)

```
Tests/AGUIClientTests/EventVerifierTests.swift
```

Required test cases:
- Valid complete run passes through unmodified
- `AGUIProtocolError` on wrong first event
- No events accepted after `RUN_ERROR`
- Duplicate `TEXT_MESSAGE_START` same id throws
- `TEXT_MESSAGE_CONTENT` without `START` throws
- `RUN_FINISHED` with open text message throws
- `THINKING_TEXT_MESSAGE_START` outside `THINKING_START` throws
- Sequential runs: `RUN_FINISHED` → `RUN_STARTED` resets state correctly
- All 26 event types pass through when correctly sequenced

### Dependencies

Phase 1 types. No existing files modified.

---

## Phase 3 — `defaultApplyEvents` (Event-to-State Pipeline)

**Objective**: Transform a raw event stream into `AgentState` emissions. Without this, callers cannot observe structured state changes including message history, tool calls, thinking state, or custom events.

### Files to Create

```
Sources/AGUIClient/State/DefaultApplyEvents.swift
Tests/AGUIClientTests/DefaultApplyEventsTests.swift
```

### Public API

```swift
extension AsyncSequence where Element == any AGUIEvent {
    public func applyEvents(
        input: RunAgentInput,
        subscribers: [any AgentSubscriber] = []
    ) -> AsyncThrowingStream<AgentState, Error>
}
```

### Internal State

All within a single `Task` — no actor needed:

```swift
var messages: [any Message]         // mutable working list
var state: State                    // current JSON state (Data)
var rawEvents: [RawEvent]
var customEvents: [CustomEvent]
var thinkingActive: Bool
var thinkingVisible: Bool
var thinkingTitle: String?
var thinkingMessages: [String]
var thinkingBuffer: String?         // in-progress thinking text segment
var initialMessagesEmitted: Bool
```

### Event Handling

Every state-producing event and its action:

| Event | Action |
|---|---|
| `TextMessageStartEvent` | Append new `AssistantMessage(id:, content: "")` to messages |
| `TextMessageContentEvent` | Find message by id, append `delta` to its `content` |
| `TextMessageEndEvent` | No-op (message already in list) |
| `ToolCallStartEvent` | Find last `AssistantMessage` by `parentMessageId` (or last assistant); append `ToolCall` with empty arguments. If none exists, create new `AssistantMessage` |
| `ToolCallArgsEvent` | Find `AssistantMessage` containing `toolCallId`, append delta to `FunctionCall.arguments` |
| `ToolCallEndEvent` | No-op |
| `ToolCallResultEvent` | Append `ToolMessage(id: messageId, content:, toolCallId:)` to messages |
| `MessagesSnapshotEvent` | Replace entire `messages` list |
| `StateSnapshotEvent` | Replace `state` |
| `StateDeltaEvent` | Apply JSON Patch via `PatchApplicator` to `state` |
| `RawEvent` | Append to `rawEvents` |
| `CustomEvent` | Append to `customEvents` |
| `RunStartedEvent` | Reset all thinking state |
| `ThinkingStartEvent` | Set `thinkingActive = true`, `thinkingTitle = event.title` |
| `ThinkingEndEvent` | Finalise `thinkingBuffer` → append to `thinkingMessages`; set `thinkingActive = false` |
| `ThinkingTextMessageStartEvent` | Set new `thinkingBuffer = ""` |
| `ThinkingTextMessageContentEvent` | Append `event.delta` to `thinkingBuffer` |
| `ThinkingTextMessageEndEvent` | Finalise `thinkingBuffer` → append to `thinkingMessages` |

**Subscriber dispatch**: Before processing each event's state effect, call `runSubscribersWithMutation(subscribers:messages:state:)` dispatching `onEvent(params:)`. If mutation returns `stopPropagation == true`, skip the default state update and emit the subscriber's mutation instead.

**Emit on every state change**: Each handled event emits an `AgentState` with only the changed fields non-nil. For example, a `TextMessageContentEvent` sets only `.messages`; `.state`, `.thinking`, etc. are nil.

**Initial messages**: On first event, if `input.messages` is non-empty, emit an initial `AgentState(messages: input.messages)` before processing — mirrors Kotlin behaviour for pre-populated threads.

### Tests (write first — TDD)

```
Tests/AGUIClientTests/DefaultApplyEventsTests.swift
```

Required test cases:
- Text message sequence builds correct `AssistantMessage`
- Tool call sequence (Start → Args × N → End) builds `AssistantMessage.toolCalls`
- `ToolCallResultEvent` appends correct `ToolMessage`
- `MessagesSnapshotEvent` replaces messages
- `StateDeltaEvent` applies JSON Patch correctly
- `StateSnapshotEvent` replaces state
- Thinking sequence builds `ThinkingTelemetryState` with correct `messages`
- `RunStartedEvent` resets thinking state
- Subscriber `stopPropagation` suppresses default state update
- `RawEvent` and `CustomEvent` accumulate correctly

### Dependencies

Phase 1 types. `PatchApplicator.apply(patch:to:)` must be callable without going through `StateManager` actor context — extract it into a standalone `nonisolated` free function or make the method `static`.

---

## Phase 4 — `AbstractAgent` (Extensible Agent Base)

**Objective**: Provide an open class that users subclass to create any transport-backed agent (HTTP, WebSocket, local, mock). `HttpAgent` refactors to extend it.

### Files to Create

```
Sources/AGUIClient/AbstractAgent.swift
Sources/AGUIClient/AgentConfig.swift
Sources/AGUIClient/RunAgentParameters.swift
Tests/AGUIClientTests/AbstractAgentTests.swift
Tests/AGUIClientTests/HttpAgentPipelineTests.swift
```

### Files to Modify

```
Sources/AGUIClient/HttpAgent.swift   ← refactor from struct to class extending AbstractAgent
```

---

### `AgentConfig.swift`

```swift
// Base config
public struct AgentConfig: Sendable {
    public var agentId: String?
    public var description: String
    public var threadId: String?
    public var initialMessages: [any Message]
    public var initialState: State
    public var debug: Bool
}

// HTTP-specific config
public struct HttpAgentConfig: Sendable {
    public var base: AgentConfig
    public var url: String
    public var headers: [String: String]
    public var requestTimeout: TimeInterval   // default: 600s
    public var connectTimeout: TimeInterval   // default: 30s
    // Auth convenience — setting either automatically updates headers
    public var bearerToken: String?
    public var apiKey: String?
    public var apiKeyHeader: String           // default: "X-API-Key"
}
```

---

### `RunAgentParameters.swift`

```swift
public struct RunAgentParameters: Sendable {
    public var runId: String?
    public var tools: [Tool]?
    public var context: [Context]?
    public var forwardedProps: State?
}
```

---

### `AbstractAgent.swift`

**Core design**: Swift actors cannot be subclassed. Use `open class: @unchecked Sendable` with an internal `actor` (`AgentStorage`) for all mutable state.

```swift
public open class AbstractAgent: @unchecked Sendable {

    // MARK: - Internal actor for thread-safe mutable state
    private let storage: AgentStorage          // private actor

    // MARK: - Configuration (immutable after init)
    public let description: String
    public let threadId: String
    public private(set) var agentId: String?
    public let debug: Bool

    // MARK: - Public state accessors (async — routed through actor)
    public var messages: [any Message] { get async }
    public var state: State             { get async }
    public var rawEvents: [RawEvent]    { get async }
    public var customEvents: [CustomEvent] { get async }
    public var thinking: ThinkingTelemetryState? { get async }

    // MARK: - The one method subclasses must implement
    open func run(input: RunAgentInput) -> AsyncThrowingStream<any AGUIEvent, Error> {
        fatalError("Subclasses must implement run(input:)")
    }

    // MARK: - Public API
    public func runAgent(
        parameters: RunAgentParameters? = nil,
        subscriber: (any AgentSubscriber)? = nil
    ) async throws

    public func runAgentObservable(
        input: RunAgentInput,
        subscriber: (any AgentSubscriber)? = nil
    ) -> AsyncThrowingStream<any AGUIEvent, Error>

    public func runAgentObservable(
        parameters: RunAgentParameters? = nil,
        subscriber: (any AgentSubscriber)? = nil
    ) -> AsyncThrowingStream<any AGUIEvent, Error>

    public func abortRun()
    public func dispose()
    public func subscribe(_ subscriber: any AgentSubscriber) async -> any AgentSubscription
    open func clone() -> Self
}
```

### `runAgent()` Pipeline

```swift
public func runAgent(parameters: RunAgentParameters? = nil, ...) async throws {
    let input = prepareInput(parameters)
    currentTask = Task {
        try await run(input)
            .transformChunks(debug: debug)    // existing — Phase 2 already wires debug
            .verifyEvents(debug: debug)        // Phase 2 — new
            .applyEvents(input: input,         // Phase 3 — new
                         subscribers: activeSubscribers)
            .processApplyEvents()              // updates storage + fires subscriber hooks
            .collect()                         // drives the pipeline
    }
    try await currentTask?.value
}
```

### `processApplyEvents()` — Internal Pipeline Stage

An `AsyncSequence` extension on `AsyncThrowingStream<AgentState, Error>` that:

1. Receives `AgentState` emissions from `applyEvents()`
2. Writes changed fields to the internal `AgentStorage` actor
3. Fires `onMessagesChanged` and `onStateChanged` subscriber hooks when respective fields are non-nil
4. Re-emits `AgentState` unchanged (for `runAgentObservable`)

### Subscriber Lifecycle Notifications

| Hook | When Called |
|---|---|
| `onRunInitialized` | Before pipeline starts; applies any `AgentStateMutation` to initial state |
| `onRunFailed` | On any error thrown by the pipeline; `stopPropagation` suppresses `onError()` |
| `onRunFinalized` | In `defer` block — always called regardless of success/failure |

### `HttpAgent` Refactoring

`HttpAgent` changes from `struct` to `final class` extending `AbstractAgent`:

```swift
public final class HttpAgent: AbstractAgent {
    // Only the HTTP-specific transport state
    private let transport: HttpTransport

    public override func run(input: RunAgentInput) -> AsyncThrowingStream<any AGUIEvent, Error> {
        // Existing implementation: transport.execute → EventStream → yield events
        // EventStream bytes → SSE → decode → yield each AGUIEvent
    }

    public override func clone() -> Self { ... }
}
```

The existing builder-style `run(_:endpoint:)` and `run(threadId:runId:configure:)` methods on `HttpAgent` are **preserved** and forward to `runAgentObservable()` internally — existing callers are unaffected.

> **Breaking change note**: `HttpAgent` changes from `struct` to `class`. Copy semantics change. Document in release notes. All existing `let agent = HttpAgent(...)` usage is source-compatible.

### Tests (write first — TDD)

```
Tests/AGUIClientTests/AbstractAgentTests.swift
Tests/AGUIClientTests/HttpAgentPipelineTests.swift
```

Required test cases:
- Custom `AbstractAgent` subclass with mock `run()` correctly processes full pipeline
- `abortRun()` cancels the in-flight task
- `dispose()` prevents further runs
- `runAgentObservable()` emits processed `AgentState` events
- All 6 subscriber lifecycle hooks fire in correct order
- `stopPropagation` in subscriber halts default processing
- Sequential runs: two `runAgent()` calls on same instance maintain state correctly
- `HttpAgent.run()` wires into full pipeline end-to-end

### Dependencies

Phases 1, 2, 3. Modifies `HttpAgent.swift`.

---

## Phase 5 — `ToolExecutionManager` + `ToolResponseHandler`

**Objective**: Automatic tool call lifecycle management — detect tool calls in event streams, execute via registry, send results back.

### Files to Create

```
Sources/AGUITools/Core/ToolResponseHandler.swift
Sources/AGUITools/Core/ToolExecutionManager.swift
Sources/AGUITools/Core/ToolExecutionEvent.swift
Tests/AGUIToolsTests/ToolExecutionManagerTests.swift
```

---

### `ToolResponseHandler.swift`

```swift
public protocol ToolResponseHandler: Sendable {
    func sendToolResponse(
        _ message: ToolMessage,
        threadId: String?,
        runId: String?
    ) async throws
}
```

---

### `ToolExecutionEvent.swift`

```swift
public enum ToolExecutionEvent: Sendable {
    case started(toolCallId: String, toolName: String)
    case executing(toolCallId: String, toolName: String)
    case succeeded(toolCallId: String, toolName: String, result: ToolExecutionResult)
    case failed(toolCallId: String, toolName: String, error: String)
}
```

---

### `ToolExecutionManager.swift`

`ToolExecutionManager` processes an event stream and side-effects tool execution. It passes all events through unchanged while reacting to tool call events concurrently:

```swift
public actor ToolExecutionManager {
    private let toolRegistry: any ToolRegistry
    private let responseHandler: any ToolResponseHandler
    private var activeExecutions: [String: Task<Void, Error>] = [:]
    private var toolCallBuffer: [String: ToolCallBuilder] = [:]

    // Hot monitoring stream
    public let executionEvents: AsyncStream<ToolExecutionEvent>

    public func processEventStream(
        _ events: some AsyncSequence<any AGUIEvent>,
        threadId: String?,
        runId: String?
    ) -> AsyncThrowingStream<any AGUIEvent, Error>

    public func cancelAllExecutions()
    public func activeExecutionCount() -> Int
    public func isExecuting(toolCallId: String) -> Bool
}
```

**Internal logic per event:**

| Event | Action |
|---|---|
| `ToolCallStartEvent` | Create `ToolCallBuilder(id:name:)`, store in `toolCallBuffer` |
| `ToolCallArgsEvent` | Append delta to builder |
| `ToolCallEndEvent` | Build complete `ToolCall`, spawn `Task` to execute; track in `activeExecutions` |
| `RunFinishedEvent` / `RunErrorEvent` | `await` all active execution tasks before finishing stream |
| All other events | Pass through unchanged |

**Tool execution task** (per tool call):

```
ToolCallBuilder.build()
    → ToolExecutionContext(toolCall:, threadId:, runId:)
    → registry.execute(context:) → ToolExecutionResult
    → format result as String
    → ToolMessage(id: UUID, content: formattedResult, toolCallId:)
    → responseHandler.sendToolResponse(_:threadId:runId:)
```

Error handling: if `ToolRegistryError.toolNotFound` or execution throws, send an error `ToolMessage` back. Neither case throws from the stream — tool errors are reported back to the agent, not the caller.

### Tests (write first — TDD)

```
Tests/AGUIToolsTests/ToolExecutionManagerTests.swift
```

Required test cases (using a mock `ToolResponseHandler`):
- Tool call sequence triggers execution and sends response
- Multiple concurrent tool calls execute concurrently
- `RunFinishedEvent` awaits all pending executions before completing stream
- Unknown tool name → error `ToolMessage` sent, stream continues
- `cancelAllExecutions()` cancels pending tasks
- `executionEvents` stream emits correct lifecycle events in order

### Dependencies

`AGUITools` → `AGUICore` only (no new package dependency). Phase 1 not required here.

---

## Phase 6 — `ClientToolResponseHandler` (HTTP Bridge)

**Objective**: HTTP implementation of `ToolResponseHandler` that sends tool results back through `HttpAgent`.

### Files to Create

```
Sources/AGUIAgentSDK/Tools/ClientToolResponseHandler.swift
Tests/AGUIAgentSDKTests/ClientToolResponseHandlerTests.swift
```

### Files to Modify

```
Package.swift   ← add AGUITools to AGUIAgentSDK dependencies
```

> **Why `AGUIAgentSDK` and not `AGUIClient`?** `ClientToolResponseHandler` bridges both `AGUIClient` (`HttpAgent`) and `AGUITools` (`ToolResponseHandler`). `AGUIAgentSDK` already depends on both, making it the correct integration layer. This avoids a circular dependency.

### Implementation

```swift
public final class ClientToolResponseHandler: ToolResponseHandler, Sendable {
    private let httpAgent: HttpAgent

    public init(httpAgent: HttpAgent) {
        self.httpAgent = httpAgent
    }

    public func sendToolResponse(
        _ message: ToolMessage,
        threadId: String?,
        runId: String?
    ) async throws {
        let input = RunAgentInput(
            threadId: threadId ?? "tool_\(UUID().uuidString)",
            runId: runId ?? "run_\(UUID().uuidString)",
            messages: [message]
        )
        // Drive the full pipeline; discard resulting events
        for try await _ in httpAgent.runAgentObservable(input: input) { }
    }
}
```

### `Package.swift` Change

```swift
.target(
    name: "AGUIAgentSDK",
    dependencies: ["AGUICore", "AGUIClient", "AGUITools"]  // AGUITools added
)
```

### Tests (write first — TDD)

```
Tests/AGUIAgentSDKTests/ClientToolResponseHandlerTests.swift
```

Test: use a mock `HttpAgent` subclass to verify `sendToolResponse` constructs the correct `RunAgentInput` containing the tool message with the correct `threadId` and `runId`.

### Dependencies

Phase 4 (`HttpAgent` as class), Phase 5 (`ToolResponseHandler` protocol).

---

## Phase 7 — Wire `ToolRegistry` into Agents

**Objective**: `StatefulAgUiAgent` automatically populates tool definitions in `RunAgentInput`, routes tool calls through `ToolExecutionManager`, and correctly tracks tool call events in conversation history. Also fixes the silent `StateDeltaEvent` drop.

### Files to Modify

```
Sources/AGUIAgentSDK/StatefulAgUiAgentConfig.swift
Sources/AGUIAgentSDK/StatefulAgUiAgent.swift
Tests/AGUIAgentSDKTests/StatefulAgUiAgentToolTests.swift
```

---

### `StatefulAgUiAgentConfig` Additions

```swift
public struct StatefulAgUiAgentConfig: Sendable {
    // ... existing fields ...

    /// When set, tool definitions are automatically included in every RunAgentInput
    /// and tool calls are executed and fed back to the agent.
    public var toolRegistry: (any ToolRegistry)?

    /// Persistent user ID for message attribution.
    public var userId: String?

    /// Context items included with every request.
    public var context: [Context]

    // Auth convenience
    public var bearerToken: String?
    public var apiKey: String?
    public var apiKeyHeader: String   // default: "X-API-Key"
}
```

---

### `StatefulAgUiAgent` Changes

**Init**: if `config.toolRegistry != nil`, create:

```swift
self.toolExecutionManager = ToolExecutionManager(
    toolRegistry: config.toolRegistry!,
    responseHandler: ClientToolResponseHandler(httpAgent: httpAgent)
)
```

**`sendMessage`**: populate `RunAgentInput.tools` from `toolRegistry.allTools()`.

**`sendMessage`**: wrap the raw `EventStream` through `ToolExecutionManager` before passing to `trackHistoryAndState()`:

```swift
let rawStream = try await httpAgent.run(input)
let processedStream = toolExecutionManager?.processEventStream(rawStream, ...) ?? rawStream
return trackHistoryAndState(stream: processedStream, threadId: threadId)
```

**`trackHistoryAndState()`** — add missing event handling:

```swift
// Tool call tracking
case let start as ToolCallStartEvent:
    pendingToolCalls[start.toolCallId] = ToolCallBuilder(id: start.toolCallId, name: start.toolCallName)

case let args as ToolCallArgsEvent:
    pendingToolCalls[args.toolCallId]?.append(delta: args.delta)

case let end as ToolCallEndEvent:
    if let builder = pendingToolCalls.removeValue(forKey: end.toolCallId) {
        // Find or create AssistantMessage and attach the completed ToolCall
        upsertToolCallInHistory(builder.build(), to: threadId)
    }

case let result as ToolCallResultEvent:
    let toolMsg = ToolMessage(id: result.messageId, content: result.content, toolCallId: result.toolCallId)
    await historyManager.append(message: toolMsg, to: threadId)

// Full history replacement
case let snapshot as MessagesSnapshotEvent:
    await historyManager.replace(messages: snapshot.messages, for: threadId)

// Fix: StateDelta was silently dropped — now applied via PatchApplicator
case let delta as StateDeltaEvent:
    let currentState = await stateManager.currentState()
    if let patched = try? patchApplicator.apply(patch: delta.delta, to: currentState) {
        await stateManager.updateState(patched)
    }
```

### Tests (write first — TDD)

```
Tests/AGUIAgentSDKTests/StatefulAgUiAgentToolTests.swift
```

Required test cases:
- Tool call events appear correctly in conversation history after a tool-using run
- Tool registry tools are included in `RunAgentInput.tools`
- `StateDeltaEvent` updates state correctly (was silently dropped before this phase)
- `MessagesSnapshotEvent` replaces history correctly
- Agent with no tool registry still works correctly

### Dependencies

Phases 4, 5, 6.

---

## Phase 8 — `ToolErrorHandler` (Circuit Breaker & Retry)

**Objective**: Sophisticated error recovery for tool execution — configurable retry backoff and circuit breaker to prevent cascading failures.

### Files to Create

```
Sources/AGUITools/Core/ToolErrorHandler.swift
Sources/AGUITools/Core/CircuitBreaker.swift
Sources/AGUITools/Core/ToolExceptions.swift
Tests/AGUIToolsTests/CircuitBreakerTests.swift
Tests/AGUIToolsTests/ToolErrorHandlerTests.swift
```

---

### `ToolExceptions.swift`

Typed exception hierarchy used for retry categorisation:

```swift
public class ToolValidationException: Error { }  // not retryable
public class ToolTimeoutException: Error { }      // retryable
public class ToolNetworkException: Error { }      // retryable
public class ToolResourceException: Error { }     // configurable
```

---

### `CircuitBreaker.swift`

```swift
public actor CircuitBreaker {
    public enum State { case closed, open, halfOpen }
    public private(set) var state: State = .closed

    private let config: CircuitBreakerConfig
    private var failureCount = 0
    private var successCount = 0
    private var lastFailureTime: ContinuousClock.Instant?

    // Automatically transitions OPEN → HALF_OPEN when recovery timeout expires
    public func isOpen() -> Bool

    // CLOSED → OPEN at failure threshold; HALF_OPEN → OPEN on any failure
    public func recordFailure()

    // HALF_OPEN → CLOSED when success threshold met; CLOSED: resets failure count
    public func recordSuccess()

    public func reset()
    public func getState() -> State
}

public struct CircuitBreakerConfig: Sendable {
    public var failureThreshold: Int = 5
    public var recoveryTimeout: Duration = .seconds(60)
    public var successThreshold: Int = 2
}
```

---

### `ToolErrorHandler.swift`

```swift
public enum RetryStrategy: Sendable {
    case fixed
    case linear
    case exponential
    case exponentialJitter
}

public struct ToolErrorConfig: Sendable {
    public var maxRetryAttempts: Int = 3
    public var baseRetryDelay: Duration = .seconds(1)
    public var maxRetryDelay: Duration = .seconds(30)
    public var retryStrategy: RetryStrategy = .exponentialJitter
    public var retryOnResourceErrors: Bool = true
    public var retryOnUnknownErrors: Bool = false
    public var maxHistorySize: Int = 100
    public var circuitBreakerConfig: CircuitBreakerConfig = .init()
}

public enum ToolErrorDecision: Sendable {
    case retry(delay: Duration, maxAttempts: Int)
    case fail(message: String, shouldReport: Bool)
}

public actor ToolErrorHandler {
    public init(config: ToolErrorConfig = .init())

    public func handleError(
        _ error: Error,
        context: ToolExecutionContext,
        attempt: Int
    ) async -> ToolErrorDecision

    public func recordSuccess(toolName: String)
    public func errorStats(for toolName: String) -> ToolErrorStats
    public func resetErrorState(for toolName: String)
}
```

**Integration point**: `ToolExecutionManager` optionally takes a `ToolErrorHandler`. When present, the execution task wraps `registry.execute(context:)` in a retry loop driven by `handleError(_:context:attempt:)`.

### Tests (write first — TDD)

```
Tests/AGUIToolsTests/CircuitBreakerTests.swift
Tests/AGUIToolsTests/ToolErrorHandlerTests.swift
```

Required test cases:
- All 3 circuit breaker state transitions (CLOSED → OPEN → HALF_OPEN → CLOSED)
- Circuit opens exactly at `failureThreshold`
- HALF_OPEN → OPEN on any failure during recovery
- Recovery timeout triggers OPEN → HALF_OPEN transition
- All 4 retry strategies produce correct delays
- Jitter stays within `±10%` of base exponential
- `ToolValidationException` is never retried
- `ToolTimeoutException` is always retried
- Error stats are accurate after mixed success/failure runs

### Dependencies

Phase 5.

---

## Phase 9 — `AgUiAgent` (Stateless Convenience Agent)

**Objective**: A stateless convenience wrapper providing `sendMessage()`, tool integration, and auth helpers without maintaining conversation history.

### Files to Create

```
Sources/AGUIAgentSDK/AgUiAgent.swift
Sources/AGUIAgentSDK/AgUiAgentConfig.swift
Sources/AGUIAgentSDK/AgentBuilders.swift
Tests/AGUIAgentSDKTests/AgUiAgentTests.swift
Tests/AGUIAgentSDKTests/AgentBuildersTests.swift
```

---

### `AgUiAgentConfig.swift`

```swift
public struct AgUiAgentConfig: Sendable {
    public var bearerToken: String?
    public var apiKey: String?
    public var apiKeyHeader: String = "X-API-Key"
    public var headers: [String: String] = [:]
    public var systemPrompt: String?
    public var debug: Bool = false
    public var toolRegistry: (any ToolRegistry)?
    public var userId: String?
    public var context: [Context] = []
    public var forwardedProps: State = Data("{}".utf8)
    public var requestTimeout: TimeInterval = 600
    public var connectTimeout: TimeInterval = 30

    /// Merges auth helpers into headers dict
    public func buildHeaders() -> [String: String]
}
```

---

### `AgUiAgent.swift`

```swift
open class AgUiAgent: Sendable {
    public let config: AgUiAgentConfig
    private let agent: HttpAgent
    private let toolExecutionManager: ToolExecutionManager?

    public init(url: URL, configure: (inout AgUiAgentConfig) -> Void = { _ in })

    /// Run with explicit input — override for custom behaviour
    open func run(input: RunAgentInput) -> AsyncThrowingStream<any AGUIEvent, Error>

    /// Convenience — creates fresh input each call (no history)
    open func sendMessage(
        _ message: String,
        threadId: String = UUID().uuidString,
        state: State? = nil,
        includeSystemPrompt: Bool = true
    ) -> AsyncThrowingStream<any AGUIEvent, Error>

    public func subscribe(_ subscriber: any AgentSubscriber) async -> any AgentSubscription
    open func close()
}
```

---

### `AgentBuilders.swift`

Convenience factory functions mirroring Kotlin's `AgentBuilders.kt`:

```swift
/// Bearer token authenticated agent
public func agentWithBearer(url: URL, token: String) -> AgUiAgent

/// API key authenticated agent
public func agentWithApiKey(url: URL, apiKey: String, header: String = "X-API-Key") -> AgUiAgent

/// Stateless agent with tool registry
public func agentWithTools(url: URL, registry: any ToolRegistry) -> AgUiAgent

/// Stateful agent with system prompt
public func chatAgent(url: URL, systemPrompt: String) -> StatefulAgUiAgent

/// Stateful agent with initial JSON state
public func statefulAgent(url: URL, initialState: State) -> StatefulAgUiAgent

/// Agent with verbose debug logging
public func debugAgent(url: URL) -> AgUiAgent
```

### Tests (write first — TDD)

```
Tests/AGUIAgentSDKTests/AgUiAgentTests.swift
Tests/AGUIAgentSDKTests/AgentBuildersTests.swift
```

Required test cases:
- `sendMessage` constructs correct `RunAgentInput` (system prompt, user message, no history)
- `sendMessage` includes tool definitions when registry configured
- `close()` calls `agent.dispose()`
- Builder functions produce correctly configured agent instances

### Dependencies

Phases 4, 5, 6, 7.

---

## Phase 10 — Auth Helpers & Debug Mode

**Objective**: Surface convenience auth properties on all config types and propagate the `debug` flag through the pipeline.

### Files to Modify

```
Sources/AGUIClient/Transport/HttpAgentConfiguration.swift
Sources/AGUIAgentSDK/StatefulAgUiAgentConfig.swift
```

### `HttpAgentConfiguration` Additions

```swift
public struct HttpAgentConfiguration: Sendable {
    // ... existing fields ...
    public var debug: Bool = false

    // Setting these automatically rebuilds the Authorization / API key header
    public var bearerToken: String? { didSet { rebuildHeaders() } }
    public var apiKey: String?      { didSet { rebuildHeaders() } }
    public var apiKeyHeader: String = "X-API-Key" { didSet { rebuildHeaders() } }

    private mutating func rebuildHeaders() { ... }
}
```

**Debug propagation**: `debug` is forwarded from `HttpAgentConfiguration` into `AbstractAgent.config.debug`, which in turn passes it to `.transformChunks(debug:)` and `.verifyEvents(debug:)`.

### `StatefulAgUiAgentConfig` Additions (if not already added in Phase 7)

```swift
public var debug: Bool = false
public var bearerToken: String?
public var apiKey: String?
public var apiKeyHeader: String = "X-API-Key"
```

### Dependencies

Phase 4.

---

## Phase 11 — `ToolRegistry.getAllExecutors()` + Integration Tests

**Objective**: Add the missing `getAllExecutors()` method; verify end-to-end pipeline with integration tests.

### Files to Modify

```
Sources/AGUITools/Registry/ToolRegistry.swift   ← add getAllExecutors() to protocol + DefaultToolRegistry
```

### Files to Create

```
Tests/AGUIAgentSDKTests/EndToEndPipelineTests.swift
```

### `ToolRegistry` Protocol Addition

```swift
public protocol ToolRegistry: Sendable {
    // ... existing methods ...

    /// Returns all registered executors keyed by tool name.
    func allExecutors() async -> [String: any ToolExecutor]
}

// DefaultToolRegistry implementation
public func allExecutors() async -> [String: any ToolExecutor] {
    executors   // returns copy of internal dict
}
```

### Integration Tests

```
Tests/AGUIAgentSDKTests/EndToEndPipelineTests.swift
```

These tests run full simulated agent interactions using a `MockHttpAgent` subclass (overrides `run()` to emit a pre-configured event sequence):

| Scenario | What is verified |
|---|---|
| Text-only conversation | Messages accumulate correctly across turns |
| Tool-using conversation | Tool calls execute, results feed back, history correct |
| Thinking-enabled conversation | `ThinkingTelemetryState` builds correctly |
| Sequential multi-run | Two `runAgent()` calls on same instance maintain state |
| State delta | JSON Patch applied and reflected in `agent.state` |
| Invalid event stream | `AGUIProtocolError` thrown by `verifyEvents()` |
| Circuit breaker | After 5 tool failures, subsequent calls fail fast |

### Dependencies

All prior phases.

---

## Package.swift — Final State

```swift
.target(name: "AGUICore",      dependencies: []),
.target(name: "AGUIClient",    dependencies: ["AGUICore"]),
.target(name: "AGUITools",     dependencies: ["AGUICore"]),
.target(name: "AGUIAgentSDK",  dependencies: ["AGUICore", "AGUIClient", "AGUITools"]),  // AGUITools added
```

---

## All Files Created / Modified

| Phase | Action | File |
|---|---|---|
| 1 | Create | `Sources/AGUIClient/State/AgentState.swift` |
| 1 | Create | `Sources/AGUIClient/State/ThinkingTelemetryState.swift` |
| 2 | Create | `Sources/AGUIClient/Streaming/EventVerifier.swift` |
| 2 | Create | `Tests/AGUIClientTests/EventVerifierTests.swift` |
| 3 | Create | `Sources/AGUIClient/State/DefaultApplyEvents.swift` |
| 3 | Create | `Tests/AGUIClientTests/DefaultApplyEventsTests.swift` |
| 4 | Create | `Sources/AGUIClient/AbstractAgent.swift` |
| 4 | Create | `Sources/AGUIClient/AgentConfig.swift` |
| 4 | Create | `Sources/AGUIClient/RunAgentParameters.swift` |
| 4 | **Modify** | `Sources/AGUIClient/HttpAgent.swift` (struct → class) |
| 4 | Create | `Tests/AGUIClientTests/AbstractAgentTests.swift` |
| 4 | Create | `Tests/AGUIClientTests/HttpAgentPipelineTests.swift` |
| 5 | Create | `Sources/AGUITools/Core/ToolResponseHandler.swift` |
| 5 | Create | `Sources/AGUITools/Core/ToolExecutionManager.swift` |
| 5 | Create | `Sources/AGUITools/Core/ToolExecutionEvent.swift` |
| 5 | Create | `Tests/AGUIToolsTests/ToolExecutionManagerTests.swift` |
| 6 | Create | `Sources/AGUIAgentSDK/Tools/ClientToolResponseHandler.swift` |
| 6 | **Modify** | `Package.swift` (add `AGUITools` dep to `AGUIAgentSDK`) |
| 6 | Create | `Tests/AGUIAgentSDKTests/ClientToolResponseHandlerTests.swift` |
| 7 | **Modify** | `Sources/AGUIAgentSDK/StatefulAgUiAgentConfig.swift` |
| 7 | **Modify** | `Sources/AGUIAgentSDK/StatefulAgUiAgent.swift` |
| 7 | Create | `Tests/AGUIAgentSDKTests/StatefulAgUiAgentToolTests.swift` |
| 8 | Create | `Sources/AGUITools/Core/ToolErrorHandler.swift` |
| 8 | Create | `Sources/AGUITools/Core/CircuitBreaker.swift` |
| 8 | Create | `Sources/AGUITools/Core/ToolExceptions.swift` |
| 8 | Create | `Tests/AGUIToolsTests/CircuitBreakerTests.swift` |
| 8 | Create | `Tests/AGUIToolsTests/ToolErrorHandlerTests.swift` |
| 9 | Create | `Sources/AGUIAgentSDK/AgUiAgent.swift` |
| 9 | Create | `Sources/AGUIAgentSDK/AgUiAgentConfig.swift` |
| 9 | Create | `Sources/AGUIAgentSDK/AgentBuilders.swift` |
| 9 | Create | `Tests/AGUIAgentSDKTests/AgUiAgentTests.swift` |
| 9 | Create | `Tests/AGUIAgentSDKTests/AgentBuildersTests.swift` |
| 10 | **Modify** | `Sources/AGUIClient/Transport/HttpAgentConfiguration.swift` |
| 10 | **Modify** | `Sources/AGUIAgentSDK/StatefulAgUiAgentConfig.swift` |
| 11 | **Modify** | `Sources/AGUITools/Registry/ToolRegistry.swift` |
| 11 | Create | `Tests/AGUIAgentSDKTests/EndToEndPipelineTests.swift` |

**Total: 24 new files, 9 modified files, 13 new test files.**

---

## Breaking Changes & Migration Notes

| Change | Risk | Mitigation |
|---|---|---|
| `HttpAgent` changes from `struct` to `class` | **Medium** — copy semantics change | Document in changelog; `let agent = HttpAgent(...)` is source-compatible |
| `EventVerifier` added to `AbstractAgent` pipeline | **Low** — only catches invalid streams | Agents producing valid streams are unaffected |
| `PatchApplicator` method extracted from `StateManager` actor | **Low** — internal refactor | Public `StateManager` API unchanged |
| `AGUITools` added as `AGUIAgentSDK` dependency | **None** — additive only | |

---

## Testing Strategy

All phases follow **Red-Green-Refactor** TDD:

1. Write the test file for the phase first
2. Confirm tests fail (red)
3. Write the minimum implementation to pass (green)
4. Refactor with `swift build` and `swift test` staying green

Each phase must pass all of:
```bash
swift build
swift test
swiftlint lint
swift package plugin --allow-writing-to-package-directory swiftformat
```

before moving to the next phase.
