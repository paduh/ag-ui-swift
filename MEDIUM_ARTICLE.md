# Building AGUISwift: A Native Swift SDK for the AG-UI Protocol

## The Journey Begins

A few weeks ago, I found myself searching for a native Swift SDK to integrate the Agent User Interaction Protocol (AG-UI) into an iOS project. After scouring GitHub and the usual Swift package repositories, I came up empty-handed. There were implementations in Python, TypeScript, and even Kotlin Multiplatform, but nothing native for Swift.

That's when I stumbled upon [this community request](https://github.com/orgs/ag-ui-protocol/projects/1/views/5?pane=issue&itemId=132549057&issue=ag-ui-protocol%7Cag-ui%7C494) in the AG-UI protocol repository. Someone was asking for a Swift SDK implementation, and it seemed like the perfect opportunity to contribute to the open-source community while solving my own problem.

I left a comment expressing my interest in picking up the work, and even though I haven't received a response yet, I decided to start building. Sometimes the best way to contribute is to just start building and show what's possible.

## Why AG-UI?

The AG-UI protocol enables real-time streaming communication between applications and AI agents. It's designed for building AI agent user interfaces with support for:

- Real-time event streaming
- Tool execution and integration
- State management
- Multi-turn conversations
- Type-safe protocol implementation

For iOS developers, having a native Swift SDK means we can leverage Swift's type system, async/await, and modern concurrency features without dealing with bridging layers or cross-platform compromises.

## Architecture Decisions: Pragmatic Design for a Protocol SDK

When I started building AGUISwift, I explored different architectural approaches. Initially, I considered Domain-Driven Design (DDD) with pure value objects, but after building the foundation, I realized that for a protocol SDK, a more pragmatic approach would serve developers better.

### The Three-Layer Architecture

I structured the SDK into three main modules:

**AGUICore** - The foundation layer containing:
- Event type definitions (lifecycle, text messages, tool calls, etc.)
- Polymorphic event decoder with registry-based architecture
- Event DTOs (Data Transfer Objects) for JSON serialization
- Error types and domain models

**AGUIClient** - High-level agent implementations

**AGUITools** - Tool execution framework

### Registry-Based Polymorphic Decoding

The core innovation in AGUISwift is the `AGUIEventDecoder`—a registry-based decoder that performs polymorphic deserialization based on the "type" field in JSON events.

```swift
// Simple, clean API
let decoder = AGUIEventDecoder()
let event = try decoder.decode(jsonData)

// Pattern match on event type
switch event.eventType {
case .runStarted:
    let runStarted = event as! RunStartedEvent
    print("Run \(runStarted.runId) started")
case .runFinished:
    let runFinished = event as! RunFinishedEvent
    print("Run \(runFinished.runId) finished")
default:
    print("Other event: \(event.eventType)")
}
```

### Separation of Concerns: Events and DTOs

Events are clean, simple structs that represent the domain model:

```swift
public struct RunStartedEvent: AGUIEvent, Equatable, Hashable, Sendable {
    public let threadId: String
    public let runId: String
    public let timestamp: Int64?
    public let rawEvent: Data?
    
    public var eventType: EventType { .runStarted }
}
```

Decoding is handled by DTOs (Data Transfer Objects) that bridge JSON and domain models:

```swift
struct RunStartedEventDTO: Decodable {
    let threadId: String
    let runId: String
    let timestamp: Int64?
    
    func toDomain(rawEvent: Data? = nil) -> RunStartedEvent {
        RunStartedEvent(
            threadId: threadId,
            runId: runId,
            timestamp: timestamp,
            rawEvent: rawEvent
        )
    }
}
```

This separation means:
- Events remain simple and focused on domain concepts
- Serialization logic is isolated in DTOs
- We can evolve serialization without touching domain models
- Events don't need to conform to Codable

### Forward Compatibility with Tolerant Mode

One of the most powerful features is the decoder's ability to handle unknown events gracefully:

```swift
var config = AGUIEventDecoder.Configuration()
config.unknownEventStrategy = .returnUnknown
let decoder = AGUIEventDecoder(config: config)

let event = try decoder.decode(data)
if let unknown = event as? UnknownEvent {
    print("Unknown event type: \(unknown.typeRaw)")
    // Can still access raw JSON for forwarding or logging
}
```

This enables forward compatibility—older SDK versions can receive new event types without crashing, even if they can't decode them.

## What's Been Implemented So Far

### Foundation: Event Decoder and Core Types

I started with the fundamental building blocks:

**AGUIEventDecoder** - Registry-based polymorphic decoder
- Strict mode (default): Throws errors for unknown/unsupported events
- Tolerant mode: Returns `UnknownEvent` for forward compatibility
- Custom registry support for extensibility

**Event Types:**
- `EventType` enum with all AG-UI protocol event types
- `EventDecodingError` for comprehensive error handling
- `UnknownEvent` for graceful handling of unrecognized events

### Protocol Events: The Core Domain Model

The AG-UI protocol defines various event types. I've implemented all lifecycle events:

**Lifecycle Events:**
- `RunStartedEvent` - Signals when an agent run begins
- `RunFinishedEvent` - Signals when an agent run completes successfully
- `RunErrorEvent` - Signals when an agent run encounters an error
- `StepStartedEvent` - Signals when an execution step begins
- `StepFinishedEvent` - Signals when an execution step completes

Each event follows a consistent pattern:
- Simple, clean structs with String properties
- Type-safe event type enumeration
- Optional timestamp and raw event data preservation
- Full `Equatable` and `Hashable` conformance

### Event DTOs: Separation of Concerns

Each event has a corresponding DTO for JSON decoding:

```swift
struct RunStartedEventDTO: Decodable {
    let threadId: String
    let runId: String
    let timestamp: Int64?
    
    func toDomain(rawEvent: Data? = nil) -> RunStartedEvent {
        RunStartedEvent(threadId: threadId, runId: runId, 
                        timestamp: timestamp, rawEvent: rawEvent)
    }
}
```

DTOs handle all the messy JSON parsing details, keeping domain events clean and focused.

### Testing: Building Confidence

I've written comprehensive unit tests following a consistent pattern:

**Decoding Tests:**
- Valid event decoding with all fields
- Optional field handling (timestamps, etc.)
- Raw event data preservation
- Unknown extra fields handling

**Error Handling Tests:**
- Missing type field
- Unknown event types (strict vs tolerant mode)
- Missing required fields
- Type mismatches
- Invalid JSON

**Model Behavior Tests:**
- Event type consistency
- Equatable implementation
- Edge cases (empty strings, Unicode, etc.)

Having comprehensive tests ensures correctness—one bug in event serialization can break entire applications.

## Design Patterns and Swift Idioms

### Protocol-Oriented Design

Swift's protocol-oriented nature influenced several design decisions:

```swift
public protocol AGUIEvent: Sendable {
    var eventType: EventType { get }
    var timestamp: Int64? { get }
    var rawEvent: Data? { get }
}
```

This protocol serves as a domain concept without coupling to serialization. Events don't conform to `Codable` directly—decoding is handled by the decoder and DTOs.

### Registry Pattern for Extensibility

The decoder uses a registry pattern that makes it easy to add new event types:

```swift
let customRegistry: [EventType: AGUIEventDecoder.DecodeHandler] = [
    .runStarted: { data, decoder in
        try decoder.decode(RunStartedEventDTO.self, from: data)
            .toDomain(rawEvent: data)
    },
    .runFinished: { data, decoder in
        try decoder.decode(RunFinishedEventDTO.self, from: data)
            .toDomain(rawEvent: data)
    }
    // Add more handlers as needed
]

let decoder = AGUIEventDecoder(registry: customRegistry)
```

This pattern allows:
- Modular event type registration
- Easy composition of multiple registries
- Custom decoders for specific use cases
- Testing with minimal event sets

### Type Safety Through Enums

The `EventType` enum provides compile-time type safety:

```swift
public enum EventType: String, Codable, CaseIterable, Sendable {
    case runStarted = "RUN_STARTED"
    case runFinished = "RUN_FINISHED"
    case runError = "RUN_ERROR"
    // ... more cases
}
```

Pattern matching on `eventType` ensures exhaustive handling:

```swift
switch event.eventType {
case .runStarted:
    // Handle run started
case .runFinished:
    // Handle run finished
case .runError:
    // Handle run error
// Compiler ensures all cases are handled
}
```

### DTO Pattern for Clean Separation

The DTO (Data Transfer Object) pattern separates serialization from domain models:

```swift
// DTO handles JSON decoding
struct RunStartedEventDTO: Decodable {
    let threadId: String
    let runId: String
    let timestamp: Int64?
}

// Domain model stays clean
public struct RunStartedEvent: AGUIEvent {
    public let threadId: String
    public let runId: String
    public let timestamp: Int64?
    // No Codable conformance needed
}
```

This keeps domain models focused on business logic while DTOs handle the infrastructure concerns.

## Challenges and Learnings

### Evolving from DDD to Pragmatic Design

One of the biggest challenges was deciding how strict to be with architectural patterns. I initially explored Domain-Driven Design with pure value objects, but realized that for a protocol SDK, pragmatism wins.

The evolution:
- **Started with**: Pure value objects (ThreadId, RunId) with validation
- **Evolved to**: Simple String properties with clear naming
- **Reason**: Protocol SDKs need to be easy to use, not architecturally pure

The key insight: **Separation of concerns doesn't require value objects**. The DTO pattern achieves the same goal—keeping serialization separate from domain models—without the complexity.

### Registry-Based Decoding: The Right Abstraction

The registry pattern emerged as the perfect abstraction for polymorphic decoding:

- **Extensible**: Easy to add new event types
- **Testable**: Can test with minimal registries
- **Composable**: Multiple registries can be combined
- **Flexible**: Supports custom decoding strategies

This pattern scales better than trying to make every event type conform to Codable directly.

### Forward Compatibility Matters

Building `UnknownEvent` and tolerant mode wasn't initially planned, but it's crucial for a protocol SDK:

- Older SDK versions can receive new event types
- Applications can gracefully degrade
- Raw JSON is preserved for debugging/forwarding
- No crashes from unrecognized types

This is especially important when the protocol evolves faster than SDK releases.

### Swift Package Manager Considerations

Building as an SPM package influenced several decisions:
- Module boundaries need to be clear
- Public APIs must be stable
- Internal implementation details can evolve

The three-module structure (AGUICore, AGUIClient, AGUITools) allows consumers to import only what they need. The decoder's registry pattern makes it easy to extend without breaking changes.

## What's Next

The foundation is solid, but there's still much to build:

**Immediate Next Steps:**
- ✅ Complete all lifecycle events (RunStarted, RunFinished, RunError, StepStarted, StepFinished)
- Implement text message events (TEXT_MESSAGE_START, CONTENT, END, CHUNK)
- Add tool call events (TOOL_CALL_START, ARGS, END, RESULT, CHUNK)
- Implement state management events (STATE_SNAPSHOT, STATE_DELTA, MESSAGES_SNAPSHOT)
- Add thinking events (THINKING_START, END, TEXT_MESSAGE_START, etc.)

**Client Implementation:**
- AgUiAgent (stateless)
- StatefulAgUiAgent (with conversation history)
- SSE (Server-Sent Events) parser for streaming
- HTTP transport layer with event streaming

**Tool Framework:**
- ToolExecutor protocol
- ToolRegistry for managing tools
- Tool execution manager with error handling

**Documentation:**
- ✅ Comprehensive API documentation
- Usage guides and examples
- Migration guides for future versions

## Contributing and Feedback

This is very much a work in progress, and I'd love to hear from the community. If you're interested in:
- Using the SDK in your project
- Contributing implementations
- Providing feedback on the architecture
- Suggesting improvements

Please check out the [repository](https://github.com/paduh/ag-ui-swift) and feel free to open issues or pull requests.

## Reflection

Building AGUISwift has been a great learning experience. It's forced me to think deeply about:
- How to structure a protocol SDK for maximum usability
- When to apply architectural patterns (and when not to)
- Balancing purity with pragmatism
- Building for maintainability and extensibility
- The importance of forward compatibility in protocol SDKs

### Key Learnings

**Start Simple, Evolve Thoughtfully**: I began with a DDD-inspired architecture with value objects, but evolved to a simpler, more pragmatic approach. The DTO pattern achieves separation of concerns without the complexity.

**Registry Patterns Scale**: The registry-based decoder emerged as the perfect abstraction. It's extensible, testable, and composable—exactly what a protocol SDK needs.

**Forward Compatibility Matters**: Building `UnknownEvent` and tolerant mode wasn't initially planned, but it's crucial. Protocol SDKs need to gracefully handle evolution.

**Documentation is Architecture**: Writing comprehensive documentation forced me to clarify the design. The decoder's API emerged cleaner because I had to explain it.

The fact that I started without waiting for permission reminds me that sometimes the best way to contribute to open source is to just start building. The code speaks louder than comments, and iteration based on real usage beats theoretical perfection.

If you're working on a similar project or thinking about contributing to open source, my advice is: don't wait for permission. Start building, share your work, and iterate based on feedback. The community will guide you, but you have to take the first step.

---

**Repository**: [github.com/paduh/ag-ui-swift](https://github.com/paduh/ag-ui-swift)  
**AG-UI Protocol**: [github.com/ag-ui-protocol/ag-ui](https://github.com/ag-ui-protocol/ag-ui)  
**Community Request**: [GitHub Issue #494](https://github.com/orgs/ag-ui-protocol/projects/1/views/5?pane=issue&itemId=132549057&issue=ag-ui-protocol%7Cag-ui%7C494)


