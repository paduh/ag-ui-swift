# AGUIClient Implementation Plan

## Executive Summary

This document outlines the implementation plan for AGUIClient, the transport layer of AGUISwift. Based on analysis of the AG-UI protocol specification and the Kotlin reference implementation, this plan provides a phased approach to building a production-ready HTTP client with Server-Sent Events (SSE) streaming support.

**Timeline**: 2-3 weeks
**Complexity**: Medium-High
**Dependencies**: AGUICore (complete)

## Architecture Overview

AGUIClient implements the transport layer between applications and AG-UI agents. It follows the protocol's core abstraction:

```swift
// Protocol's fundamental contract
type RunAgent = () -> AsyncSequence<AGUIEvent>
```

### Module Structure

```
AGUIClient/
├── Transport/
│   ├── HttpAgent.swift              # Main HTTP client
│   ├── HttpAgentConfiguration.swift # Configuration
│   └── HttpTransport.swift          # Low-level HTTP
├── Streaming/
│   ├── SseParser.swift              # Server-Sent Events parser
│   ├── EventStream.swift            # AsyncSequence wrapper
│   └── StreamBuffer.swift           # Backpressure handling
├── State/
│   ├── StateManager.swift           # State synchronization
│   └── PatchApplicator.swift        # JSON Patch (RFC 6902)
├── Errors/
│   └── ClientError.swift            # Error types
└── AGUIClient.swift                 # Public facade
```

## Protocol Requirements

From the AG-UI specification:

### Request Format (RunAgentInput)

```swift
public struct RunAgentInput: Encodable {
    let threadId: String
    let runId: String
    let parentRunId: String?
    let state: Data
    let messages: [any Message]
    let tools: [Tool]
    let context: [Context]
    let forwardedProps: Data
}
```

Already implemented in AGUICore with builder pattern.

### Response Format (Event Stream)

Server responds with Server-Sent Events (SSE) containing AG-UI events:

```
data: {"type":"RUN_STARTED","threadId":"...","runId":"..."}

data: {"type":"TEXT_MESSAGE_START","messageId":"msg-1"}

data: {"type":"TEXT_MESSAGE_CHUNK","messageId":"msg-1","delta":"Hello"}

data: {"type":"TEXT_MESSAGE_END","messageId":"msg-1"}

data: {"type":"RUN_FINISHED","threadId":"...","runId":"..."}
```

### Transport Specification

**HTTP Method**: POST
**Endpoint**: `/run` (or custom endpoint)
**Content-Type**: `application/json`
**Accept**: `text/event-stream`
**Connection**: Keep-Alive for streaming

## Phase 1: Core HTTP Transport (Week 1, Days 1-3)

### 1.1 HttpAgentConfiguration

Configuration object for HTTP client:

```swift
public struct HttpAgentConfiguration {
    public var baseURL: URL
    public var timeout: TimeInterval
    public var retryPolicy: RetryPolicy
    public var headers: [String: String]

    public enum RetryPolicy {
        case none
        case fixed(maxAttempts: Int, delay: TimeInterval)
        case exponentialBackoff(maxAttempts: Int, baseDelay: TimeInterval)
    }

    public init(baseURL: URL) {
        self.baseURL = baseURL
        self.timeout = 120.0  // Long timeout for streaming
        self.retryPolicy = .none
        self.headers = [:]
    }
}
```

**Design Decision**: Value type (struct) for thread safety and immutability.

**Trade-off**: Configuration is copied on modification, but configurations are created once and reused.

### 1.2 HttpTransport

Low-level HTTP transport using URLSession:

```swift
actor HttpTransport {
    private let session: URLSession
    private let configuration: HttpAgentConfiguration

    init(configuration: HttpAgentConfiguration) {
        self.configuration = configuration

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeout
        sessionConfig.httpAdditionalHeaders = configuration.headers
        self.session = URLSession(configuration: sessionConfig)
    }

    func execute(
        endpoint: String,
        input: RunAgentInput
    ) async throws -> URLSession.AsyncBytes {
        let url = configuration.baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

        // Encode RunAgentInput to JSON
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(input)

        // Execute request and get streaming response
        let (bytes, response) = try await session.bytes(for: request)

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClientError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw ClientError.httpError(statusCode: httpResponse.statusCode)
        }

        return bytes
    }
}
```

**Design Decision**: Use actor for thread-safe URLSession access.

**Trade-off**: Actor isolation adds slight overhead, but prevents data races in concurrent scenarios.

**Implementation Notes**:
- URLSession.bytes(for:) returns AsyncSequence of bytes
- Long timeout (120s) accommodates slow agent responses
- Accept header signals we expect SSE stream

### 1.3 ClientError

Comprehensive error types:

```swift
public enum ClientError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case networkError(Error)
    case decodingError(Error)
    case streamError(String)
    case timeout
    case cancelled
}

extension ClientError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL configuration"
        case .invalidResponse:
            return "Received invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode event: \(error.localizedDescription)"
        case .streamError(let message):
            return "Stream error: \(message)"
        case .timeout:
            return "Request timed out"
        case .cancelled:
            return "Request was cancelled"
        }
    }
}
```

**Testing Strategy**:
- Unit tests for configuration validation
- Integration tests with mock server
- Network error simulation

## Phase 2: SSE Parser (Week 1, Days 4-5)

### 2.1 SSE Protocol

Server-Sent Events format:

```
event: message
data: {"type":"TEXT_MESSAGE_CHUNK","delta":"Hello"}
id: 123

data: {"type":"RUN_FINISHED"}

```

**Key Features**:
- Lines starting with `data:` contain payload
- Multiple `data:` lines concatenate with newlines
- Empty line signals end of event
- `id:` field for event IDs (reconnection)
- `event:` field for event types (usually omitted for default)

### 2.2 SseParser Implementation

Incremental parser that handles partial chunks:

```swift
public struct SseParser {
    private var buffer: String = ""

    public init() {}

    public mutating func parse(_ chunk: String) -> [SseEvent] {
        buffer += chunk
        var events: [SseEvent] = []

        // Split on double newline (event separator)
        let parts = buffer.components(separatedBy: "\n\n")

        // Keep last part in buffer (might be incomplete)
        buffer = parts.last ?? ""

        // Process complete events
        for part in parts.dropLast() where !part.isEmpty {
            if let event = parseEvent(part) {
                events.append(event)
            }
        }

        return events
    }

    private func parseEvent(_ text: String) -> SseEvent? {
        var data: [String] = []
        var id: String?
        var eventType: String?

        for line in text.components(separatedBy: "\n") {
            if line.hasPrefix("data:") {
                let payload = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                data.append(payload)
            } else if line.hasPrefix("id:") {
                id = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("event:") {
                eventType = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            }
            // Ignore comments (lines starting with :)
        }

        guard !data.isEmpty else { return nil }

        // Concatenate multiple data lines with newlines
        let payload = data.joined(separator: "\n")

        return SseEvent(
            data: payload,
            id: id,
            event: eventType ?? "message"
        )
    }

    public mutating func reset() {
        buffer = ""
    }
}

public struct SseEvent {
    public let data: String
    public let id: String?
    public let event: String
}
```

**Design Decision**: Mutable struct with incremental parsing.

**Trade-off**: Requires `var` at call site, but enables efficient streaming without buffering entire response.

**Edge Cases to Handle**:
- Partial UTF-8 sequences across chunks
- Very long data lines
- Multiple data fields per event
- Empty events (heartbeat)

### 2.3 Testing Strategy

Critical tests for SSE parser:

```swift
func testSingleEvent() {
    var parser = SseParser()
    let events = parser.parse("data: {\"test\":\"value\"}\n\n")
    XCTAssertEqual(events.count, 1)
    XCTAssertEqual(events[0].data, "{\"test\":\"value\"}")
}

func testPartialChunks() {
    var parser = SseParser()

    // First chunk is incomplete
    var events = parser.parse("data: {\"te")
    XCTAssertEqual(events.count, 0)

    // Complete the event
    events = parser.parse("st\":\"value\"}\n\n")
    XCTAssertEqual(events.count, 1)
}

func testMultipleDataLines() {
    var parser = SseParser()
    let events = parser.parse("data: line1\ndata: line2\n\n")
    XCTAssertEqual(events.count, 1)
    XCTAssertEqual(events[0].data, "line1\nline2")
}

func testEventWithId() {
    var parser = SseParser()
    let events = parser.parse("id: 123\ndata: test\n\n")
    XCTAssertEqual(events[0].id, "123")
}
```

## Phase 3: Event Streaming (Week 2, Days 1-2)

### 3.1 EventStream

AsyncSequence wrapper that combines HTTP transport, SSE parsing, and event decoding:

```swift
public struct EventStream: AsyncSequence {
    public typealias Element = any AGUIEvent

    private let bytes: URLSession.AsyncBytes
    private let decoder: AGUIEventDecoder

    init(bytes: URLSession.AsyncBytes, decoder: AGUIEventDecoder) {
        self.bytes = bytes
        self.decoder = decoder
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(bytes: bytes.makeAsyncIterator(), decoder: decoder)
    }

    public struct AsyncIterator: AsyncIteratorProtocol {
        private var bytesIterator: URLSession.AsyncBytes.AsyncIterator
        private let decoder: AGUIEventDecoder
        private var sseParser = SseParser()
        private var eventQueue: [any AGUIEvent] = []

        init(bytes: URLSession.AsyncBytes.AsyncIterator, decoder: AGUIEventDecoder) {
            self.bytesIterator = bytes
            self.decoder = decoder
        }

        public mutating func next() async throws -> (any AGUIEvent)? {
            // Return queued events first
            if !eventQueue.isEmpty {
                return eventQueue.removeFirst()
            }

            // Read bytes and parse SSE events
            while let byte = try await bytesIterator.next() {
                // Accumulate bytes into string
                // (Handle UTF-8 decoding properly)
                let chunk = String(bytes: [byte], encoding: .utf8) ?? ""

                // Parse SSE events from chunk
                let sseEvents = sseParser.parse(chunk)

                // Decode AG-UI events from SSE data
                for sseEvent in sseEvents {
                    guard let data = sseEvent.data.data(using: .utf8) else {
                        continue
                    }

                    do {
                        let event = try decoder.decode(data)
                        eventQueue.append(event)
                    } catch {
                        // Log decoding error but continue stream
                        // (Could make error handling configurable)
                        print("Warning: Failed to decode event: \(error)")
                    }
                }

                // Return first decoded event
                if !eventQueue.isEmpty {
                    return eventQueue.removeFirst()
                }
            }

            return nil  // Stream ended
        }
    }
}
```

**Design Decision**: Process byte-by-byte to handle partial UTF-8 sequences.

**Trade-off**: Slightly slower than buffering, but more robust. Could optimize later with line buffering.

**Error Handling**: Non-fatal decoding errors logged but don't stop stream. Critical errors propagate.

### 3.2 Improved UTF-8 Handling

The byte-by-byte approach above is oversimplified. Better approach:

```swift
public struct AsyncIterator: AsyncIteratorProtocol {
    private var bytesIterator: URLSession.AsyncBytes.AsyncIterator
    private let decoder: AGUIEventDecoder
    private var sseParser = SseParser()
    private var eventQueue: [any AGUIEvent] = []
    private var utf8Buffer: [UInt8] = []

    public mutating func next() async throws -> (any AGUIEvent)? {
        if !eventQueue.isEmpty {
            return eventQueue.removeFirst()
        }

        while let byte = try await bytesIterator.next() {
            utf8Buffer.append(byte)

            // Try to decode accumulated bytes as UTF-8
            if let string = String(bytes: utf8Buffer, encoding: .utf8) {
                // Successful decode, process the chunk
                utf8Buffer.removeAll()

                let sseEvents = sseParser.parse(string)
                for sseEvent in sseEvents {
                    if let data = sseEvent.data.data(using: .utf8) {
                        if let event = try? decoder.decode(data) {
                            eventQueue.append(event)
                        }
                    }
                }

                if !eventQueue.isEmpty {
                    return eventQueue.removeFirst()
                }
            } else if utf8Buffer.count > 4 {
                // Invalid UTF-8 sequence (UTF-8 max 4 bytes)
                // Skip invalid bytes and try to resync
                utf8Buffer.removeFirst()
            }
        }

        return nil
    }
}
```

## Phase 4: HttpAgent Public API (Week 2, Days 3-4)

### 4.1 HttpAgent Implementation

Main client API:

```swift
public struct HttpAgent {
    private let transport: HttpTransport
    private let configuration: HttpAgentConfiguration
    private let eventDecoder: AGUIEventDecoder

    public init(configuration: HttpAgentConfiguration) {
        self.configuration = configuration
        self.transport = HttpTransport(configuration: configuration)
        self.eventDecoder = AGUIEventDecoder()
    }

    public convenience init(baseURL: URL) {
        self.init(configuration: HttpAgentConfiguration(baseURL: baseURL))
    }

    /// Execute agent run and stream events
    public func run(_ input: RunAgentInput) async throws -> EventStream {
        let bytes = try await transport.execute(endpoint: "/run", input: input)
        return EventStream(bytes: bytes, decoder: eventDecoder)
    }

    /// Execute agent run with builder
    public func run(
        threadId: String,
        runId: String,
        configure: (RunAgentInputBuilder) -> RunAgentInputBuilder = { $0 }
    ) async throws -> EventStream {
        let input = try configure(
            RunAgentInput.builder()
                .threadId(threadId)
                .runId(runId)
        ).build()

        return try await run(input)
    }
}
```

**Usage Examples**:

```swift
// Simple usage
let agent = HttpAgent(baseURL: URL(string: "https://agent.example.com")!)

for try await event in try await agent.run(threadId: "t1", runId: "r1") { builder in
    builder.message(UserMessage(id: "msg1", content: "Hello!"))
} {
    print(event)
}

// Advanced usage with full control
let input = try RunAgentInput.builder()
    .threadId("thread-1")
    .runId("run-1")
    .message(DeveloperMessage(id: "dev1", content: "You are helpful"))
    .message(UserMessage(id: "user1", content: "Hello!"))
    .tool(weatherTool)
    .build()

for try await event in try await agent.run(input) {
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

### 4.2 Error Handling

```swift
do {
    for try await event in try await agent.run(input) {
        // Process events
    }
} catch ClientError.httpError(let code) {
    print("HTTP error: \(code)")
} catch ClientError.networkError(let error) {
    print("Network error: \(error)")
} catch {
    print("Unexpected error: \(error)")
}
```

## Phase 5: Backpressure and Buffering (Week 2, Day 5)

### 5.1 StreamBuffer

Handle backpressure when consumer is slower than producer:

```swift
actor StreamBuffer<Element> {
    private var buffer: [Element] = []
    private let maxSize: Int
    private let strategy: BufferingStrategy

    enum BufferingStrategy {
        case dropOldest  // Drop oldest when full
        case dropNewest  // Drop newest when full
        case throwError  // Throw error when full
    }

    init(maxSize: Int = 100, strategy: BufferingStrategy = .dropOldest) {
        self.maxSize = maxSize
        self.strategy = strategy
    }

    func append(_ element: Element) throws {
        if buffer.count >= maxSize {
            switch strategy {
            case .dropOldest:
                buffer.removeFirst()
            case .dropNewest:
                return  // Don't add new element
            case .throwError:
                throw ClientError.streamError("Buffer full")
            }
        }
        buffer.append(element)
    }

    func next() -> Element? {
        guard !buffer.isEmpty else { return nil }
        return buffer.removeFirst()
    }

    var isEmpty: Bool {
        buffer.isEmpty
    }
}
```

**Design Decision**: Drop oldest events by default for streaming text.

**Trade-off**: May miss intermediate chunks, but prevents memory growth. Critical events (runFinished, runError) should be prioritized.

**Advanced**: Priority queue that never drops critical events:

```swift
actor PriorityStreamBuffer {
    private var normalBuffer: [any AGUIEvent] = []
    private var priorityBuffer: [any AGUIEvent] = []
    private let maxNormalSize: Int

    private let criticalTypes: Set<EventType> = [
        .runFinished, .runError, .textMessageEnd, .toolCallEnd
    ]

    func append(_ event: any AGUIEvent) {
        if criticalTypes.contains(event.eventType) {
            priorityBuffer.append(event)
        } else {
            if normalBuffer.count >= maxNormalSize {
                normalBuffer.removeFirst()
            }
            normalBuffer.append(event)
        }
    }

    func next() -> (any AGUIEvent)? {
        // Priority events first
        if !priorityBuffer.isEmpty {
            return priorityBuffer.removeFirst()
        }
        return normalBuffer.isEmpty ? nil : normalBuffer.removeFirst()
    }
}
```

## Phase 6: State Management (Week 3, Days 1-2)

### 6.1 StateManager

Handles state snapshots and delta patches:

```swift
public actor StateManager {
    private var currentState: Data = Data("{}".utf8)
    private let patchApplicator = PatchApplicator()

    public func handleSnapshot(_ event: StateSnapshotEvent) {
        currentState = event.state
    }

    public func handleDelta(_ event: StateDeltaEvent) throws {
        currentState = try patchApplicator.apply(
            patch: event.patch,
            to: currentState
        )
    }

    public func getState() -> Data {
        currentState
    }

    public func reset() {
        currentState = Data("{}".utf8)
    }
}
```

### 6.2 PatchApplicator

Implements RFC 6902 JSON Patch:

```swift
public struct PatchApplicator {
    public func apply(patch: Data, to state: Data) throws -> Data {
        // Parse current state as JSON
        guard let stateJSON = try? JSONSerialization.jsonObject(with: state) else {
            throw ClientError.decodingError(NSError(domain: "Invalid state JSON", code: 1))
        }

        // Parse patch operations
        struct PatchOperation: Decodable {
            let op: String
            let path: String
            let value: Any?
        }

        let operations = try JSONDecoder().decode([PatchOperation].self, from: patch)

        var mutableState = stateJSON

        for operation in operations {
            switch operation.op {
            case "add":
                mutableState = try applyAdd(path: operation.path, value: operation.value, to: mutableState)
            case "remove":
                mutableState = try applyRemove(path: operation.path, from: mutableState)
            case "replace":
                mutableState = try applyReplace(path: operation.path, value: operation.value, to: mutableState)
            case "move":
                // Implement move operation
                break
            case "copy":
                // Implement copy operation
                break
            case "test":
                // Implement test operation
                break
            default:
                throw ClientError.streamError("Unknown patch operation: \(operation.op)")
            }
        }

        return try JSONSerialization.data(withJSONObject: mutableState)
    }

    // Implementation of individual patch operations...
}
```

**Note**: Full JSON Patch implementation is complex. Consider using a third-party library or implementing incrementally (add/replace/remove first, then move/copy/test).

## Testing Strategy

### Unit Tests

**Transport Layer**:
- ✅ Configuration validation
- ✅ URL construction
- ✅ Request header setup
- ✅ Error mapping

**SSE Parser**:
- ✅ Single event parsing
- ✅ Multiple events
- ✅ Partial chunks
- ✅ Multi-line data fields
- ✅ Event IDs
- ✅ Empty events (heartbeat)
- ✅ Edge cases (very long lines, etc.)

**Event Stream**:
- ✅ Event decoding
- ✅ Error handling
- ✅ Stream completion
- ✅ Cancellation

### Integration Tests

**Mock Server**:
Create a simple HTTP server that returns SSE events for testing:

```swift
final class MockAgentServer {
    private var server: NWListener?

    func start(port: UInt16 = 8080) throws {
        // Implement simple HTTP server using Network framework
        // Respond to /run with SSE stream
    }

    func sendEvent(_ event: AGUIEvent) {
        // Send event to connected clients
    }

    func stop() {
        server?.cancel()
    }
}

final class HttpAgentIntegrationTests: XCTestCase {
    var server: MockAgentServer!

    override func setUp() async throws {
        server = MockAgentServer()
        try server.start()
    }

    func testEndToEndEventStreaming() async throws {
        let agent = HttpAgent(baseURL: URL(string: "http://localhost:8080")!)

        let input = try RunAgentInput.builder()
            .threadId("test")
            .runId("run1")
            .build()

        Task {
            // Server sends events
            try await Task.sleep(for: .milliseconds(100))
            server.sendEvent(RunStartedEvent(threadId: "test", runId: "run1"))
            server.sendEvent(TextMessageChunkEvent(messageId: "msg1", delta: "Hello"))
            server.sendEvent(RunFinishedEvent(threadId: "test", runId: "run1"))
        }

        var events: [any AGUIEvent] = []
        for try await event in try await agent.run(input) {
            events.append(event)
        }

        XCTAssertEqual(events.count, 3)
        XCTAssertTrue(events[0] is RunStartedEvent)
        XCTAssertTrue(events[1] is TextMessageChunkEvent)
        XCTAssertTrue(events[2] is RunFinishedEvent)
    }
}
```

### Performance Tests

- Stream throughput (events/second)
- Memory usage under load
- Connection handling (multiple concurrent streams)
- Large event handling

## Implementation Checklist

### Phase 1: Core Transport (Week 1, Days 1-3)
- [ ] HttpAgentConfiguration struct
- [ ] HttpTransport actor with URLSession
- [ ] ClientError enum with LocalizedError
- [ ] Basic unit tests
- [ ] Integration test setup

### Phase 2: SSE Parser (Week 1, Days 4-5)
- [ ] SseParser with incremental parsing
- [ ] SseEvent struct
- [ ] UTF-8 handling
- [ ] Comprehensive parser tests
- [ ] Edge case tests

### Phase 3: Event Streaming (Week 2, Days 1-2)
- [ ] EventStream AsyncSequence
- [ ] AsyncIterator implementation
- [ ] Event decoding integration
- [ ] Error handling
- [ ] Stream tests

### Phase 4: Public API (Week 2, Days 3-4)
- [ ] HttpAgent struct
- [ ] Convenience initializers
- [ ] Builder-based run method
- [ ] API documentation
- [ ] Usage examples

### Phase 5: Backpressure (Week 2, Day 5)
- [ ] StreamBuffer actor
- [ ] Buffering strategies
- [ ] Priority queue for critical events
- [ ] Buffer tests
- [ ] Load tests

### Phase 6: State Management (Week 3, Days 1-2)
- [ ] StateManager actor
- [ ] PatchApplicator struct
- [ ] RFC 6902 operations (add, remove, replace)
- [ ] State synchronization tests
- [ ] Patch application tests

### Polish (Week 3, Days 3-4)
- [ ] Documentation review
- [ ] Example app
- [ ] Performance optimization
- [ ] Memory leak testing
- [ ] Thread safety audit

## API Design Summary

### Public Types

```swift
// Client
public struct HttpAgent
public struct HttpAgentConfiguration
public enum ClientError: Error

// Streaming
public struct EventStream: AsyncSequence
public struct SseParser
public struct SseEvent

// State
public actor StateManager
public struct PatchApplicator
```

### Usage Pattern

```swift
// 1. Create agent
let agent = HttpAgent(baseURL: agentURL)

// 2. Build input
let input = try RunAgentInput.builder()
    .threadId("thread-1")
    .runId("run-1")
    .message(UserMessage(id: "msg1", content: "Hello"))
    .build()

// 3. Stream events
for try await event in try await agent.run(input) {
    switch event.eventType {
    case .textMessageChunk:
        // Handle chunk
    case .runFinished:
        // Handle completion
    default:
        break
    }
}
```

## Next Steps After AGUIClient

Once AGUIClient is complete, implement:

1. **AGUIAgentSDK** - High-level convenience APIs
   - AgUiAgent (stateless)
   - StatefulAgUiAgent (conversation history)
   - Message accumulation helpers

2. **AGUITools** - Tool execution framework
   - ToolExecutor protocol
   - ToolRegistry
   - Circuit breaker for resilience

3. **Examples** - Sample applications
   - iOS chat app
   - macOS document Q&A
   - Integration examples

## References

- AG-UI Protocol: https://docs.ag-ui.com/
- RFC 6902 (JSON Patch): https://datatracker.ietf.org/doc/html/rfc6902
- Server-Sent Events: https://html.spec.whatwg.org/multipage/server-sent-events.html
- Swift Concurrency: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/
