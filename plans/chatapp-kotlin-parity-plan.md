# ChatApp Kotlin Compose Parity — Implementation Plan

## Overview

This plan brings the Swift iOS ChatApp example to full feature parity with the Kotlin Compose `chatapp` reference implementation. Eight features are missing from the Swift example that the Kotlin version ships. They are grouped into five sequenced phases based on architectural dependencies.

**Target:** `Examples/ChatApp/` — SwiftUI iOS chat client  
**Swift:** 5.9+, iOS 16+, `@MainActor`, `async/await`  
**Constraint:** No new third-party dependencies — `PatchApplicator` (already in `AGUIClient`) covers RFC 6902 JSON patch

---

## Gap Summary

| # | Feature | Status in Swift iOS | Status in Kotlin Compose |
|---|---------|--------------------|-----------------------|
| 1 | Typed ephemeral slots | Single shared slot | Typed `TOOL_CALL` / `STEP` slots with different dismiss timings |
| 2 | Supplemental messages | Not implemented | Connection status + errors as in-chat messages |
| 3 | Optimistic user messages | Not implemented | Shown immediately, correlated on `MessagesSnapshot` |
| 4 | `ToolCallArgsEvent` | Not handled | Streamed args preview, truncated at 80 chars |
| 5 | Message animations | Basic default | 200ms fade-in on messages, shimmer on ephemeral |
| 6 | Client-side tool execution | Not implemented | `ChangeBackgroundToolExecutor` via `ToolExecutor` registry |
| 7 | A2UI / Generative UI | Not implemented | Full 18-component rendering, JSON patch, user action routing |
| 8 | ClawgUI enterprise pairing | Not implemented | 6-state machine with pairing dialogs |

---

## Key Architectural Findings

1. **`PatchApplicator` already exists** in `AGUIClient` — full RFC 6902 (add, remove, replace, move, copy, test). Import via `AGUIClient` in ChatApp. No reimplementation needed.
2. **All SDK event types exist** — `ToolCallArgsEvent`, `ActivitySnapshotEvent`, `ActivityDeltaEvent`, `StateSnapshotEvent`, `StateDeltaEvent` are already decoded by the SDK. This is a ChatApp-layer implementation only.
3. **`buildAgent()` must become `async`** — injecting the tool registry requires `await registry.register(...)`. This is the only breaking change to the store's call sites.
4. **`processEvent()` will grow to ~20 cases** — extract into extension files by domain to keep `ChatAppStore.swift` under 500 lines.
5. **TDD is mandatory** — write failing tests first for every feature before implementation (per `CLAUDE.md`).

---

## Execution Order & Parallelism

```
Phase 1: State Foundation  ← MUST LAND FIRST (blocker)
    1A  Typed ephemeral slots
    1B  Supplemental messages
    1C  Optimistic user messages

Phase 2: Tool Pipeline  ← after Phase 1
    2A  ToolCallArgsEvent
    2B  Client-side tool execution (ChangeBackgroundToolExecutor)

Phase 3: Animations  ← after Phase 1, parallel with Phase 2

Phase 4: A2UI / Generative UI  ← after Phase 1, parallel with Phases 2 & 3
    Internal order: A2UIComponent → SurfaceStateManager → store wiring → component views → surface view

Phase 5: ClawgUI Pairing  ← independent after Phase 1, parallel with all others
```

Phases 2, 3, 4, and 5 can be distributed across developers simultaneously once Phase 1 is merged. Phase 4 is ~3–4× the effort of any other phase.

---

## Phase 1 — State Foundation

**Rationale:** All 8 features eventually touch `ChatUIState`, `DisplayMessage`, or `sendMessage`. Settling the state model first avoids two breaking passes through the same files. Phase 1 is the only hard blocker.

### 1A — Typed Ephemeral Slots

**Problem:** `ChatUIState.ephemeralMessage` is a single `DisplayMessage?`. The Kotlin implementation uses a typed map with separate dismiss timings per slot (`TOOL_CALL` → 1s, `STEP` → immediate).

#### Files to Create

**`Sources/Models/EphemeralSlot.swift`** (new)
```swift
enum EphemeralSlot: Hashable, CaseIterable, Comparable, Sendable {
    case toolCall  // dismiss after 1 second
    case step      // dismiss immediately on StepFinished

    var displayPriority: Int {
        switch self {
        case .step:     return 0
        case .toolCall: return 1
        }
    }

    var dismissDelay: Duration? {
        switch self {
        case .toolCall: return .seconds(1)
        case .step:     return nil  // immediate
        }
    }
}
```

#### Files to Modify

**`Sources/Models/ChatUIState.swift`**
- Replace `var ephemeralMessage: DisplayMessage?` with `var ephemeralSlots: [EphemeralSlot: DisplayMessage]`
- Update `init` default to `ephemeralSlots: [:]`

**`Sources/Store/ChatAppStore.swift`**
- `ephemeralDismissTask: Task<Void, Never>?` → `private var ephemeralDismissTasks: [EphemeralSlot: Task<Void, Never>] = [:]`
- Rewrite `showEphemeral(_:)` → `private func showEphemeral(_ message: DisplayMessage, slot: EphemeralSlot)`
- Rewrite `scheduleEphemeralDismissal()` → `private func scheduleEphemeralDismissal(for slot: EphemeralSlot)`
- `ToolCallStartEvent` → `showEphemeral(..., slot: .toolCall)`
- `ToolCallEndEvent` → `scheduleEphemeralDismissal(for: .toolCall)`
- `StepStartedEvent` → `showEphemeral(..., slot: .step)`
- `StepFinishedEvent` → `state.ephemeralSlots[.step] = nil` (immediate, no delay)
- `defer` block in `sendMessage` → clear all slots: `state.ephemeralSlots.removeAll()`

**`Sources/Views/ChatView.swift`**
- Replace `if let ephemeral = state.ephemeralMessage` with:
  ```swift
  ForEach(
      EphemeralSlot.allCases
          .sorted(by: { $0.displayPriority < $1.displayPriority })
          .compactMap { state.ephemeralSlots[$0] },
      id: \.id
  ) { ephemeral in
      EphemeralBanner(message: ephemeral)
  }
  ```
- Update `.animation(...)` value to `state.ephemeralSlots`

#### Tests

Update existing assertions:
- `store.state.ephemeralMessage` → `store.state.ephemeralSlots[.toolCall]` / `[.step]`

New tests:
- `test_bothEphemeralSlotsCoexist` — fire `StepStartedEvent` then `ToolCallStartEvent`, assert both slots populated
- `test_stepFinished_clearsImmediately` — assert `.step` slot is nil immediately after `StepFinishedEvent`
- `test_toolCallEnd_dismissesAfterDelay` — assert `.toolCall` persists for <1s then clears

---

### 1B — Supplemental Messages

**Problem:** Connection status and inline errors exist only as an alert (`state.error`). The Kotlin version renders these as distinct chat messages below the message list.

#### Files to Create

**`Sources/Models/SupplementalMessage.swift`** (new)
```swift
struct SupplementalMessage: Identifiable, Sendable {
    let id: String
    enum Kind: Sendable {
        case connection(agentName: String)
        case error(message: String)
    }
    let kind: Kind
    let timestamp: Date
}
```

**`Sources/Models/ChatRow.swift`** (new) — unified list item for the view
```swift
enum ChatRow: Identifiable, Sendable {
    case agent(DisplayMessage)
    case supplemental(SupplementalMessage)

    var id: String {
        switch self {
        case .agent(let m):        return m.id
        case .supplemental(let s): return s.id
        }
    }

    var timestamp: Date {
        switch self {
        case .agent(let m):        return m.timestamp
        case .supplemental(let s): return s.timestamp
        }
    }
}
```

#### Files to Modify

**`Sources/Models/ChatUIState.swift`**
- Add `var supplementalMessages: [SupplementalMessage] = []`
- Add computed `var chatRows: [ChatRow]` — merges and sorts both lists by timestamp

**`Sources/Store/ChatAppStore.swift`**
- Add `private func appendSupplemental(_ message: SupplementalMessage)`
- On successful agent connection in `buildAgent(from:)` → `appendSupplemental(.init(id: UUID().uuidString, kind: .connection(agentName: config.name), timestamp: .now))`
- `RunErrorEvent` handler → also call `appendSupplemental(.init(..., kind: .error(message: e.error.message), ...))` alongside the existing `state.error` alert assignment
- On `setActiveAgent(id:)` when switching → optionally append "Disconnected from X" supplemental

**`Sources/Views/ChatView.swift`**
- `ForEach` iterates `store.state.chatRows` instead of `state.messages`
- Handle both `ChatRow` cases in the cell builder

#### Tests

- `test_buildAgent_appendsConnectionSupplemental`
- `test_runError_appendsInlineError`
- `test_chatRows_mergesAndSortsByTimestamp`

---

### 1C — Optimistic User Messages

**Problem:** User messages only appear after the agent echoes them back in a `MessagesSnapshotEvent`. The Kotlin version shows them immediately with a "pending" state.

#### Files to Modify

**`Sources/Models/DisplayMessage.swift`**
- Add `var isSending: Bool = false` — indicates pending agent confirmation (user role only)

**`Sources/Store/ChatAppStore.swift`**
- In `sendMessage(_:)`: create user `DisplayMessage` with `isSending: true`; store its id in `private var pendingUserMessageId: String?`
- In `rebuildMessages()` (called from `MessagesSnapshotEvent`):
  1. Parse snapshot into `rebuilt: [DisplayMessage]`
  2. If `pendingUserMessageId != nil`, look for a user message in `rebuilt` with matching content
  3. If found → confirmed, set `pendingUserMessageId = nil`
  4. If not found → prepend the pending message (with `isSending: true`) to `rebuilt`
  5. Assign `state.messages = rebuilt`
- On task cancellation in `cancelStreaming()` → set `isSending = false` on the pending message or remove it, clear `pendingUserMessageId`

**`Sources/Views/MessageBubbleView.swift`**
- For `.user` role, when `message.isSending == true`: show `Image(systemName: "clock").opacity(0.5)` trailing the timestamp label

#### Tests

- `test_sendMessage_optimisticallyShowsUserMessage`
- `test_messagesSnapshot_correlatesAndClearsPending`
- `test_messagesSnapshot_reinjectsPendingIfNotFound`
- `test_cancellation_clearsPendingMessage`

---

## Phase 2 — Tool Pipeline

**Requires:** Phase 1 complete  
**Rationale:** Features 2A and 2B both touch the tool call pipeline and the `buildAgent()` lifecycle. Doing them in the same phase avoids multiple passes through `AgentConfig` and the agent construction path.

### 2A — ToolCallArgsEvent

**Problem:** `ToolCallArgsEvent` is unhandled. The Kotlin version buffers deltas by `toolCallId` and updates the ephemeral tool slot with a truncated args preview.

#### Files to Modify

**`Sources/Store/ChatAppStore.swift`** (or `ChatAppStore+EventProcessing.swift`)

Add:
```swift
private var toolCallArgBuffer: [String: String] = [:]
```

Update `processEvent` switch:
```swift
// In ToolCallStartEvent handler — initialize buffer:
toolCallArgBuffer[e.toolCallId] = ""

// New case:
case let e as ToolCallArgsEvent:
    toolCallArgBuffer[e.toolCallId, default: ""] += e.delta
    let summary = summarizeArguments(toolCallArgBuffer[e.toolCallId] ?? "")
    if var msg = state.ephemeralSlots[.toolCall] {
        msg.content = summary
        state.ephemeralSlots[.toolCall] = msg
    }

// In ToolCallEndEvent handler — clear buffer entry:
toolCallArgBuffer.removeValue(forKey: e.toolCallId)
```

Add helper:
```swift
private func summarizeArguments(_ json: String) -> String {
    let trimmed = json.trimmingCharacters(in: .whitespaces)
    guard trimmed.count > 80 else { return trimmed }
    return String(trimmed.prefix(80)) + "…"
}
```

Clear `toolCallArgBuffer` in `finishStreamingMessages()` and `setActiveAgent(id:)`.

**Important:** `DisplayMessage` is a value type. Always write back the full keypath:
```swift
state.ephemeralSlots[.toolCall] = msg  // not a mutation on the retrieved copy
```

#### Tests

- `test_toolCallArgs_updatesEphemeralContent`
- `test_toolCallArgs_multipleDeltas_concatenate`
- `test_toolCallArgs_truncatesAt80Chars`
- `test_toolCallEnd_clearsArgBuffer`

---

### 2B — Client-Side Tool Execution

**Problem:** `ChangeBackgroundToolExecutor` does not exist in the Swift example. The Kotlin version registers it via `ToolExecutor` / `DefaultToolRegistry`, and the `ToolExecutionManager` middleware intercepts tool events and executes locally.

#### Files to Create

**`Sources/Tools/ChangeBackgroundToolExecutor.swift`** (new)
```swift
actor ChangeBackgroundToolExecutor: ToolExecutor {
    // Tool definition
    let tool: Tool = Tool(
        name: "change_background",
        description: "Changes the chat background color",
        parameters: /* JSON schema: { color: { type: string, description: hex color } } */
    )

    private let onBackground: @Sendable (String) async -> Void

    init(onBackground: @escaping @Sendable (String) async -> Void) {
        self.onBackground = onBackground
    }

    func execute(context: ToolExecutionContext) async throws -> ToolExecutionResult {
        // Decode {"color": "#RRGGBB"} or {"hex": "#RRGGBB"} from context.toolCall arguments
        // Validate hex format
        // Call onBackground(hex)
        // Return .success(message: "Background updated to \(hex)")
    }

    nonisolated func validate(toolCall: ToolCall) -> ToolValidationResult {
        // Check arguments JSON contains a valid hex color field
    }
}
```

**`Sources/Tools/ChatAppToolRegistry.swift`** (new)
```swift
enum ChatAppToolRegistry {
    static func makeRegistry(
        onBackground: @escaping @Sendable (String) async -> Void
    ) async throws -> any ToolRegistry {
        let registry = DefaultToolRegistry()
        let executor = ChangeBackgroundToolExecutor(onBackground: onBackground)
        try await registry.register(executor: executor)
        return registry
    }
}
```

#### Files to Modify

**`Sources/Models/AgentConfig.swift`**
- `toStatefulAgentConfig()` gains optional parameter:
  ```swift
  func toStatefulAgentConfig(toolRegistry: (any ToolRegistry)? = nil) throws -> StatefulAgUiAgentConfig {
      var sdkConfig = ...
      sdkConfig.toolRegistry = toolRegistry
      return sdkConfig
  }
  ```

**`Sources/Store/ChatAppStore.swift`**
- `buildAgent(from:)` becomes `private func buildAgent(from config: AgentConfig) async`
- All callers wrapped: `Task { await self.buildAgent(from: config) }`
- Body:
  ```swift
  let registry = try? await ChatAppToolRegistry.makeRegistry(
      onBackground: { [weak self] hex in
          await MainActor.run { self?.state.backgroundHex = hex }
      }
  )
  let sdkConfig = try config.toStatefulAgentConfig(toolRegistry: registry)
  agent = StatefulAgUiAgent(configuration: sdkConfig)
  ```
- The existing `handleCustomEvent` for `change_background` in `processEvent` is retained for backward compatibility when the server sends a `CustomEvent` instead of executing the tool locally

**Extract:** `Sources/Store/ChatAppStore+EventProcessing.swift` (new) — move `processEvent(_:)` and all private helpers (`showEphemeral`, `scheduleEphemeralDismissal`, `rebuildMessages`, `summarizeArguments`, `handleCustomEvent`) here. `ChatAppStore.swift` retains only agent lifecycle and agent management methods.

#### Tests

- `test_changeBackgroundTool_parsesHexAndCallsBack`
- `test_changeBackgroundTool_validate_rejectsInvalidHex`
- `test_toolRegistry_registersExecutor`
- `test_buildAgent_injectsToolRegistry`

---

## Phase 3 — Message Animations

**Requires:** Phase 1 complete (ephemeral refactor changes `EphemeralBanner` structure)  
**Parallel with:** Phase 2

**Problem:** Messages appear instantly. The Kotlin version uses a 200ms ease-in fade on regular messages and a moving shimmer gradient on ephemeral banners.

#### Files to Create

**`Sources/Views/ShimmerModifier.swift`** (new)
```swift
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.5), .clear],
                        startPoint: .init(x: phase, y: 0.5),
                        endPoint:   .init(x: phase + 0.5, y: 0.5)
                    )
                    .blendMode(.screen)
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                .clipped()
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.2).repeatForever(autoreverses: false)
                ) { phase = 1 }
            }
    }
}

extension View {
    func shimmer() -> some View { modifier(ShimmerModifier()) }
}
```

#### Files to Modify

**`Sources/Views/MessageBubbleView.swift`**
```swift
// Add local state:
@State private var appeared = false

// Add to bubble container:
.opacity(appeared ? 1 : 0)
.onAppear {
    withAnimation(.easeIn(duration: 0.2)) { appeared = true }
}
```

**`Sources/Views/ChatView.swift`**
- `ForEach` animation: change `.default` → `.easeIn(duration: 0.2)` on `value: store.state.chatRows.count`
- Ephemeral banner stack: `.animation(.easeIn(duration: 0.8), value: state.ephemeralSlots)`
- Apply `.shimmer()` to each `EphemeralBanner` body

#### Notes

- `LazyVStack` triggers `.onAppear` reliably for newly inserted items. The `ForEach`-level `value:` animation handles list insertions; the per-bubble `onAppear` handles the individual fade. Both are needed.
- Use `#Preview` macros to visually verify both animations before merging.

---

## Phase 4 — A2UI / Generative UI

**Requires:** Phase 1 complete  
**Parallel with:** Phases 2, 3, and 5  
**Effort:** ~3–4× any other single phase — treat as a sub-project

**Problem:** The Swift example has no `ActivitySnapshotEvent` / `ActivityDeltaEvent` handling. The Kotlin version renders 18 component types with live JSON patch updates and routes user actions back to the agent.

### Internal Implementation Order

Build in this sequence so each step is independently testable:

1. `A2UIComponent` enum + decoder
2. `A2UISurfaceStateManager` + `PatchApplicator` wiring
3. `ChatAppStore` event cases + `ChatUIState` additions
4. `A2UIComponentView` (one component type at a time)
5. `A2UISurfaceView` root renderer
6. `MessageBubbleView` new role case

### Files to Create

**`Sources/A2UI/A2UIComponent.swift`** (new)

Recursive `Decodable` enum. Custom `init(from decoder:)` reads `"type"` discriminator first. Unknown types must **not throw** — use `.unknown` fallback so the app never crashes on new component types.

```swift
indirect enum A2UIComponent: Decodable, Sendable {
    case text(content: String, style: TextStyle?)
    case button(label: String, actionId: String)
    case vStack(children: [A2UIComponent])
    case hStack(children: [A2UIComponent])
    case image(url: URL, altText: String?)
    case divider
    case card(title: String?, children: [A2UIComponent])
    case list(items: [A2UIComponent])
    case badge(label: String, color: String?)
    case textField(placeholder: String, bindingKey: String)
    case toggle(label: String, bindingKey: String, value: Bool)
    case select(label: String, options: [String], bindingKey: String)
    case progress(value: Double, total: Double)
    case markdown(content: String)
    case spacer(height: CGFloat?)
    case chart(spec: Data)
    case table(headers: [String], rows: [[String]])
    case unknown  // fallback — renders nothing
}
```

**`Sources/A2UI/A2UISurfaceStateManager.swift`** (new)

`@MainActor` class (not actor — integrates directly with the store's isolation domain).

```swift
@MainActor final class A2UISurfaceStateManager {
    private var surfaces: [String: Data] = [:]

    /// Replace or initialize surface state from a snapshot event.
    func applySnapshot(_ event: ActivitySnapshotEvent) {
        surfaces[event.messageId] = event.content
    }

    /// Apply RFC 6902 JSON patch delta. Returns updated Data or throws.
    func applyDelta(_ event: ActivityDeltaEvent) throws -> Data {
        guard let current = surfaces[event.messageId] else { throw A2UIError.surfaceNotFound }
        let patchApplicator = PatchApplicator()
        let updated = try patchApplicator.apply(patch: event.patch, to: current)
        surfaces[event.messageId] = updated
        return updated
    }

    func surfaceData(for messageId: String) -> Data? { surfaces[messageId] }
    func reset() { surfaces.removeAll() }
}
```

**`Sources/Views/A2UI/A2UIComponentView.swift`** (new)

Recursive SwiftUI view. User action calls an injected closure — no direct store reference in the view.

```swift
struct A2UIComponentView: View {
    let component: A2UIComponent
    let onAction: (String, [String: Any]) -> Void  // (actionId, payload)

    var body: some View {
        switch component {
        case .text(let content, let style):   Text(content)/* + style */
        case .button(let label, let actionId): Button(label) { onAction(actionId, [:]) }
        case .vStack(let children):           VStack { ForEach(...) { A2UIComponentView(...) } }
        case .hStack(let children):           HStack { ForEach(...) { A2UIComponentView(...) } }
        case .divider:                        Divider()
        case .markdown(let content):          /* MarkdownUI or Text */
        // ... all 18 cases
        case .unknown:                        EmptyView()
        }
    }
}
```

**`Sources/Views/A2UI/A2UISurfaceView.swift`** (new)

Root renderer for one surface, decodes the latest `Data` blob on each render.

```swift
struct A2UISurfaceView: View {
    let messageId: String
    let surfaceData: Data?
    let onAction: (String, String, [String: Any]) -> Void  // (messageId, actionId, payload)

    var body: some View {
        if let data = surfaceData,
           let component = try? JSONDecoder().decode(A2UIComponent.self, from: data) {
            A2UIComponentView(component: component) { actionId, payload in
                onAction(messageId, actionId, payload)
            }
        }
    }
}
```

#### Files to Modify

**`Sources/Models/DisplayMessage.swift`**
- Add new `DisplayMessageRole` case: `.a2uiSurface(messageId: String)`

**`Sources/Models/ChatUIState.swift`**
- Add `var a2uiSurfaces: [String: Data] = [:]`

**`Sources/Store/ChatAppStore+A2UI.swift`** (new extension file)
```swift
extension ChatAppStore {
    func processA2UISnapshot(_ event: ActivitySnapshotEvent) {
        surfaceManager.applySnapshot(event)
        state.a2uiSurfaces[event.messageId] = event.content
        upsertA2UIMessage(messageId: event.messageId)
    }

    func processA2UIDelta(_ event: ActivityDeltaEvent) {
        guard let updated = try? surfaceManager.applyDelta(event) else { return }
        state.a2uiSurfaces[event.messageId] = updated
    }

    private func upsertA2UIMessage(messageId: String) {
        // Insert DisplayMessage(role: .a2uiSurface(messageId:)) if not present
        guard !state.messages.contains(where: { $0.id == "a2ui-\(messageId)" }) else { return }
        let msg = DisplayMessage(id: "a2ui-\(messageId)", role: .a2uiSurface(messageId: messageId), content: "", timestamp: .now)
        state.messages.append(msg)
    }

    func handleA2UIAction(messageId: String, actionId: String, payload: [String: Any]) {
        // Encode and send action back to agent
        let body: [String: Any] = ["messageId": messageId, "action": actionId, "payload": payload]
        guard let data = try? JSONSerialization.data(withJSONObject: body),
              let str = String(data: data, encoding: .utf8) else { return }
        // Send as structured user message — agent interprets the JSON payload
        Task { await sendMessage("[A2UI Action] \(str)") }
    }
}
```

**`Sources/Store/ChatAppStore.swift`** (existing)
- Add `private let surfaceManager = A2UISurfaceStateManager()`
- In `processEvent`, add two new cases:
  ```swift
  case let e as ActivitySnapshotEvent where e.activityType == "a2ui-surface":
      processA2UISnapshot(e)

  case let e as ActivityDeltaEvent where e.activityType == "a2ui-surface":
      processA2UIDelta(e)
  ```
- Clear surfaces in `setActiveAgent(id:)`: `state.a2uiSurfaces.removeAll(); surfaceManager.reset()`

**`Sources/Views/MessageBubbleView.swift`**
- Handle `.a2uiSurface(let messageId)` in the role switch:
  ```swift
  case .a2uiSurface(let messageId):
      A2UISurfaceView(
          messageId: messageId,
          surfaceData: store.state.a2uiSurfaces[messageId]
      ) { mId, actionId, payload in
          store.handleA2UIAction(messageId: mId, actionId: actionId, payload: payload)
      }
  ```

#### Tests

- `test_activitySnapshot_insertsA2UIDisplayMessage`
- `test_activityDelta_updatesA2UIState`
- `test_a2uiComponent_decodesButton`
- `test_a2uiComponent_decodesUnknown_doesNotThrow`
- `test_a2uiSurfaceStateManager_applyDelta_patchesCorrectly`
- `test_a2uiSurfaceStateManager_applyDelta_throwsOnMissingSnapshot`
- Visual `#Preview` for every component type

#### A2UI Risks

| Risk | Mitigation |
|------|-----------|
| Unknown component types crash the app | `.unknown` fallback in enum — never throw in `init(from decoder:)` for unrecognized types |
| `PatchApplicator` API mismatch | Verify public API surface of `PatchApplicator` before starting; fallback: copy it into the ChatApp target |
| Recursive `A2UIComponent` ForEach requires `Identifiable` | Add a computed `var stableId: String` based on position path; or use `.enumerated()` with `id: \.offset` |
| `ActivitySnapshotEvent.replace == false` edge case | Define behavior: merge top-level JSON keys (not deep merge); matches Kotlin behavior |

---

## Phase 5 — ClawgUI Enterprise Pairing

**Requires:** Phase 1 complete  
**Parallel with:** Phases 2, 3, and 4  
**Note:** Pairing protocol HTTP details should be confirmed against the ClawgUI server implementation before coding the network layer.

**Problem:** The Swift example has no detection or handling of ClawgUI gateway endpoints. The Kotlin version implements a 6-state pairing state machine with full UI dialogs.

### State Machine

```
idle ──[clawg-ui URL detected]──► initiating
initiating ──[handshake 403 + pairing info]──► pendingApproval(approvalURL)
initiating ──[HTTP error]──► failed(reason)
pendingApproval ──[user opens URL + confirms]──► awaitingApproval
awaitingApproval ──[poll: 200 OK]──► idle (connected)
awaitingApproval ──[poll timeout]──► retryingConnection
retryingConnection ──[retry succeeds]──► pendingApproval(url)
retryingConnection ──[max retries exhausted]──► failed(reason)
failed ──[user dismisses]──► idle
```

#### Files to Create

**`Sources/ClawgUI/ClawgUIPairingState.swift`** (new)
```swift
enum ClawgUIPairingState: Sendable, Equatable {
    case idle
    case initiating
    case pendingApproval(approvalURL: URL)
    case retryingConnection
    case awaitingApproval
    case failed(reason: String)
}
```

**`Sources/ClawgUI/ClawgUIDetector.swift`** (new)
```swift
struct ClawgUIDetector {
    static func isClawgUIEndpoint(_ urlString: String) -> Bool {
        guard let _ = urlString.range(
            of: #".*/v1/clawg-ui.*"#,
            options: .regularExpression
        ) else { return false }
        return true
    }
}
```

**`Sources/ClawgUI/ClawgUIPairingManager.swift`** (new)

`@MainActor` class owning the state machine. Uses `URLSession` for HTTP handshake. Polling uses `Task` with exponential backoff. `reset()` cancels any in-flight polling task.

```swift
@MainActor final class ClawgUIPairingManager {
    private(set) var pairingState: ClawgUIPairingState = .idle
    private var pollingTask: Task<Void, Never>?
    private let maxRetries = 5

    func initiatePairing(agentURL: URL) async { ... }
    func confirmApproval() { pairingState = .awaitingApproval; startPolling() }
    func retryConnection() async { ... }
    func reset() { pollingTask?.cancel(); pollingTask = nil; pairingState = .idle }
    private func startPolling() { ... }  // exponential backoff, max maxRetries
}
```

**`Sources/Views/ClawgUI/ClawgUIPairingView.swift`** (new)

Sheet modal. Renders different content per state. No business logic — all state transitions via callbacks passed in.

```swift
struct ClawgUIPairingView: View {
    let state: ClawgUIPairingState
    let onConfirm: () -> Void
    let onRetry: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        switch state {
        case .initiating:        InitiatingView()
        case .pendingApproval(let url): PendingApprovalView(url: url, onConfirm: onConfirm, onDismiss: onDismiss)
        case .awaitingApproval:  AwaitingApprovalView(onRetry: onRetry, onDismiss: onDismiss)
        case .retryingConnection: RetryingView()
        case .failed(let reason): FailedView(reason: reason, onDismiss: onDismiss)
        case .idle:              EmptyView()
        }
    }
}
```

#### Files to Modify

**`Sources/Models/ChatUIState.swift`**
- Add `var clawgUIPairingState: ClawgUIPairingState = .idle`

**`Sources/Store/ChatAppStore.swift`** (or `ChatAppStore+ClawgUI.swift`)
- Add `private let pairingManager = ClawgUIPairingManager()`
- Gate `buildAgent(from:)`:
  ```swift
  if ClawgUIDetector.isClawgUIEndpoint(config.url) {
      await pairingManager.initiatePairing(agentURL: agentURL)
      state.clawgUIPairingState = pairingManager.pairingState
      // Only proceed to build StatefulAgUiAgent when pairingState == .idle (success)
      guard pairingManager.pairingState == .idle else { return }
  }
  ```
- Mirror `pairingManager.pairingState` into `state.clawgUIPairingState` on each transition

**`Sources/Views/RootView.swift`**
- Add:
  ```swift
  .sheet(isPresented: Binding(
      get: { store.state.clawgUIPairingState != .idle },
      set: { if !$0 { store.pairingManager.reset() } }
  )) {
      ClawgUIPairingView(
          state: store.state.clawgUIPairingState,
          onConfirm: { store.pairingManager.confirmApproval() },
          onRetry: { Task { await store.pairingManager.retryConnection() } },
          onDismiss: { store.pairingManager.reset() }
      )
  }
  ```

#### Tests

- `test_clawgUIDetector_matchesClawgUIPattern`
- `test_clawgUIDetector_rejectsRegularURLs`
- `test_pairingManager_transitionsToInitiating`
- `test_pairingManager_reset_cancelsPolling`
- State machine unit tests with mocked `URLSession`

#### ClawgUI Risks

| Risk | Mitigation |
|------|-----------|
| Pairing HTTP protocol details unknown | Stub the network layer; implement state machine and UI; leave `initiatePairing` as `TODO` until server spec is confirmed |
| Polling blocks `buildAgent` | Polling runs in a separate `Task`; `buildAgent` awaits only the initial handshake, not approval |
| `ClawgUIPairingManager` retaining `ChatAppStore` | Use `@escaping @Sendable` callback closures for state updates, not direct store references |

---

## Final File Structure

```
Examples/ChatApp/Sources/
├── Models/
│   ├── ChatUIState.swift              (modify)
│   ├── DisplayMessage.swift           (modify)
│   ├── EphemeralSlot.swift            (NEW)
│   ├── SupplementalMessage.swift      (NEW)
│   └── ChatRow.swift                  (NEW)
├── Store/
│   ├── ChatAppStore.swift             (modify — agent lifecycle only)
│   ├── ChatAppStore+EventProcessing.swift  (NEW — processEvent + helpers)
│   ├── ChatAppStore+A2UI.swift        (NEW — A2UI event handling + action routing)
│   └── ChatAppStore+ClawgUI.swift     (NEW — ClawgUI detection + gating)
├── Tools/
│   ├── ChangeBackgroundToolExecutor.swift  (NEW)
│   └── ChatAppToolRegistry.swift           (NEW)
├── A2UI/
│   ├── A2UIComponent.swift            (NEW)
│   └── A2UISurfaceStateManager.swift  (NEW)
├── ClawgUI/
│   ├── ClawgUIPairingState.swift      (NEW)
│   ├── ClawgUIDetector.swift          (NEW)
│   └── ClawgUIPairingManager.swift    (NEW)
└── Views/
    ├── ChatView.swift                 (modify)
    ├── MessageBubbleView.swift        (modify)
    ├── RootView.swift                 (modify — ClawgUI sheet)
    ├── ShimmerModifier.swift          (NEW)
    ├── A2UI/
    │   ├── A2UISurfaceView.swift      (NEW)
    │   └── A2UIComponentView.swift    (NEW)
    └── ClawgUI/
        └── ClawgUIPairingView.swift   (NEW)
```

**New files total:** 16  
**Modified files total:** 6

---

## TDD Checklist Per Phase

Follow Red–Green–Refactor. Run `swift test` after each test added.

- [ ] **Phase 1A** — Write ephemeral slot tests → implement typed slots
- [ ] **Phase 1B** — Write supplemental message tests → implement `ChatRow` merge
- [ ] **Phase 1C** — Write optimistic message tests → implement pending correlation
- [ ] **Phase 2A** — Write args buffer tests → implement `ToolCallArgsEvent` case
- [ ] **Phase 2B** — Write tool executor tests → implement `ChangeBackgroundToolExecutor`
- [ ] **Phase 3**  — Write `#Preview` macros → implement `ShimmerModifier` + fade-in
- [ ] **Phase 4**  — Write component decoder tests → build A2UI bottom-up
- [ ] **Phase 5**  — Write detector + state machine tests → implement `ClawgUIPairingManager`

## Verification Before Each Merge

```bash
swift build
swift test
swift package plugin --allow-writing-to-package-directory swiftformat
swiftlint lint
```
