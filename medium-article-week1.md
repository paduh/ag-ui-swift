# Building a Production-Ready AI Agent SDK in Swift: Week 1

## How I'm implementing the AG-UI protocol with protocol-oriented design, actors, and AsyncSequence

---

*This is the first in a bi-weekly series documenting my journey building AGUISwift — an open-source Swift SDK for the Agent User Interaction Protocol. I'll share architectural decisions, Swift 6 concurrency patterns, and lessons learned along the way.*

---

If you've tried building real-time AI agent interfaces in Swift, you know the pain. The ecosystem is dominated by Python and TypeScript SDKs, leaving Swift developers to cobble together URLSession calls, manually parse Server-Sent Events, and pray their state management doesn't race condition into oblivion.

I decided to change that.

**AGUISwift** is my answer — a production-ready Swift SDK that brings first-class AI agent support to iOS, macOS, and beyond. After weeks of development, I'm excited to share what I've built and the architectural decisions that make it work.

---

## What is AG-UI?

The [Agent User Interaction Protocol (AG-UI)](https://docs.ag-ui.com) is an open standard for real-time communication between AI agents and user interfaces. Think of it as the "WebSocket for AI" — but smarter. It defines:

- **26 event types** for everything from `RUN_STARTED` to `TOOL_CALL_RESULT`
- **Streaming text** with proper chunking and backpressure
- **State synchronization** via JSON Patch (RFC 6902)
- **Tool execution** for extending agent capabilities

The protocol already has SDKs in TypeScript, Python, and Kotlin. Swift was conspicuously absent. Until now.

---

## The Architecture: Layered, Protocol-Oriented, Actor-Safe

I structured AGUISwift as four distinct modules, each with a single responsibility:

```
AGUICore (Foundation)
    │   Protocol types • Event models • Message definitions
    ▼
AGUIClient (Transport)
    │   HTTP streaming • SSE parsing • State management
    ▼
AGUIAgentSDK (High-Level APIs)
    │   HttpAgent • Builders • Convenience wrappers
    ▼
AGUITools (Extension Framework)
        Tool execution • Registry • Custom capabilities
```

This layering isn't just organizational — it enables **progressive disclosure**. Need raw event access? Use `AGUICore`. Want a batteries-included agent? Import `AGUIAgentSDK`. Building custom tooling? `AGUITools` has you covered.

---

## The Hard Part: Streaming SSE with Proper UTF-8 Handling

Here's where things get interesting. Server-Sent Events sound simple until you realize:

1. Network chunks don't respect event boundaries
2. UTF-8 characters can split across chunks
3. You need backpressure to avoid memory explosions
4. State must be thread-safe without blocking

My solution is a **three-layer streaming pipeline**:

```
HTTP Response (URLSession.AsyncBytes)
           │
           ▼
    ┌─────────────┐
    │  SseParser  │  Stateful, handles partial events
    └─────────────┘
           │
           ▼
    ┌─────────────┐
    │ EventStream │  AsyncSequence with buffering
    └─────────────┘
           │
           ▼
    Typed AGUIEvent instances
```

### The SseParser: Stateful Incremental Parsing

The SSE spec looks simple, but edge cases abound. My `SseParser` maintains state between parse calls:

```swift
public struct SseParser: Sendable {
    private var buffer: String = ""

    public mutating func parse(_ chunk: String) -> [SseEvent] {
        buffer.append(chunk)
        var events: [SseEvent] = []

        // Handle both \n\n and \r\n\r\n delimiters
        while let range = buffer.range(of: "\n\n") ??
                          buffer.range(of: "\r\n\r\n") {
            let eventText = String(buffer[..<range.lowerBound])
            buffer.removeSubrange(..<range.upperBound)

            if let event = parseEvent(eventText) {
                events.append(event)
            }
        }
        return events
    }
}
```

The key insight: **buffer incomplete data** and only emit complete events. This handles chunked transfer encoding gracefully.

### UTF-8 Edge Cases That Will Ruin Your Day

Here's a bug that took me hours to track down. Consider a streaming response where a 4-byte UTF-8 character (like an emoji 🤖) splits across network chunks:

```
Chunk 1: [0xF0, 0x9F]      // First 2 bytes of 🤖
Chunk 2: [0xA4, 0x96, ...] // Last 2 bytes + more data
```

Naive string conversion fails. My `EventStream` handles this with a byte buffer:

```swift
final class EventStreamIterator<Bytes: AsyncSequence>:
    AsyncIteratorProtocol where Bytes.Element == UInt8 {

    private var utf8Buffer: [UInt8] = []

    private func decodeUTF8(_ bytes: [UInt8]) -> (String, [UInt8]) {
        var validEnd = bytes.count

        // Check for incomplete multi-byte sequence at end
        for i in stride(from: bytes.count - 1,
                        through: max(0, bytes.count - 4),
                        by: -1) {
            let byte = bytes[i]
            if byte & 0b11000000 == 0b11000000 { // Start byte
                let expectedLength = expectedUTF8Length(byte)
                let actualLength = bytes.count - i
                if actualLength < expectedLength {
                    validEnd = i
                }
                break
            }
        }

        let validBytes = Array(bytes[..<validEnd])
        let remainder = Array(bytes[validEnd...])
        let string = String(decoding: validBytes, as: UTF8.self)
        return (string, remainder)
    }
}
```

This ensures emoji, CJK characters, and any valid UTF-8 stream correctly — even when split mid-character.

---

## Polymorphic Decoding: The Registry Pattern

AG-UI defines 26 event types. The JSON looks like this:

```json
{"type": "TEXT_MESSAGE_START", "messageId": "abc", "role": "assistant"}
{"type": "TOOL_CALL_START", "toolCallId": "xyz", "toolCallName": "search"}
```

Same field name (`type`), completely different payload structures. Swift's `Codable` doesn't handle this out of the box. My solution: **a registry-based decoder**.

```swift
public typealias DecodeHandler = @Sendable (
    _ data: Data,
    _ decoder: JSONDecoder
) throws -> any AGUIEvent

public struct AGUIEventDecoder: Sendable {
    private let registry: [EventType: DecodeHandler]

    public func decode(from data: Data) throws -> any AGUIEvent {
        // Extract type discriminator first
        let typeContainer = try JSONDecoder()
            .decode(TypeContainer.self, from: data)

        guard let handler = registry[typeContainer.type] else {
            switch configuration.unknownEventStrategy {
            case .throwError:
                throw EventDecodingError.unknownEventType(typeContainer.type)
            case .returnUnknown:
                return UnknownEvent(typeRaw: typeContainer.type.rawValue, ...)
            }
        }

        return try handler(data, JSONDecoder())
    }
}
```

The beauty of this pattern:

1. **Extensible** — Add custom event types without modifying core code
2. **Composable** — Merge multiple registries for different use cases
3. **Testable** — Mock handlers return predictable events
4. **Fail-safe** — Unknown events can be preserved, not dropped

I organize handlers into focused registries that compose together:

```swift
public static func defaultRegistry() -> AGUIEventDecoder {
    let composer = RegistryComposer()
        .add(LifecycleEventRegistry.handlers)    // 5 types
        .add(TextMessageEventRegistry.handlers)  // 4 types
        .add(ToolCallEventRegistry.handlers)     // 5 types
        .add(StateEventRegistry.handlers)        // 3 types
        .add(ThinkingEventRegistry.handlers)     // 5 types
        .add(ActivityEventRegistry.handlers)     // 2 types
        .add(SpecialEventRegistry.handlers)      // Raw, Custom

    return AGUIEventDecoder(registry: composer.build())
}
```

---

## Actor-Based State Management

AG-UI supports two state synchronization patterns:

1. **STATE_SNAPSHOT** — Full state replacement
2. **STATE_DELTA** — Incremental updates via JSON Patch

Both must be thread-safe. Enter Swift actors:

```swift
public actor StateManager {
    private var currentState: [String: Any] = [:]

    public func applySnapshot(_ snapshot: [String: Any]) {
        currentState = snapshot
    }

    public func applyDelta(_ operations: [PatchOperation]) throws {
        currentState = try PatchApplicator.apply(
            operations,
            to: currentState
        )
    }

    public func state<T: Decodable>(as type: T.Type) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: currentState)
        return try JSONDecoder().decode(type, from: data)
    }
}
```

Actor isolation guarantees that snapshots and deltas apply **sequentially**, preventing race conditions. The `PatchApplicator` implements RFC 6902 operations atomically — if any operation fails, the entire patch is rejected.

---

## The Developer Experience: Fluent Builders

Raw APIs are powerful but verbose. I added a builder pattern for ergonomic usage:

```swift
let input = RunAgentInputBuilder()
    .threadId("thread-123")
    .runId("run-456")
    .message(UserMessage(content: "Hello, agent!"))
    .tool(FrontendTool(
        name: "get_weather",
        description: "Fetches current weather",
        parameters: weatherSchema
    ))
    .context(["user_timezone": "America/New_York"])
    .build()

let agent = HttpAgent(baseURL: URL(string: "https://api.myagent.com")!)

for try await event in agent.runAgent(input) {
    switch event {
    case let textStart as TextMessageStartEvent:
        print("Agent says: ", terminator: "")
    case let textContent as TextMessageContentEvent:
        print(textContent.delta, terminator: "")
    case is TextMessageEndEvent:
        print() // Newline
    case let error as RunErrorEvent:
        print("Error: \(error.error.message)")
    default:
        break
    }
}
```

Clean. Readable. Type-safe. The builder validates required fields at `build()` time, catching configuration errors early.

---

## What's Next

This is just the beginning. Over the coming weeks, I'll be:

- **Implementing `AGUITools`** — A framework for registering and executing frontend tools
- **Adding `StatefulAgUiAgent`** — Conversation history and context management
- **Building real-world examples** — Chat UIs, coding assistants, multimodal agents
- **Performance optimization** — Benchmarking against the TypeScript SDK

If you're interested in contributing or just following along, check out the repo:

**[github.com/pduhnmac/ag-ui-swift](https://github.com/pduhnmac/ag-ui-swift)** *(Update with your actual repo URL)*

---

## Key Takeaways

1. **Layer your architecture** — Separate concerns enable progressive disclosure and testability
2. **Handle UTF-8 properly** — Streaming bytes ≠ streaming strings
3. **Use registries for polymorphism** — More flexible than switch statements, easier to extend
4. **Embrace actors for state** — Swift concurrency makes thread-safe state trivial
5. **Invest in DX** — Builders and fluent APIs make your SDK a joy to use

---

*Found this useful? Follow me for the next installment where I'll dive into tool execution and frontend capabilities. Questions or feedback? Drop a comment or open an issue on GitHub.*

---

**Tags:** `swift` `ios` `ai` `agents` `open-source` `architecture` `concurrency` `asyncsequence`
