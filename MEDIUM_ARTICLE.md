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

## Architecture Decisions: Domain-Driven Design from Day One

When I started building AGUISwift, I made a conscious decision to apply Domain-Driven Design (DDD) principles from the very beginning. This wasn't just about following best practices—it was about creating a maintainable, testable, and extensible foundation.

### The Three-Layer Architecture

I structured the SDK into three main modules, similar to the Kotlin implementation but with Swift-specific considerations:

**AGUICore** - The foundation layer containing:
- Domain layer with pure value objects
- Protocol layer with event definitions
- Infrastructure layer for serialization

**AGUIClient** - High-level agent implementations

**AGUITools** - Tool execution framework

### Domain Layer: Pure Business Logic

One of the first architectural decisions was to create a strict separation between domain logic and infrastructure concerns. This led me to implement value objects in the domain layer that have zero infrastructure dependencies.

```swift
// Pure domain value object - no Codable, no Foundation
public struct ThreadId: Hashable, Equatable {
    public let value: String
    
    public init(_ value: String) throws {
        guard !value.isEmpty else {
            throw DomainError.invalidThreadId("Thread ID cannot be empty")
        }
        self.value = value
    }
}
```

This approach ensures that:
- Domain logic is testable without infrastructure mocks
- Business rules are enforced at the domain level
- The domain layer can evolve independently of serialization concerns

### Infrastructure Layer: Handling the Messy Details

For serialization, I created infrastructure wrappers that bridge the pure domain objects with Codable requirements:

```swift
// Infrastructure wrapper - handles JSON serialization
struct SerializableThreadId: Codable {
    let domainValue: ThreadId
    
    init(from decoder: Decoder) throws {
        let stringValue = try container.decode(String.self)
        self.domainValue = try ThreadId(stringValue)
    }
}
```

This separation means:
- Domain objects remain pure and focused
- Serialization can change without affecting domain logic
- We can support multiple serialization formats if needed

### Why Not Just Use Codable Directly?

You might be wondering: why go through all this trouble when Swift's Codable is so convenient? The answer comes down to maintainability and testability.

In a protocol SDK, events are the core domain concept. By keeping domain events pure, we can:
- Test business logic without JSON parsing
- Change serialization strategies without touching domain code
- Support multiple protocols or formats in the future
- Make the domain model understandable to domain experts

## What's Been Implemented So Far

### Foundation: Value Objects and Domain Errors

I started with the fundamental building blocks:

**Value Objects:**
- `ThreadId` - Type-safe thread identifier with validation
- `RunId` - Type-safe run identifier with validation  
- `EventTimestamp` - Domain-focused timestamp representation

**Domain Errors:**
- `DomainError` enum for all domain validation failures

These might seem simple, but they provide the type safety and validation that prevent entire classes of bugs.

### Protocol Events: The Core Domain Model

The AG-UI protocol defines various event types. I've implemented the lifecycle events first:

**RunStartedEvent** - Signals when an agent run begins
**RunFinishedEvent** - Signals when an agent run completes

Each event follows a consistent pattern:
- Pure domain properties (ThreadId, RunId, EventTimestamp)
- Type-safe event type enumeration
- Comprehensive Codable implementation
- Full test coverage

### Testing: Building Confidence

I've written comprehensive unit tests covering:
- Initialization and validation
- JSON encoding and decoding
- Error handling for invalid data
- Round-trip serialization

Having 14 tests per event type might seem like overkill, but when building a protocol SDK, correctness is everything. One bug in event serialization can break entire applications.

## Design Patterns and Swift Idioms

### Protocol-Oriented Design

Swift's protocol-oriented nature influenced several design decisions:

```swift
public protocol BaseEvent: Codable {
    var eventType: EventType { get }
    var timestamp: Int64? { get }
    var rawEvent: Data? { get }
}
```

This protocol serves as both a domain concept and a serialization contract, but the implementation separates these concerns.

### Type Safety Through Value Objects

Instead of passing raw strings around, the SDK uses value objects:

```swift
// Before: Easy to mix up threadId and runId
func processEvent(threadId: String, runId: String)

// After: Compiler prevents mistakes
func processEvent(threadId: ThreadId, runId: RunId)
```

This catches errors at compile time rather than runtime.

### Helper Methods for Common Patterns

I created helper methods to reduce boilerplate:

```swift
extension BaseEvent {
    static func verifyType(
        in container: KeyedDecodingContainer<Keys>,
        expected: EventType,
        typeKey: Keys
    ) throws {
        // Type verification logic
    }
}
```

This pattern will be reused across all event types, keeping the codebase DRY and maintainable.

## Challenges and Learnings

### Balancing Purity with Practicality

One of the biggest challenges was deciding how strict to be with DDD layering. Should value objects have Codable? Should events be split into domain and infrastructure versions?

I chose a middle ground:
- Domain value objects are pure (no Codable)
- Infrastructure wrappers handle serialization
- Events currently mix concerns but will be refactored

This gives us the benefits of DDD without making the API too complex for initial adoption.

### Swift Package Manager Considerations

Building as an SPM package influenced several decisions:
- Module boundaries need to be clear
- Public APIs must be stable
- Internal implementation details can evolve

The three-module structure (AGUICore, AGUIClient, AGUITools) allows consumers to import only what they need.

## What's Next

The foundation is solid, but there's still much to build:

**Immediate Next Steps:**
- Complete all lifecycle events (RunError, StepStarted, StepFinished)
- Implement text message events (TEXT_MESSAGE_START, CONTENT, END)
- Add tool call events
- Build the HTTP transport layer

**Client Implementation:**
- AgUiAgent (stateless)
- StatefulAgUiAgent (with conversation history)
- SSE (Server-Sent Events) parser for streaming

**Tool Framework:**
- ToolExecutor protocol
- ToolRegistry for managing tools
- Tool execution manager

## Contributing and Feedback

This is very much a work in progress, and I'd love to hear from the community. If you're interested in:
- Using the SDK in your project
- Contributing implementations
- Providing feedback on the architecture
- Suggesting improvements

Please check out the [repository](https://github.com/paduh/ag-ui-swift) and feel free to open issues or pull requests.

## Reflection

Building AGUISwift has been a great learning experience. It's forced me to think deeply about:
- How to structure a protocol SDK
- When to apply DDD principles
- Balancing purity with pragmatism
- Building for maintainability from day one

The fact that I started without waiting for permission reminds me that sometimes the best way to contribute to open source is to just start building. The code speaks louder than comments.

If you're working on a similar project or thinking about contributing to open source, my advice is: don't wait for permission. Start building, share your work, and iterate based on feedback. The community will guide you, but you have to take the first step.

---

**Repository**: [github.com/paduh/ag-ui-swift](https://github.com/paduh/ag-ui-swift)  
**AG-UI Protocol**: [github.com/ag-ui-protocol/ag-ui](https://github.com/ag-ui-protocol/ag-ui)  
**Community Request**: [GitHub Issue #494](https://github.com/orgs/ag-ui-protocol/projects/1/views/5?pane=issue&itemId=132549057&issue=ag-ui-protocol%7Cag-ui%7C494)

