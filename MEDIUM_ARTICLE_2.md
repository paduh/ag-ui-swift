# Refactoring AGUISwift: Design Decisions and What I Learned

Over the past few weeks, I've been deep in refactoring mode on AGUISwift, my native Swift implementation of the AG-UI protocol. The codebase has evolved significantly, and I wanted to share some of the architectural decisions I made, why I made them, and what's coming next.

This isn't going to be a theoretical architecture discussion. I'll show you the real problems I ran into, the solutions I implemented, and the trade-offs I had to make. If you're building SDKs or protocol implementations in Swift, hopefully some of these patterns will be useful.

## Quick context

AGUISwift is a Swift SDK for the Agent User Interaction Protocol. It enables real-time streaming between iOS/macOS apps and AI agents. The architecture is pretty straightforward:

```
AGUICore (foundation layer)
    ↓
AGUIClient (transport)
    ↓
AGUIAgentSDK (high-level APIs)
```

Most of the interesting work has been happening in AGUICore, which contains all the protocol types and message definitions. That's what I'll focus on here.

## The DTO refactor

Let me start with the biggest change. Originally, all the message types (UserMessage, AssistantMessage, etc.) implemented Codable directly. Seemed like the obvious choice at first. Swift's Codable is great, right? Just add conformance and you get JSON serialization for free.

Except it wasn't working out that way.

The problem showed up when I started implementing more complex message types. ActivityMessage, for example, has this `activityContent` field that can contain arbitrary JSON. The protocol spec says it could be anything: `{"status": "processing"}` or `{"progress": 0.5}` or a complex visualization config.

With direct Codable conformance, I had a few options:
1. Make activityContent an `Any` type (not Codable, breaks everything)
2. Make it a `Data` blob (lose type safety)
3. Create a massive enum of every possible content type (doesn't scale)
4. Use some custom decoder (now my domain model knows about JSON parsing)

None of these felt right. The domain model shouldn't care about JSON structure. That's a serialization concern.

So I refactored to use DTOs (Data Transfer Objects). Here's what that looks like:

```swift
// Domain model - clean, no Codable
public struct UserMessage: Message, Equatable, Hashable, Sendable {
    public let id: String
    public let content: [any InputContent]
    public var role: Role { .user }
}

// DTO - handles JSON
struct UserMessageDTO: Decodable {
    let id: String
    let role: String
    let content: [InputContentDTO]

    func toDomain() throws -> UserMessage {
        let domainContent = try content.map { try $0.toDomain() }
        return UserMessage(id: id, content: domainContent)
    }
}
```

The domain model stays clean. All the JSON parsing complexity lives in the DTO layer. And here's the thing: this makes evolution so much easier. When the protocol changes (and it will), I only need to update the DTOs. The domain models stay stable.

### What it cost me

This wasn't free. I added about 500 lines of code. Every message type now has a corresponding DTO. That's 18 message types, so 18 DTOs, plus all the conversion logic.

The directory structure got more complex too:

```
Sources/AGUICore/
├── Types/Messages/          # Domain models
│   ├── UserMessage.swift
│   ├── AssistantMessage.swift
│   └── ...
└── Decoding/MessageDTO/     # Serialization
    ├── UserMessageDTO.swift
    ├── AssistantMessageDTO.swift
    └── ...
```

More files to navigate, more code to maintain. But honestly? Worth it. The separation of concerns is so much cleaner now. I can test domain logic without touching JSON. I can change serialization format without touching business logic. The coupling is gone.

### Was it the right call?

For this project, yes. AGUISwift is a protocol SDK. Protocols evolve. The AG-UI spec is still being refined. Having this separation means I can adapt to spec changes without restructuring the entire domain model.

If I was building a simple app that just consumes an API? Probably overkill. Direct Codable would be fine. But for a library that other developers will build on top of? The extra structure pays dividends.

## The builder pattern

The next big change was adding a builder for `RunAgentInput`. This type represents the request body sent to an agent. It has 8 parameters: threadId, runId, parentRunId, state, messages, tools, context, and forwardedProps.

The constructor was getting ridiculous:

```swift
let input = RunAgentInput(
    threadId: "thread-123",
    runId: "run-456",
    parentRunId: nil,
    state: Data("{}".utf8),
    messages: messages,
    tools: tools,
    context: contexts,
    forwardedProps: Data("{}".utf8)
)
```

Try reading that code six months from now. Which parameter is which? What's the order? Why are there two `Data("{}".utf8)` blobs?

I added a builder:

```swift
let input = try RunAgentInput.builder()
    .threadId("thread-123")
    .runId("run-456")
    .message(DeveloperMessage(id: "dev-1", content: "You are helpful"))
    .message(UserMessage(id: "user-1", content: "Hello!"))
    .tool(weatherTool)
    .contextItem(Context(description: "user_location", value: "San Francisco"))
    .build()
```

Much better. Self-documenting. The methods guide you through what's needed. Xcode's autocomplete actually helps instead of showing you a wall of parameters.

### Making it immutable

Here's a decision I spent some time on: should the builder be a class or a struct?

I went with struct. Each builder method returns a new builder instance:

```swift
public struct RunAgentInputBuilder {
    private var _threadId: String?
    private var _messages: [any Message] = []

    public func threadId(_ threadId: String) -> Self {
        var builder = self  // copy
        builder._threadId = threadId
        return builder
    }
}
```

This means every method call creates a copy. That's overhead, right? Yeah, a bit. But it gives me thread safety for free. No locks needed. And builders are short-lived anyway, they exist during construction and then get discarded.

The real win is reusability. You can create a base builder and then branch from it:

```swift
let base = RunAgentInput.builder()
    .threadId("thread-1")
    .runId("run-1")

let input1 = try base
    .message(message1)
    .build()

let input2 = try base
    .message(message2)
    .build()
```

Same base config, different messages. With a mutable class-based builder, that second call would include message1 too. With value semantics, each branch is independent.

### Throw vs crash

Another decision: what happens when someone calls `build()` without setting the required fields?

I could do this:

```swift
public func build() -> RunAgentInput {
    guard let threadId = _threadId else {
        preconditionFailure("threadId is required")
    }
    // ...
}
```

That crashes the app. For internal code, maybe that's fine. Fail fast, fail loud. But this is a public SDK. Should my library crash your app because you forgot to set a field?

I went with throwing instead:

```swift
public func build() throws -> RunAgentInput {
    guard let threadId = _threadId else {
        throw BuilderError.missingThreadId
    }
    // ...
}

public enum BuilderError: Error {
    case missingThreadId
    case missingRunId
}
```

Now you can catch it:

```swift
do {
    let input = try builder.build()
} catch BuilderError.missingThreadId {
    // show error to user, or log it, or whatever
}
```

More verbose? Yes. You need `try` everywhere. But you get error recovery. A UI can show validation messages. A test can verify the error. Your app doesn't crash.

For library code, I think that's the right trade-off. Let the application decide what to do with errors. Don't make that decision for them.

## What's actually done

Let me be concrete about what's implemented:

**Type system (complete):**
All the protocol types are done. Role enum, 6 message types (User, Assistant, Developer, System, Tool, Activity), InputContent (Text and Binary), Tools, ToolCalls, FunctionCalls, Context, State, RunAgentInput.

**DTO layer (complete):**
Every message type has a corresponding DTO. MessageDecoder handles polymorphic deserialization. Custom encoding for ActivityMessage to handle the arbitrary JSON content.

**Event system (complete):**
All 26 event types from the AG-UI spec. Lifecycle events (RunStarted, RunFinished, etc.), text message events, tool call events, state events, thinking events, activity events. The whole thing.

**Builder pattern (complete):**
RunAgentInputBuilder with fluent interface. Value semantics. Throwing build(). 20 test cases covering happy path and error conditions.

**Tests:**
339 tests, all passing. Unit tests for every type. DTO serialization tests. Builder tests. Error handling. Edge cases. The works.

## What's next

The foundation is solid. Now I need to build the layers on top.

### Transport layer (next 1-2 weeks)

AGUIClient is the transport module. It needs to handle HTTP communication and Server-Sent Events parsing.

The target API looks like this:

```swift
let client = HttpAgent(baseURL: "https://agent.example.com")

for try await event in client.run(input) {
    switch event.eventType {
    case .textMessageChunk:
        let chunk = event as! TextMessageChunkEvent
        print(chunk.delta, terminator: "")
    case .runFinished:
        print("\nDone!")
    default:
        break
    }
}
```

Async sequence of events streaming from the agent. Clean, Swift-y.

The hard part is going to be the SSE parser. Server-Sent Events is a simple protocol on the surface, but there are edge cases. Partial chunks. Reconnection. Event IDs. Making sure the parser is incremental and doesn't buffer the entire stream.

I'm planning to use AsyncStream for backpressure handling. If events arrive faster than the consumer processes them, I'll buffer the newest 100 and drop older ones. For streaming text, that's acceptable. Nobody needs the middle chunks from 10 seconds ago. But some events are critical (runFinished, runError), so those need priority.

Still thinking through the details there.

### High-level APIs (weeks 2-3)

AGUIAgentSDK is the developer-friendly layer. Two main types:

**AgUiAgent** for stateless interactions:
```swift
let agent = AgUiAgent(endpoint: "https://agent.example.com")
let response = try await agent.run(
    threadId: "thread-1",
    runId: "run-1",
    message: "What's the weather?"
)
```

Simple request/response. No state tracking.

**StatefulAgUiAgent** for conversations:
```swift
let agent = StatefulAgUiAgent(endpoint: "https://agent.example.com")

agent.send("What's the weather in SF?")
for try await event in agent.events {
    // process events
}

agent.send("How about New York?")
// agent remembers the previous context
```

The stateful version maintains message history. Each call sends the accumulated conversation.

The challenge here is memory management. Can't keep unlimited message history. I'm thinking of a sliding window strategy: keep the last 50 messages, summarize older context. But summarization needs an LLM call, which adds latency and cost.

Maybe make it configurable? Let developers choose between `unlimited`, `limit(maxMessages: Int)`, or `sliding(window: Int, summarize: Bool)`. Different apps have different constraints.

### Tool execution (weeks 3-4)

AGUITools enables agents to call Swift functions. Define a tool:

```swift
struct WeatherTool: ToolExecutor {
    func execute(arguments: Data) async throws -> Data {
        struct Args: Decodable {
            let location: String
        }
        let args = try JSONDecoder().decode(Args.self, from: arguments)
        let weather = try await fetchWeather(location: args.location)
        return try JSONEncoder().encode(weather)
    }
}
```

Register it:

```swift
let registry = ToolRegistry()
registry.register(
    name: "get_weather",
    description: "Get current weather",
    executor: WeatherTool()
)
```

The interesting part is resilience. What if a tool crashes? Or hangs? One buggy tool shouldn't bring down the whole agent.

I'm planning to use a circuit breaker pattern. Track failures per tool. After N consecutive failures, stop calling it. After a timeout period, try once more. If it succeeds, resume normal operation. If it fails again, back to blocked state.

Might be overkill, but I've been bitten by cascading failures before. Better to have the protection and not need it.

## Things I learned

**Architecture emerges from doing**

I didn't start with the DTO pattern. I started with simple Codable conformance. The problems surfaced during implementation. The solution emerged from those problems.

Don't over-design upfront. Build something, learn from it, refactor when you have real information.

**Separation has costs**

The DTO pattern added 500 lines of code. More files. More indirection. But it bought me clean boundaries and easier evolution. That's the trade-off.

For this project, worth it. For a simple CRUD app? Probably not.

**Builders aren't always worth it**

The builder pattern added ~300 lines. But it made the construction API so much better. Every call site got cleaner. Developer time saved compounds.

Worth it for complex, frequently-used types. Not worth it for simple structs with 2-3 fields.

**Throw, don't crash**

Making `build()` throw instead of crash was the right call. More verbose at call sites, but it's a public SDK. Users need to be able to handle errors.

In internal code? Maybe crash is fine. In library code? Always prefer throwing.

**Tests are your refactoring safety net**

I have 339 tests. When I did the DTO refactor, I touched 45 test files. Every single one caught issues during migration. Type mismatches. Missing conversions. Edge cases I'd forgotten.

The tests aren't overhead. They're the thing that lets you refactor fearlessly.

## Some technical details worth noting

**Value semantics everywhere**

Almost everything is a struct. Messages are structs. Events are structs. The builder is a struct. This gives thread safety for free and makes behavior more predictable.

Classes when you need reference semantics or inheritance. Structs for everything else.

**Protocol-oriented design**

The Message protocol defines the contract:

```swift
public protocol Message: Sendable, Hashable {
    var id: String { get }
    var role: Role { get }
}
```

Concrete types implement it:

```swift
public struct UserMessage: Message { ... }
public struct AssistantMessage: Message { ... }
```

Polymorphic collections just work: `[any Message]`

This is more Swift-y than class hierarchies. Compose protocols instead of inheriting classes.

**Forward compatibility**

The event decoder has two modes. Strict mode (default) throws errors for unknown events. Tolerant mode returns UnknownEvent for events it doesn't recognize.

```swift
var config = AGUIEventDecoder.Configuration()
config.unknownEventStrategy = .returnUnknown
let decoder = AGUIEventDecoder(config: config)

let event = try decoder.decode(data)
if let unknown = event as? UnknownEvent {
    // log it, forward it, or ignore it
}
```

This handles protocol evolution. When the spec adds new event types, older SDK versions don't crash. They just get UnknownEvent instances.

Good for production. When the protocol evolves faster than SDK updates, apps keep working.

## Wrapping up

Building AGUISwift has been a good exercise in practical architecture. Not theoretical purity, but real-world trade-offs. What actually works.

The DTO pattern emerged from real problems. The builder pattern solved real usability issues. Throwing instead of crashing gives users real error recovery.

Next up is the transport layer and high-level APIs. If the foundation is solid (and I think it is), building upward should be straightforward. If I missed something, I'll find out and adapt.

That's the process. Build, measure, learn, refactor. Repeat.

The SDK is open source: [github.com/paduh/ag-ui-swift](https://github.com/paduh/ag-ui-swift)

If you're working on something similar or have thoughts on the patterns I've used, I'd love to hear about it.
