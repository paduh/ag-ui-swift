// RunAgentInputBuilder.swift
// AGUISwift

import Foundation

/// Builder for constructing `RunAgentInput` instances with a fluent interface.
///
/// `RunAgentInputBuilder` provides an ergonomic way to construct complex `RunAgentInput`
/// instances through method chaining, making the code more readable and reducing
/// errors when working with multiple optional parameters.
///
/// ## Basic Usage
///
/// ```swift
/// let input = RunAgentInput.builder()
///     .threadId("thread-123")
///     .runId("run-456")
///     .build()
/// ```
///
/// ## Building Complex Inputs
///
/// ```swift
/// let input = RunAgentInput.builder()
///     .threadId("chat-session-1")
///     .runId("run-1")
///     .message(DeveloperMessage(id: "dev-1", content: "You are helpful"))
///     .message(UserMessage(id: "user-1", content: "Hello!"))
///     .tool(weatherTool)
///     .contextItem(Context(description: "location", value: "SF"))
///     .build()
/// ```
///
/// ## Incremental Building
///
/// ```swift
/// let builder = RunAgentInput.builder()
///     .threadId("thread-1")
///     .runId("run-1")
///
/// // Add messages conditionally
/// if includeSystemPrompt {
///     builder.message(SystemMessage(id: "sys-1", content: "Be concise"))
/// }
///
/// let input = builder.build()
/// ```
///
/// ## Thread Safety
///
/// The builder is `Sendable` and thread-safe. However, you should not mutate
/// a builder instance from multiple threads concurrently. Instead, use separate
/// builder instances per thread or synchronize access appropriately.
///
/// - SeeAlso: `RunAgentInput`
public final class RunAgentInputBuilder: Sendable {

    // Use nonisolated(unsafe) for mutable state in a Sendable class
    // This is safe because builders are typically used in a single-threaded context
    nonisolated(unsafe) private var _threadId: String?
    nonisolated(unsafe) private var _runId: String?
    nonisolated(unsafe) private var _parentRunId: String?
    nonisolated(unsafe) private var _state = Data("{}".utf8)
    nonisolated(unsafe) private var _messages: [any Message] = []
    nonisolated(unsafe) private var _tools: [Tool] = []
    nonisolated(unsafe) private var _context: [Context] = []
    nonisolated(unsafe) private var _forwardedProps = Data("{}".utf8)

    /// Creates a new builder instance.
    public init() {}

    // MARK: - Required Fields

    /// Sets the conversation thread identifier.
    ///
    /// - Parameter threadId: The thread identifier
    /// - Returns: The builder instance for method chaining
    @discardableResult
    public func threadId(_ threadId: String) -> Self {
        _threadId = threadId
        return self
    }

    /// Sets the unique identifier for this run.
    ///
    /// - Parameter runId: The run identifier
    /// - Returns: The builder instance for method chaining
    @discardableResult
    public func runId(_ runId: String) -> Self {
        _runId = runId
        return self
    }

    // MARK: - Optional Fields

    /// Sets the parent run identifier for nested agent calls.
    ///
    /// - Parameter parentRunId: The parent run identifier
    /// - Returns: The builder instance for method chaining
    @discardableResult
    public func parentRunId(_ parentRunId: String) -> Self {
        _parentRunId = parentRunId
        return self
    }

    /// Sets the state data as JSON.
    ///
    /// - Parameter state: The state data
    /// - Returns: The builder instance for method chaining
    @discardableResult
    public func state(_ state: Data) -> Self {
        _state = state
        return self
    }

    /// Sets the forwarded properties as JSON.
    ///
    /// - Parameter forwardedProps: The forwarded properties data
    /// - Returns: The builder instance for method chaining
    @discardableResult
    public func forwardedProps(_ forwardedProps: Data) -> Self {
        _forwardedProps = forwardedProps
        return self
    }

    // MARK: - Messages

    /// Adds a single message to the conversation history.
    ///
    /// Can be called multiple times to add messages incrementally.
    ///
    /// - Parameter message: The message to add
    /// - Returns: The builder instance for method chaining
    @discardableResult
    public func message(_ message: any Message) -> Self {
        _messages.append(message)
        return self
    }

    /// Sets the complete message array, replacing any previously added messages.
    ///
    /// - Parameter messages: The array of messages
    /// - Returns: The builder instance for method chaining
    @discardableResult
    public func messages(_ messages: [any Message]) -> Self {
        _messages = messages
        return self
    }

    // MARK: - Tools

    /// Adds a single tool to the available tools.
    ///
    /// Can be called multiple times to add tools incrementally.
    ///
    /// - Parameter tool: The tool to add
    /// - Returns: The builder instance for method chaining
    @discardableResult
    public func tool(_ tool: Tool) -> Self {
        _tools.append(tool)
        return self
    }

    /// Sets the complete tools array, replacing any previously added tools.
    ///
    /// - Parameter tools: The array of tools
    /// - Returns: The builder instance for method chaining
    @discardableResult
    public func tools(_ tools: [Tool]) -> Self {
        _tools = tools
        return self
    }

    // MARK: - Context

    /// Adds a single context item to the contextual information.
    ///
    /// Can be called multiple times to add context items incrementally.
    ///
    /// - Parameter item: The context item to add
    /// - Returns: The builder instance for method chaining
    @discardableResult
    public func contextItem(_ item: Context) -> Self {
        _context.append(item)
        return self
    }

    /// Sets the complete context array, replacing any previously added context items.
    ///
    /// - Parameter context: The array of context items
    /// - Returns: The builder instance for method chaining
    @discardableResult
    public func context(_ context: [Context]) -> Self {
        _context = context
        return self
    }

    // MARK: - Build

    /// Builds and returns a `RunAgentInput` instance.
    ///
    /// - Returns: A configured `RunAgentInput` instance
    /// - Precondition: `threadId` and `runId` must be set before calling build
    ///
    /// Example:
    /// ```swift
    /// let input = RunAgentInput.builder()
    ///     .threadId("thread-1")
    ///     .runId("run-1")
    ///     .build()
    /// ```
    public func build() -> RunAgentInput {
        guard let threadId = _threadId else {
            preconditionFailure("threadId is required")
        }
        guard let runId = _runId else {
            preconditionFailure("runId is required")
        }

        return RunAgentInput(
            threadId: threadId,
            runId: runId,
            parentRunId: _parentRunId,
            state: _state,
            messages: _messages,
            tools: _tools,
            context: _context,
            forwardedProps: _forwardedProps
        )
    }
}

// MARK: - RunAgentInput Extension

extension RunAgentInput {
    /// Creates a new builder for constructing `RunAgentInput` instances.
    ///
    /// Provides a fluent interface for building complex inputs with method chaining.
    ///
    /// - Returns: A new `RunAgentInputBuilder` instance
    ///
    /// Example:
    /// ```swift
    /// let input = RunAgentInput.builder()
    ///     .threadId("thread-123")
    ///     .runId("run-456")
    ///     .message(UserMessage(id: "msg-1", content: "Hello"))
    ///     .build()
    /// ```
    public static func builder() -> RunAgentInputBuilder {
        RunAgentInputBuilder()
    }
}
