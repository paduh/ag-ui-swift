# PR #1512 Implementation Plan

## Source

Based on review feedback from [ag-ui-protocol/ag-ui#1512](https://github.com/ag-ui-protocol/ag-ui/pull/1512) and
cross-SDK parity analysis against the TypeScript (`sdks/typescript`) and Go (`sdks/community/go`) reference
implementations.

## Status of Reviewer's Issues

Most critical and high-priority bugs raised by the reviewer have **already been fixed** in the current
codebase. The items below are the confirmed remaining gaps.

### Already Resolved — No Action Required

| Issue | Evidence |
|-------|---------|
| C1 — Missing Reasoning events | All 7 `REASONING_*` cases in `EventType.swift`, structs + DTOs exist |
| C2 — Role.reasoning / encryptedValue | `Role.reasoning` exists; `encryptedValue` present on all 7 message types (`AssistantMessage`, `UserMessage`, `SystemMessage`, `ToolMessage`, `DeveloperMessage`, `ReasoningMessage`, `ActivityMessage`) and `ToolCall`; all message DTOs decode it |
| H1 — RunStartedEvent missing parentRunId/input | Both fields present |
| H2 — RunFinishedEvent missing result | `result: Data?` present |
| H3 — RunErrorEvent non-standard structure | Has `message: String`, `code: String?`; no extra fields |
| H4 — RawEvent reads `data` not `event` | `RawEventDTO` reads `jsonObject["event"]`, has `source: String?` |
| H5 — Bool/Int type priority | `AnyCodable` decodes `Bool` before `Int` in `PatchApplicator` |
| H6 — SSE line endings | `SseParser` normalises `\r\n` → `\n` and `\r` → `\n` |
| H7 — Duplicate assistant messages | `ToolCallEndEvent` is `break`; flush only at `ToolCallResultEvent` |
| H8 — JSON Pointer root path | `parsePath("/")` returns `[""]` per RFC 6901 |
| H9 — Timeout error missing tool name | `withTimeout` in `ToolRegistry.swift:323` passes `toolName` and throws `ToolExecutionError.timeout(toolName:duration:)` correctly |
| H10 — HTTPResponse leaks URLSession.AsyncBytes | `HTTPResponse.bytes` is `AsyncThrowingStream<UInt8, Error>` |
| H11 — Dead AgentConfig / HttpAgentConfig | `AgentConfig` and `HttpAgentConfig` removed from `AgentConfig.swift`; `RunAgentParameters` kept (live — used by `AbstractAgent` + `HttpAgent`); moved to `RunAgentParameters.swift`; `connectTimeout` removed from `AgUiAgentConfig` |
| TextMessage* missing `name` | Both `TextMessageStartEvent` and `TextMessageChunkEvent` have `name: String?` |
| Tool missing `metadata` | `Tool.metadata: Data?` present with full encode/decode |
| No SSE reconnection | `HttpAgentTransport` has `lastEventId` tracking + retry loop |
| No SwiftUI/Combine integration | `AgentViewModelCompat` (`ObservableObject`/`@Published`) and `AgentViewModel` (`@Observable`) both exist in `AGUIAgentSDK` |
| `@frozen` on EventType | Not present |
| `@unchecked Sendable` | Not present in `Sources/` |
| `bearerToken` didSet | Uses `buildHeaders()` computed pattern — reads `bearerToken` dynamically at call time, no `didSet` needed |
| UnknownEvent.eventType returns `.raw` | `UnknownEvent.eventType` returns `.unknown` sentinel — distinct from the genuine `.raw` wire-format event |
| CircuitBreaker disconnected | `CircuitBreaker` actor is instantiated inside `ToolErrorHandler`; `allowRequest()`, `recordSuccess()`, `recordFailure()` all called from `handleError()` |
| RetryPolicy "dead code" | `RetryPolicy` IS fully wired: `AgUiAgentConfig.retryPolicy` → `HttpAgentConfiguration.retryPolicy` → `HttpAgentTransport.shouldRetry()` / `retryDelay()` — plan Bug 5 was wrong, removed |

---

## Confirmed Gaps — Must Fix

---

### Bug 1 — `MessageEncoder` missing `.reasoning` handler

**File:** `Sources/AGUICore/Encoding/MessageEncoder.swift`

`defaultRegistry()` handles 6 roles: `.developer`, `.system`, `.user`, `.assistant`, `.tool`,
`.activity`. The `.reasoning` role is absent. Calling `encode(reasoningMessage)` throws
`unsupportedRole(.reasoning)` at runtime — a silent crash for any consumer serialising conversation
history that contains a `ReasoningMessage`.

Both TypeScript and Go treat `ReasoningMessage` as a first-class message type.

**Fix:** Add private `encodeReasoningMessage()` function (mirrors `encodeAssistantMessage()`) and
register it under `.reasoning` in `defaultRegistry()`.

---

### Bug 2 — `RunFinishedEvent` missing `outcome` field

**Files:**
- `Sources/AGUICore/Events/LifecycleEvents/RunFinishedEvent.swift`
- `Sources/AGUICore/Decoding/EventDTO/LifecycleEventsDTO/RunFinishedEventDTO.swift`

TypeScript defines:
```typescript
outcome?: { type: "success" } | { type: "interrupt", interrupts: Interrupt[] }
// Interrupt: { type: string; value?: any }
```

Without this field the SDK cannot distinguish a clean finish from an agent-requested interrupt —
both look identical to callers. Go's community SDK also lacks this field; TypeScript is the
authoritative spec.

**Fix:** New `RunFinishedOutcome` enum + `Interrupt` struct in `AGUICore`; add
`outcome: RunFinishedOutcome? = nil` to `RunFinishedEvent` and decode it in the DTO.

---

### Bug 3 — Media input content types missing `mimeType`

**Files:**
- `Sources/AGUICore/Types/InputContent/ImageInputContent.swift`
- `Sources/AGUICore/Types/InputContent/AudioInputContent.swift`
- `Sources/AGUICore/Types/InputContent/VideoInputContent.swift`
- `Sources/AGUICore/Types/InputContent/DocumentInputContent.swift`

TypeScript's `InputContentSource` carries `mimeType` on both data and URL sources. Swift's flat
`url: String?` / `data: String?` fields omit `mimeType`, making it impossible to express
`image/png` vs `image/jpeg` for inline base64 data — information a TypeScript server expects.
`BinaryInputContent` already has a required `mimeType: String`.

**Fix:** Add `mimeType: String?` to the four media types (defaulted → no call-site breakage).
Update the four corresponding DTOs and `MessageEncoder.encodeUserMessage()`.

---

### Bug 4 — `connectTimeout` declared but never consumed

**Files:**
- `Sources/AGUIAgentSDK/AgUiAgentConfig.swift` — `public var connectTimeout: TimeInterval`
- `Sources/AGUIAgentSDK/StatefulAgUiAgentConfig.swift` — verify if present

`HttpTransport` configures `URLSession` using only `configuration.timeout`
(`timeoutIntervalForRequest` and `timeoutIntervalForResource`). The `connectTimeout` field is
never read by any transport code — it is declared and set to `30` but silently ignored.

**Fix:** Remove `connectTimeout` from `AgUiAgentConfig` and `StatefulAgUiAgentConfig`. If a
separate connection timeout is needed in future it should be wired through to
`HttpAgentConfiguration` and consumed by `HttpTransport`.

---

### Bug 5 — `ActivityMessage` domain field name and type diverge from protocol

**Files:**
- `Sources/AGUICore/Types/Messages/ActivityMessage.swift`
- `Sources/AGUICore/Decoding/MessageDTO/ActivityMessageDTO.swift`

The protocol defines `content: Record<string, any>` on `ActivityMessage`. The Swift domain type
exposes this as `activityContent: Data` — both the property name and the type differ. The DTO
correctly reads the wire key `"content"`, but re-exposes it as `activityContent`, so any Swift
consumer must know to look for `activityContent` even though the protocol field is `content`.

**Fix:** Rename the domain property to `content` and change its type from `Data` to `AnyCodable`
(or `[String: AnyCodable]`) so it matches the protocol definition. Update `ActivityMessageDTO`
and `MessageEncoder.encodeActivityMessage()` accordingly.

> Note: this is a **breaking public API change** — existing callers using `.activityContent` must
> be updated. Grep for `.activityContent` across `Sources/`, `Tests/`, and `Examples/` before
> committing.

---

### Bug 6 — Fire-and-forget `Task` leaks in AbstractAgent, AgUiAgent, and ToolExecutionManager

**Files:**
- `Sources/AGUIClient/AbstractAgent.swift:123` — `Task { await self.storage.setCurrentTask(nil) }`
  inside a `defer` block
- `Sources/AGUIClient/AbstractAgent.swift:174` — `Task { await storage.currentTask?.cancel() }`
  in `abortRun()`
- `Sources/AGUIClient/AbstractAgent.swift:178` — `Task { await storage.setDisposed(true) }`
  in `dispose()`
- `Sources/AGUIAgentSDK/AgUiAgent.swift:164` — `Task { await manager.cancelAllExecutions() }`
  in `close()`
- `Sources/AGUITools/Core/ToolExecutionManager.swift:163` — `let execTask = Task { await self.executeToolCall(...) }`
  created but never stored or awaited — **confirmed fire-and-forget leak**

> Note: `ChunkTransformer` and `EventVerifier` are NOT affected — both store their `Task` and
> cancel it via `continuation.onTermination`. Only the five sites above need fixing.

These are called from synchronous functions. Fire-and-forget `Task { }` has no structured
lifetime — if the enclosing object is deallocated before the task runs, behaviour is undefined.

**Fix:** Make `abortRun()`, `dispose()`, and `close()` `async` and `await` the actor calls
directly. For `ToolExecutionManager`, store `execTask` in a dictionary keyed by tool call ID so
it can be cancelled via `cancelAllExecutions()`.

```swift
// Before
public func abortRun() {
    Task { await storage.currentTask?.cancel() }
}

// After — callers must be updated to await
public func abortRun() async {
    await storage.currentTask?.cancel()
}
```

If making these `async` is a breaking API change, add `@discardableResult` internal async
variants and deprecate the synchronous wrappers with a migration note.

**Call-site audit:** grep for `.abortRun()`, `.dispose()`, `.close()` across `Sources/`,
`Tests/`, and `Examples/ChatApp` and update each call site to `await`.

---

### Bug 7 — Simple 1:1 DTOs add maintenance cost without benefit (H12)

The reviewer correctly identified that simple events whose DTOs are verbatim field copies with no
wire-to-domain transformation add ~15 files of indirection with no engineering return. The fix is
not to eliminate the DTO pattern (it is necessary for complex events), but to let the simple
domain types conform to `Decodable` directly and delete the DTO shim.

**DTOs to collapse** (confirmed 1:1 passthrough, no transformation):

| DTO File | Domain Type |
|----------|-------------|
| `TextMessageStartEventDTO.swift` | `TextMessageStartEvent` |
| `TextMessageContentEventDTO.swift` | `TextMessageContentEvent` |
| `ToolCallStartEventDTO.swift` | `ToolCallStartEvent` |
| `ToolCallArgsEventDTO.swift` | `ToolCallArgsEvent` |
| `AssistantMessageDTO.swift` | `AssistantMessage` |
| `SystemMessageDTO.swift` | `SystemMessage` |
| `DeveloperMessageDTO.swift` | `DeveloperMessage` |

**DTOs to keep** (complex mapping or JSONSerialization required):

| DTO File | Reason to Keep |
|----------|---------------|
| `UserMessageDTO.swift` | Multimodal InputContent parsing |
| `ActivityMessageDTO.swift` | JSONSerialization for arbitrary content |
| `RunStartedEventDTO.swift` | Manual JSON parsing, `input` → `Data` transform |
| `CustomEventDTO.swift` | `name`→`customType`, `value`→`data` wire renaming |
| `RawEventDTO.swift` | `event` key → `Data`, untyped payload |
| All reasoning/lifecycle DTOs with optional fields | Non-trivial null handling |

**Fix per DTO:**
1. Add `CodingKeys` enum and `Decodable` conformance to the domain type.
2. Delete the DTO `.swift` file.
3. Update the event/message decoder registry handler to decode the domain type directly
   (replace `try SomeDTO.decode(from: data).toDomain()` with
   `try JSONDecoder().decode(DomainType.self, from: data)`).

**Verify:** `swift build && swift test`

---

### Bug 8 — CI: SwiftLint disabled, no Linux build, single-version matrix

**File:** `.github/workflows/ci.yml`

SwiftLint is explicitly commented out. No Linux target is in the matrix. The reviewer flagged
this; the CLAUDE.md pre-commit checklist requires `swiftlint lint` before every commit.

**Fix:**
1. Re-enable SwiftLint in the `lint` CI job (install via Homebrew on `macos-latest`; run
   `swiftlint lint --strict`).
2. Add a `build-linux` job using `swift:latest` Docker image (or `ubuntu-latest` with Swift
   toolchain) to catch Linux-incompatible Foundation APIs.
3. Optionally add `swift-5.9` and `swift-5.10` to the matrix to guard minimum version support.

---

## Test Coverage Gaps — TDD Required

| Gap | Reviewer Issue | Scope | New File(s) |
|-----|---------------|-------|-------------|
| A — Reasoning events | — | 7 event types + `ReasoningMessage` | `Tests/AGUICoreTests/ReasoningEvents/*.swift` + `ReasoningMessageTests.swift` |
| B — `MessageEncoder` | H15 | All 7 roles (`.reasoning` added by Bug 1) | `Tests/AGUICoreTests/Encoding/MessageEncoderTests.swift` |
| C — `StatefulAgUiAgent` | H13 | History, state, multi-tool regression | `Tests/AGUIAgentSDKTests/StatefulAgUiAgentTests.swift` |
| D — `ToolExecutionManager` | H14 | Stream forwarding, retry, circuit-open, concurrency, task cancellation | `Tests/AGUIToolsTests/Core/ToolExecutionManagerTests.swift` |
| E — `StepFinishedEvent` | H15 | Decode, fields, eventType | `Tests/AGUICoreTests/LifeCycleEvents/StepFinishedEventTests.swift` |
| F — `RunFinishedEvent` outcome | — | New outcome decode cases (after Bug 2) | Extend `RunFinishedEventTests.swift` |

---

## Commit Groups

### Commit 0 — `fix: remove dead AgentConfig types and connectTimeout`
**Independent — do first, smallest change, unblocks H11 response to reviewer**

1. Delete `Sources/AGUIClient/AgentConfig.swift` entirely (`AgentConfig`, `HttpAgentConfig`,
   `RunAgentParameters` — all unreferenced).
2. Remove `connectTimeout: TimeInterval` from `Sources/AGUIAgentSDK/AgUiAgentConfig.swift`.
3. Remove `connectTimeout: TimeInterval` from `Sources/AGUIAgentSDK/StatefulAgUiAgentConfig.swift`
   (verify it is present first).
4. Run `swift build` — must pass with zero errors.
5. No test changes needed (these types have no tests because they are dead code).

**Verify:** `swift build && swift test`

---

### Commit 1 — `fix: add mimeType to media input content types`
**Independent**

**Red — extend existing test files:**
- `Tests/AGUICoreTests/Types/InputContent/ImageInputContentTests.swift`
- `Tests/AGUICoreTests/Types/InputContent/AudioInputContentTests.swift`
- `Tests/AGUICoreTests/Types/InputContent/VideoInputContentTests.swift`
- `Tests/AGUICoreTests/Types/InputContent/DocumentInputContentTests.swift`

Add cases: `mimeType` round-trips JSON encode/decode; `mimeType` nil when absent.

**Green:**
1. Add `mimeType: String?` to `ImageInputContent`, `AudioInputContent`, `VideoInputContent`,
   `DocumentInputContent` — init param defaulted to `nil`, add to `CodingKeys`, encode/decode.
2. Update 4 DTOs: pass `mimeType` through in `toDomain()`.
3. Update `MessageEncoder.encodeUserMessage()`: add `d["mimeType"] = mimeType` where non-nil for
   each media content block.

**Verify:** `swift test --filter InputContentTests`

---

### Commit 2 — `fix: add .reasoning handler to MessageEncoder`
**Independent**

**Red — new file:** `Tests/AGUICoreTests/Encoding/MessageEncoderTests.swift`

Initial cases (`.reasoning` only, to fail fast):
```
test_encodeReasoningMessage_producesCorrectJSON()
test_encodeReasoningMessage_withEncryptedValue()
test_encodeReasoningMessage_contentNilOmitted()
test_unsupportedRole_throws()
```

**Green:**
1. Add `encodeReasoningMessage(_ message: any Message, encoder: JSONEncoder) throws -> Data`
   — builds dict: `id`, `role`, `content?`, `name?`, `encryptedValue?`, returns
   `JSONSerialization.data(withJSONObject:)`. Mirrors `encodeAssistantMessage()`.
2. Register in `defaultRegistry()` under `.reasoning`.
3. Update doc comment: "all 6 message types" → "all 7 message types".

**Verify:** `swift test --filter MessageEncoderTests`

---

### Commit 3 — `test: add reasoning event test suite`
**Independent — no production changes**

**New directory:** `Tests/AGUICoreTests/ReasoningEvents/`

**New files:**
- `ReasoningStartEventTests.swift`
- `ReasoningMessageStartEventTests.swift`
- `ReasoningMessageContentEventTests.swift`
- `ReasoningMessageEndEventTests.swift`
- `ReasoningMessageChunkEventTests.swift`
- `ReasoningEndEventTests.swift`
- `ReasoningEncryptedValueEventTests.swift`

Each file covers:
- Decode valid JSON → correct domain struct (`AGUIEventDecoderTestHelpers`)
- `eventType` returns correct `EventType` case
- Required fields round-trip
- Optional fields (`timestamp`, `rawEvent`) decode when present, nil when absent
- Missing required field throws `DecodingError`
- `ReasoningEncryptedValueEvent`: both `subtype` values (`"tool-call"`, `"message"`) decode
  correctly; `entityId` + `encryptedValue` are required

**New file:** `Tests/AGUICoreTests/Types/Messages/ReasoningMessageTests.swift`
- `role` is `.reasoning`, `encryptedValue` round-trips, `content` optional.

**Pattern:** follow `Tests/AGUICoreTests/TextMessageEvents/TextMessageStartEventTests.swift`.

**Verify:** `swift test --filter ReasoningEvents`

---

### Commit 4 — `test: add StepFinishedEvent tests`
**Independent — no production changes**

**New file:** `Tests/AGUICoreTests/LifeCycleEvents/StepFinishedEventTests.swift`

Mirror `StepStartedEventTests.swift` exactly — same structure, same cases, different type.

**Verify:** `swift test --filter StepFinishedEventTests`

---

### Commit 5 — `refactor: collapse simple 1:1 DTOs to direct Decodable conformance`
**Independent — can run in parallel with Commits 1–4**

Addresses H12. Reduces DTO file count by ~7 files without removing the pattern for complex events.

**Red — for each domain type being made Decodable, verify existing tests still decode correctly
after the change. No new test files needed; test breakage = regression.**

**Green — for each of the 7 DTOs listed in Bug 8:**
1. Add `CodingKeys` enum to the domain type if not present.
2. Add `Decodable` init (or synthesised conformance if field names match wire exactly).
3. Update the decoder registry handler: replace `DomainDTO.decode(from: data).toDomain()` with
   `try JSONDecoder().decode(DomainType.self, from: data)`.
4. Delete the DTO `.swift` file.

**Order matters within this commit** — do one type at a time, run `swift build` between each to
catch registry call-site errors immediately.

**Verify:** `swift build && swift test`

---

### Commit 6 — `fix: rename ActivityMessage.activityContent to content`
**Independent — can run in parallel with Commits 1–4**

**Files:**
- `Sources/AGUICore/Types/Messages/ActivityMessage.swift`
- `Sources/AGUICore/Decoding/MessageDTO/ActivityMessageDTO.swift`
- `Sources/AGUICore/Encoding/MessageEncoder.swift` — `encodeActivityMessage()`

**Red — update or add test:**
```
test_activityMessage_contentFieldRoundTrips()
test_activityMessage_wireKeyIsContent()
```

**Green:**
1. Rename domain property `activityContent: Data` → `content: AnyCodable` (use `AnyCodable` or
   `[String: AnyCodable]` to match `Record<string, any>`).
2. Update `ActivityMessageDTO.toDomain()` to populate the renamed field.
3. Update `MessageEncoder.encodeActivityMessage()` to read `message.content`.
4. Grep for `.activityContent` across `Sources/`, `Tests/`, `Examples/` — update every callsite.

**Verify:** `swift build && swift test`

---

### Commit 7 — `fix: add RunFinishedOutcome to RunFinishedEvent`
**Begin after Commits 1–6 CI is green (no code dependency, just stability gate)**

**Red — extend** `Tests/AGUICoreTests/LifeCycleEvents/RunFinishedEventTests.swift`:
```
test_decode_withSuccessOutcome()
test_decode_withInterruptOutcome_singleInterrupt()
test_decode_withInterruptOutcome_multipleInterrupts()
test_decode_withoutOutcome_isNil()
test_interrupt_valueField_isOptional()
```

**Green:**

New types (same file or sibling `RunFinishedOutcome.swift`):
```swift
public struct Interrupt: Equatable, Hashable, Sendable, Codable {
    public let type: String
    public let value: Data?   // raw JSON — arbitrary shape
}

public enum RunFinishedOutcome: Equatable, Hashable, Sendable {
    case success
    case interrupt(interrupts: [Interrupt])
}
```

`RunFinishedEvent`: add `public let outcome: RunFinishedOutcome?`; append
`outcome: RunFinishedOutcome? = nil` to init → **zero call-site breakage**.

DTO update (`RunFinishedEventDTO`):
- Read `outcome` dict → `type` key
- `"success"` → `.success`
- `"interrupt"` → decode `interrupts` array → `.interrupt(interrupts:)`
- `Interrupt.value`: decode as `Any` via `JSONSerialization`, re-serialise to `Data`

**Equatable/Hashable:** synthesised automatically — no manual conformance needed.

**Verify:** `swift test --filter RunFinishedEventTests`

---

### Commit 8 — `test: add ToolExecutionManager test suite`
**Can run in parallel with Commits 7, 9, and 10**

**New file:** `Tests/AGUIToolsTests/Core/ToolExecutionManagerTests.swift`

Check for `MockToolRegistry` / `MockToolResponseHandler` in `Tests/AGUIToolsTests/`; create in
`Mocks/` if absent.

**Test cases:**
```
test_processEventStream_forwardsAllEvents()
test_toolCallStartArgsEnd_buildsCorrectToolCall()
test_toolCallEnd_triggersRegistryExecution()
test_successfulExecution_sendsToolMessageViaResponseHandler()
test_executionEvents_startedExecutingSucceeded_emittedInOrder()
test_retryOnTransientError_retrysUpToMaxAttempts()
test_circuitOpen_sendsErrorToolMessage_emitsFailedEvent()
test_cancelAllExecutions_cancelsInFlightTasks()
test_multipleToolCalls_allCompleteBeforeStreamTerminates()
test_runFinishedEvent_doesNotCancelPendingExecutions()
test_execTask_storedAndCancelledOnCancelAllExecutions()  // regression for Bug 6 fix
```

`ToolExecutionManager` is an `actor` — all test interaction uses `await`.
Inject controlled event sequences via `AsyncThrowingStream`.

**Verify:** `swift test --filter ToolExecutionManagerTests`

---

### Commit 9 — `test: expand MessageEncoder tests to all 7 roles`
**Can run in parallel with Commits 7, 8, and 10**

Expand `Tests/AGUICoreTests/Encoding/MessageEncoderTests.swift` (created in Commit 2):

```
test_encodeDeveloperMessage_requiredFields()
test_encodeSystemMessage_optionalContentOmitted()
test_encodeUserMessage_textContent()
test_encodeUserMessage_multimodalContent_image_withMimeType()   // uses Commit 1
test_encodeUserMessage_multimodalContent_audio()
test_encodeUserMessage_multimodalContent_video()
test_encodeUserMessage_multimodalContent_document()
test_encodeUserMessage_multimodalContent_binary()
test_encodeAssistantMessage_withToolCalls()
test_encodeAssistantMessage_encryptedValue()
test_encodeToolMessage_withError()
test_encodeToolMessage_encryptedValue()
test_encodeActivityMessage_contentFieldName()                    // wire key is "content"
test_encodeActivityMessage_arbitraryShape()
test_invalidMessageType_throws()
```

**Verify:** `swift test --filter MessageEncoderTests`

---

### Commit 10 — `fix: eliminate unstructured Task leaks`
**Can run in parallel with Commits 7, 8, and 9**

**Files:**
- `Sources/AGUIClient/AbstractAgent.swift`
- `Sources/AGUIAgentSDK/AgUiAgent.swift`
- `Sources/AGUITools/Core/ToolExecutionManager.swift`

**Changes:**

1. `AbstractAgent.abortRun()` — make `async`, replace `Task { ... }` with direct `await`:
   ```swift
   public func abortRun() async {
       await storage.currentTask?.cancel()
   }
   ```

2. `AbstractAgent.dispose()` — make `async`:
   ```swift
   public func dispose() async {
       await storage.setDisposed(true)
   }
   ```

3. `AbstractAgent.swift:123` — the `defer` block cannot `await`. Move `setCurrentTask(nil)` out
   of `defer` into explicit success/error paths instead.

4. `AgUiAgent.close()` — make `async`:
   ```swift
   public func close() async {
       if let manager = self.toolExecutionManager {
           await manager.cancelAllExecutions()
       }
       await httpAgent.dispose()
   }
   ```

5. `ToolExecutionManager.swift:163` — store `execTask` in a dictionary keyed by tool call ID:
   ```swift
   // Before — fire-and-forget
   let execTask = Task { await self.executeToolCall(...) }

   // After — stored for cancellation
   let execTask = Task { await self.executeToolCall(...) }
   activeTasks[toolCallId] = execTask
   ```
   Update `cancelAllExecutions()` to cancel and remove all entries from `activeTasks`.

**Call-site audit:** grep for `.abortRun()`, `.dispose()`, `.close()` across `Sources/`,
`Tests/`, and `Examples/ChatApp` — update each call site to `await`.

**Verify:** `swift build && swift test`

---

### Commit 11 — `ci: re-enable SwiftLint and add Linux build`
**Can run in parallel with Commits 7, 8, 9, and 10**

**File:** `.github/workflows/ci.yml`

1. Re-enable the SwiftLint step in the `lint` job:
   ```yaml
   - name: Install SwiftLint
     run: brew install swiftlint
   - name: Run SwiftLint
     run: swiftlint lint --strict
   ```
2. Add a `build-linux` job:
   ```yaml
   build-linux:
     runs-on: ubuntu-latest
     container: swift:latest
     steps:
       - uses: actions/checkout@v4
       - run: swift build
       - run: swift test
   ```

**Verify:** Push to branch, confirm CI passes on both macOS and Linux.

---

### Commit 12 — `test: add StatefulAgUiAgent tests`
**Must be last — depends on all prior commits being stable**

**New file:** `Tests/AGUIAgentSDKTests/StatefulAgUiAgentTests.swift`

**Seam strategy:** `StatefulAgUiAgent` hard-constructs `HttpAgent` internally with no injectable
transport. Use `AgUiAgent` (which accepts `AgentTransport` via its secondary init) to exercise the
shared `trackHistoryAndState` logic. Reuse `CapturingTransport` from `AgUiAgentTests.swift`
(already `internal` scope, accessible within the same test target).

If direct `StatefulAgUiAgent` coverage is required, add a package-internal init accepting
`AgentTransport` behind `@testable import`.

**Test cases:**
```
// History lifecycle
test_chat_appendsUserMessage()
test_textMessageEndEvent_appendsAssistantMessage()
test_textMessageEnd_appendsOnlyOnce_notAtContent()

// CRITICAL regression — H7
test_multiToolCallSequence_appendsAssistantMessageExactlyOnce()
// Sequence: ToolCallStart×2 → ToolCallArgs×2 → ToolCallEnd×2 → ToolCallResult×1
// Assert: history contains exactly 1 AssistantMessage

// Tool result
test_toolCallResultEvent_appendsToolMessage()

// State management
test_stateSnapshotEvent_updatesState()
test_stateDeltaEvent_appliesJsonPatch()
test_messagesSnapshotEvent_replacesHistory()

// Thread isolation
test_separateThreadIds_haveIndependentHistories()

// System prompt
test_firstMessage_prependsSystemPrompt()
test_secondMessage_doesNotDuplicateSystemPrompt()

// History trim
test_historyExceedsMaxLength_isTrimmed()

// Clear
test_clearHistory_specificThread()
test_clearHistory_allThreads()

// ActivityMessage content field (regression for Bug 6)
test_activityMessage_exposesDotContent_notDotActivityContent()
```

**Verify:** `swift build && swift test` (full suite — confirm zero regressions)

---

## Parallelism Map

```
Commit 0: Dead code removal (AgentConfig, HttpAgentConfig, connectTimeout) ✓ DONE
                      │
                      ▼  (must be green before anything else)
┌─ Commit 1:  mimeType on InputContent              ─┐
├─ Commit 2:  MessageEncoder .reasoning              ─┤
├─ Commit 3:  Reasoning event tests                  ─┤  All independent
├─ Commit 4:  StepFinishedEvent tests                ─┤  Run in parallel
├─ Commit 5:  Collapse simple 1:1 DTOs (H12)         ─┤
└─ Commit 6:  ActivityMessage content field          ─┘
                      │
                      ▼  (all green)
          Commit 7: RunFinishedOutcome
                      │
       ┌──────────────┼──────────────┬──────────────┐
       ▼              ▼              ▼              ▼
  Commit 8:      Commit 9:     Commit 10:     Commit 11:
  ToolExecution  Encoder        Task leak      CI
  Manager tests  full suite     cleanup        improvements
       └──────────────┬──────────────┴──────────────┘
                      ▼
         Commit 12: StatefulAgUiAgent tests
```

---

## Ripple Effect Register

| Change | Call sites affected | Mitigation |
|--------|---------------------|------------|
| Delete `AgentConfig` and `HttpAgentConfig` from `AgentConfig.swift`; move `RunAgentParameters` to `RunAgentParameters.swift` | None — dead types had no external callers in Sources/Tests | ✓ Done — `swift build` confirmed |
| Remove `connectTimeout` from `AgUiAgentConfig` | Any callsite reading `.connectTimeout` | ✓ Done — grep confirmed no callsites outside definition files |
| `Image/Audio/Video/DocumentInputContent` add `mimeType` | 4 DTOs (`toDomain()`), `MessageEncoder.encodeUserMessage()` | Covered in Commit 1; `mimeType` defaults `nil` — no existing callers break |
| `MessageEncoder.defaultRegistry()` add `.reasoning` | All `MessageEncoder()` consumers | Additive only — no breakage |
| Collapse 7 DTOs | Decoder registry handlers for each collapsed event type | Update each handler in same commit; run `swift build` between each |
| `ActivityMessage.activityContent` → `content` | All `.activityContent` references in Sources, Tests, Examples | **Breaking change** — grep first, update all callsites in same commit |
| `RunFinishedEvent` add `outcome` | All `RunFinishedEvent(...)` call sites | `outcome` defaults `nil` — zero breakage |
| New `RunFinishedOutcome` + `Interrupt` types | `Equatable`/`Hashable` synthesis on `RunFinishedEvent` | Automatic synthesis — no manual conformance |
| `abortRun()`, `dispose()`, `close()` become `async` | All call sites in `Sources/`, `Tests/`, `Examples/ChatApp` | Audit with grep before committing; update each call site to `await` |
| `ToolExecutionManager` stores `execTask` in dictionary | `cancelAllExecutions()` must drain the dictionary | Covered in Commit 10; add regression test in Commit 8 |

---

## Pre-Commit Checklist

Run after each commit group before pushing:

```bash
swift build
swift test
swift package plugin --allow-writing-to-package-directory swiftformat
swiftlint lint
```

---

## Commit Message Format

```
fix: remove dead AgentConfig types and connectTimeout           ← Commit 0 ✓
fix: add mimeType to media input content types                  ← Commit 1
fix: add .reasoning handler to MessageEncoder                   ← Commit 2
test: add reasoning event test suite                            ← Commit 3
test: add StepFinishedEvent tests                               ← Commit 4
refactor: collapse simple 1:1 DTOs to direct Decodable conformance ← Commit 5
fix: rename ActivityMessage.activityContent to content          ← Commit 6
fix: add RunFinishedOutcome to RunFinishedEvent                 ← Commit 7
test: add ToolExecutionManager test suite                       ← Commit 8
test: expand MessageEncoder tests to all 7 roles                ← Commit 9
fix: eliminate unstructured Task leaks in AbstractAgent, AgUiAgent, ToolExecutionManager ← Commit 10
ci: re-enable SwiftLint and add Linux build                     ← Commit 11
test: add StatefulAgUiAgent tests                               ← Commit 12
```

---

## PR Comment Responses Required

**H11 — Config type proliferation:** After Commit 0, only 3 config types remain, each at a
distinct layer (`HttpAgentConfiguration` at transport, `AgUiAgentConfig` at agent,
`StatefulAgUiAgentConfig` at stateful agent). The dead `AgentConfig`/`HttpAgentConfig` types
have been removed. Explain the layered architecture rationale.

**H12 — DTO layer:** Addressed in Commit 5. The 7 simple 1:1 DTOs (TextMessageStartEvent,
TextMessageContentEvent, ToolCallStartEvent, ToolCallArgsEvent, AssistantMessage, SystemMessage,
DeveloperMessage) now conform to `Decodable` directly — the DTO shim has been removed for these.
Complex DTOs (UserMessage, ActivityMessage, CustomEvent, RawEvent, RunStartedEvent) are retained
where JSONSerialization or wire-to-domain field mapping is genuinely required.
