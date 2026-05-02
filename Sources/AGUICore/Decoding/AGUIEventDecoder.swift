// Copyright (c) 2025 Perfect Aduh. MIT License. See LICENSE for details.

import Foundation

/// Decoder for AG-UI protocol events with polymorphic deserialization.
///
/// `AGUIEventDecoder` is thread-safe and can be used concurrently. The decoder itself
/// is immutable after initialization, and all configuration is `Sendable`.
///
/// - SeeAlso: `AGUIEvent`, `EventType`, `EventDecodingError`, `UnknownEvent`
public struct AGUIEventDecoder: Sendable {

    /// Handler function type for decoding a specific event type.
    ///
    /// Each handler receives the raw JSON data and a `JSONDecoder`, and returns
    /// a decoded `AGUIEvent` instance. Handlers are responsible for:
    ///
    /// 1. Decoding the event-specific DTO from the JSON data
    /// 2. Converting the DTO to the domain event type
    /// 3. Preserving the raw event data for debugging/forwarding
    ///
    /// - Parameters:
    ///   - data: The raw JSON data for the event
    ///   - decoder: A `JSONDecoder` instance for decoding
    /// - Returns: A decoded `AGUIEvent` instance
    /// - Throws: `EventDecodingError` or `DecodingError` if decoding fails
    public typealias DecodeHandler = @Sendable (_ data: Data, _ decoder: JSONDecoder) throws -> any AGUIEvent

    /// Configuration options for the decoder.
    ///
    /// Use `Configuration` to customize decoder behavior, particularly how unknown
    /// or unsupported events are handled.
    public struct Configuration: Sendable {
        /// Strategy for handling unknown or unsupported event types.
        ///
        /// Defaults to `.throwError` (strict mode).
        public var unknownEventStrategy: UnknownEventStrategy = .throwError

        /// Creates a new configuration with default settings.
        public init() {}
    }

    /// Strategy for handling unknown or unsupported event types.
    ///
    /// - `.throwError`: Throw `EventDecodingError` when encountering unknown/unsupported events (strict mode)
    /// - `.returnUnknown`: Return `UnknownEvent` instances for unknown/unsupported events (tolerant mode)
    ///
    /// Tolerant mode is useful for:
    /// - Forward compatibility with future protocol extensions
    /// - Graceful degradation when some event types aren't implemented
    /// - Logging or forwarding events you don't understand yet
    public enum UnknownEventStrategy: Sendable {
        /// Throw an error when encountering unknown or unsupported events.
        ///
        /// This is the default behavior and ensures type safety by requiring
        /// all events to be properly decoded.
        case throwError

        /// Return `UnknownEvent` instances for unknown or unsupported events.
        ///
        /// Enables forward compatibility and graceful handling of events
        /// that aren't yet implemented or recognized.
        case returnUnknown
    }

    private let config: Configuration
    private let makeDecoder: @Sendable () -> JSONDecoder
    private let registry: [EventType: DecodeHandler]

    // MARK: - Initialization

    /// Creates a new `AGUIEventDecoder`.
    ///
    /// - Parameters:
    ///   - config: Configuration options for the decoder (defaults to strict mode)
    ///   - makeDecoder: Factory function for creating `JSONDecoder` instances (defaults to standard `JSONDecoder()`)
    ///   - registry: Dictionary mapping event types to their decode handlers (defaults to `defaultRegistry()`)
    ///
    /// The decoder uses the provided registry to determine which event types can be decoded.
    /// If no registry is provided, it uses `defaultRegistry()` which includes all lifecycle events.
    ///
    public init(
        config: Configuration = .init(),
        makeDecoder: @escaping @Sendable () -> JSONDecoder = {
            let d = JSONDecoder()
            d.keyDecodingStrategy = .convertFromSnakeCase
            return d
        },
        registry: [EventType: DecodeHandler] = AGUIEventDecoder.defaultRegistry()
    ) {
        self.config = config
        self.makeDecoder = makeDecoder
        self.registry = registry
    }

    // MARK: - Decoding

    /// Decodes JSON data into an `AGUIEvent` instance.
    ///
    /// The decoder performs polymorphic deserialization by:
    /// 1. Extracting the "type" field from the JSON
    /// 2. Looking up the appropriate decode handler in the registry
    /// 3. Invoking the handler to decode the event-specific data
    ///
    /// - Parameter data: The JSON data to decode
    /// - Returns: A decoded `AGUIEvent` instance (specific type depends on the "type" field)
    /// - Throws: `EventDecodingError` if decoding fails or the event type is unknown/unsupported (in strict mode)
    ///
    public func decode(_ data: Data) throws -> any AGUIEvent {
        let decoder = makeDecoder()

        let disc = try decodeTypeDiscriminator(from: data, decoder: decoder)

        // Transparent backward compat: remap legacy THINKING_* wire events to REASONING_*,
        // mirroring the TypeScript SDK's BackwardCompatibility_0_0_45 middleware.
        if let (remappedData, remappedType) = Self.remapThinkingEvent(data: data, typeRaw: disc.typeRaw) {
            guard let handler = registry[remappedType] else {
                return try handleMissingHandler(for: remappedType, typeRaw: disc.typeRaw, rawEvent: data)
            }
            return try executeHandler(handler, data: remappedData, decoder: decoder)
        }

        guard let type = EventType(rawValue: disc.typeRaw) else {
            return try handleUnknownEventType(typeRaw: disc.typeRaw, rawEvent: data)
        }

        guard let handler = registry[type] else {
            return try handleMissingHandler(for: type, typeRaw: disc.typeRaw, rawEvent: data)
        }

        return try executeHandler(handler, data: data, decoder: decoder)
    }

    /// Rewrites a legacy `THINKING_*` wire event to its `REASONING_*` equivalent.
    ///
    /// Agents built against protocol versions prior to 0.0.46 emit `THINKING_*` events.
    /// Rather than keeping deprecated event types in the public API, the decoder silently
    /// upgrades them — matching how the TypeScript SDK's `BackwardCompatibility_0_0_45`
    /// middleware handles the same transition.
    ///
    /// IDs are generated fresh per-event; the caller should not rely on cross-event ID
    /// correlation for events originating from a `THINKING_*` stream.
    ///
    /// - Parameters:
    ///   - data: Raw JSON bytes from the SSE stream.
    ///   - typeRaw: The `"type"` discriminator string already extracted from `data`.
    /// - Returns: Rewritten JSON + the target `EventType`, or `nil` if no remapping is needed.
    private static func remapThinkingEvent(data: Data, typeRaw: String) -> (Data, EventType)? {
        // Wire string → (target EventType, extra fields to inject)
        let mapping: [String: (EventType, [String: Any])] = [
            "THINKING_START": (.reasoningStart, ["messageId": UUID().uuidString]),
            "THINKING_END": (.reasoningEnd, ["messageId": UUID().uuidString]),
            "THINKING_TEXT_MESSAGE_START": (.reasoningMessageStart, [
                "messageId": UUID().uuidString,
                "role": "assistant",
            ]),
            "THINKING_TEXT_MESSAGE_CONTENT": (.reasoningMessageContent, ["messageId": UUID().uuidString]),
            "THINKING_TEXT_MESSAGE_END": (.reasoningMessageEnd, ["messageId": UUID().uuidString]),
        ]

        guard let (targetType, extraFields) = mapping[typeRaw] else { return nil }

        guard var jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        jsonObject["type"] = targetType.rawValue
        for (key, value) in extraFields {
            jsonObject[key] = value
        }

        guard let remappedData = try? JSONSerialization.data(withJSONObject: jsonObject) else {
            return nil
        }

        return (remappedData, targetType)
    }

    private func decodeTypeDiscriminator(from data: Data, decoder: JSONDecoder) throws -> TypeDiscriminator {
        do {
            return try decoder.decode(TypeDiscriminator.self, from: data)
        } catch let error as DecodingError {
            throw mapDecodingError(error)
        } catch {
            throw EventDecodingError.invalidJSON
        }
    }

    private func handleUnknownEventType(typeRaw: String, rawEvent: Data) throws -> any AGUIEvent {
        switch config.unknownEventStrategy {
        case .throwError:
            throw EventDecodingError.unknownEventType(typeRaw)
        case .returnUnknown:
            return UnknownEvent(typeRaw: typeRaw, rawEvent: rawEvent)
        }
    }

    private func handleMissingHandler(
        for type: EventType,
        typeRaw: String,
        rawEvent: Data
    ) throws -> any AGUIEvent {
        switch config.unknownEventStrategy {
        case .throwError:
            throw EventDecodingError.unsupportedEventType(type)
        case .returnUnknown:
            return UnknownEvent(typeRaw: typeRaw, rawEvent: rawEvent)
        }
    }

    private func executeHandler(
        _ handler: DecodeHandler,
        data: Data,
        decoder: JSONDecoder
    ) throws -> any AGUIEvent {
        do {
            return try handler(data, decoder)
        } catch let error as EventDecodingError {
            throw error
        } catch let error as DecodingError {
            throw mapDecodingError(error)
        } catch {
            throw EventDecodingError.decodingFailed(error.localizedDescription)
        }
    }

    // MARK: - Registry Management

    /// Returns the default registry of event type handlers.
    ///
    /// The default registry includes handlers for all lifecycle events:
    /// - `runStarted`, `runFinished`, `runError`
    /// - `stepStarted`, `stepFinished`
    ///
    /// Additional event categories (text messages, tool calls, state management, etc.)
    /// can be added by composing multiple registries together.
    ///
    /// - Returns: A dictionary mapping `EventType` to `DecodeHandler` functions
    ///
    /// Example of composing custom registries:
    /// ```swift
    /// let customRegistry = RegistryComposer.compose(
    ///     AGUIEventDecoder.defaultRegistry(),
    ///     MyCustomEventRegistry.registry()
    /// )
    /// let decoder = AGUIEventDecoder(registry: customRegistry)
    /// ```
    public static func defaultRegistry() -> [EventType: DecodeHandler] {
        RegistryComposer.compose(
            LifecycleEventRegistry.registry(),
            TextMessageEventRegistry.registry(),
            ToolCallEventRegistry.registry(),
            StateEventRegistry.registry(),
            SpecialEventRegistry.registry(),
            ReasoningEventRegistry.registry(),
            ActivityEventRegistry.registry()
        )
    }

    // MARK: - Error mapping

    private func mapDecodingError(_ error: DecodingError) -> EventDecodingError {
        func path(_ codingPath: [CodingKey]) -> String {
            let pathString = codingPath.map(\.stringValue).joined(separator: ".")
            return pathString.isEmpty ? "root" : pathString
        }

        switch error {
        case .keyNotFound(let key, _) where key.stringValue == "type":
            return .missingTypeField
        case .dataCorrupted:
            return .invalidJSON
        case .keyNotFound(let key, let ctx):
            return .decodingFailed("Missing key '\(key.stringValue)' at \(path(ctx.codingPath))")
        case .typeMismatch(let type, let ctx):
            return .decodingFailed("Type mismatch '\(type)' at \(path(ctx.codingPath))")
        case .valueNotFound(let type, let ctx):
            return .decodingFailed("Missing value '\(type)' at \(path(ctx.codingPath))")
        @unknown default:
            return .decodingFailed(String(describing: error))
        }
    }
}
