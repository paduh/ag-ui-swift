// RunAgentInput.swift
// AGUISwift

import Foundation

/// Input parameters for connecting to and executing an agent.
///
/// `RunAgentInput` represents the complete request body sent to an agent's
/// HTTP endpoint when initiating or continuing a conversation. It contains
/// all necessary information for the agent to process the request.
///
/// ## Core Identifiers
///
/// - **threadId**: Identifies the conversation thread
/// - **runId**: Unique identifier for this specific run/execution
/// - **parentRunId**: Optional parent run for nested agent calls
///
/// ## Execution Context
///
/// - **state**: Current state data passed to the agent
/// - **messages**: Conversation history
/// - **tools**: Available tools the agent can invoke
/// - **context**: Additional contextual information
/// - **forwardedProps**: Custom properties to forward to the agent
///
/// ## Usage Examples
///
/// ```swift
/// // Simple agent execution
/// let input = RunAgentInput(
///     threadId: "thread-123",
///     runId: "run-456"
/// )
///
/// // With conversation history
/// let messages: [any Message] = [
///     DeveloperMessage(id: "dev-1", content: "You are helpful"),
///     UserMessage(id: "user-1", content: "Hello!")
/// ]
///
/// let input = RunAgentInput(
///     threadId: "thread-123",
///     runId: "run-456",
///     messages: messages
/// )
///
/// // With tools and context
/// let tools = [
///     Tool(name: "get_weather", description: "Get weather", parameters: ...)
/// ]
///
/// let contexts = [
///     Context(description: "user_location", value: "San Francisco")
/// ]
///
/// let input = RunAgentInput(
///     threadId: "thread-123",
///     runId: "run-456",
///     messages: messages,
///     tools: tools,
///     context: contexts
/// )
/// ```
///
/// ## HTTP POST Request
///
/// This type is typically serialized to JSON and sent as the body of
/// a POST request to an agent's endpoint.
///
/// - SeeAlso: ``Message``, ``Tool``, ``Context``
public struct RunAgentInput: Sendable, Codable, Hashable {
    /// The conversation thread identifier.
    public let threadId: String

    /// The unique identifier for this run.
    public let runId: String

    /// Optional parent run identifier for nested agent calls.
    public let parentRunId: String?

    /// Current state data as JSON.
    ///
    /// Defaults to an empty JSON object.
    public let state: Data

    /// Conversation message history.
    ///
    /// Defaults to an empty array.
    public let messages: [any Message]

    /// Available tools the agent can invoke.
    ///
    /// Defaults to an empty array.
    public let tools: [Tool]

    /// Additional contextual information.
    ///
    /// Defaults to an empty array.
    public let context: [Context]

    /// Custom properties forwarded to the agent as JSON.
    ///
    /// Defaults to an empty JSON object.
    public let forwardedProps: Data

    /// Creates a new agent input.
    ///
    /// - Parameters:
    ///   - threadId: Conversation thread identifier
    ///   - runId: Unique run identifier
    ///   - parentRunId: Optional parent run identifier
    ///   - state: State data as JSON (defaults to empty object)
    ///   - messages: Message history (defaults to empty)
    ///   - tools: Available tools (defaults to empty)
    ///   - context: Context items (defaults to empty)
    ///   - forwardedProps: Custom properties as JSON (defaults to empty object)
    public init(
        threadId: String,
        runId: String,
        parentRunId: String? = nil,
        state: Data = Data("{}".utf8),
        messages: [any Message] = [],
        tools: [Tool] = [],
        context: [Context] = [],
        forwardedProps: Data = Data("{}".utf8)
    ) {
        self.threadId = threadId
        self.runId = runId
        self.parentRunId = parentRunId
        self.state = state
        self.messages = messages
        self.tools = tools
        self.context = context
        self.forwardedProps = forwardedProps
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case threadId
        case runId
        case parentRunId
        case state
        case messages
        case tools
        case context
        case forwardedProps
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode simple string fields
        threadId = try container.decode(String.self, forKey: .threadId)
        runId = try container.decode(String.self, forKey: .runId)
        parentRunId = try container.decodeIfPresent(String.self, forKey: .parentRunId)

        // Decode state as arbitrary JSON object and convert to Data
        if container.contains(.state) {
            let stateContainer = try container.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: .state)
            let stateObject = try stateContainer.decodeJSONObject()
            state = try JSONSerialization.data(withJSONObject: stateObject)
        } else {
            state = Data("{}".utf8)
        }

        // Decode messages array using MessageDecoder for polymorphic deserialization
        if container.contains(.messages) {
            var messagesContainer = try container.nestedUnkeyedContainer(forKey: .messages)
            let messagesArray = try messagesContainer.decodeJSONArray()

            let messageDecoder = MessageDecoder()
            messages = try messagesArray.map { messageObj in
                let messageData = try JSONSerialization.data(withJSONObject: messageObj)
                return try messageDecoder.decode(messageData)
            }
        } else {
            messages = []
        }

        // Decode tools and context arrays (these already conform to Codable)
        tools = try container.decodeIfPresent([Tool].self, forKey: .tools) ?? []
        context = try container.decodeIfPresent([Context].self, forKey: .context) ?? []

        // Decode forwardedProps as arbitrary JSON object and convert to Data
        if container.contains(.forwardedProps) {
            let propsContainer = try container.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: .forwardedProps)
            let propsObject = try propsContainer.decodeJSONObject()
            forwardedProps = try JSONSerialization.data(withJSONObject: propsObject)
        } else {
            forwardedProps = Data("{}".utf8)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Encode simple string fields
        try container.encode(threadId, forKey: .threadId)
        try container.encode(runId, forKey: .runId)
        try container.encodeIfPresent(parentRunId, forKey: .parentRunId)

        // Encode state as arbitrary JSON object
        let stateObject = try JSONSerialization.jsonObject(with: state)
        var stateContainer = container.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: .state)
        try stateContainer.encodeJSONObject(stateObject)

        // Encode messages as polymorphic array using helper
        var messagesArray: [Any] = []
        for message in messages {
            let messageData = try encodeMessage(message, encoder: encoder)
            let messageDict = try JSONSerialization.jsonObject(with: messageData)
            messagesArray.append(messageDict)
        }
        var messagesContainer = container.nestedUnkeyedContainer(forKey: .messages)
        try messagesContainer.encodeJSONArray(messagesArray)

        // Encode tools and context arrays (these already conform to Codable)
        try container.encode(tools, forKey: .tools)
        try container.encode(context, forKey: .context)

        // Encode forwardedProps as arbitrary JSON object
        let propsObject = try JSONSerialization.jsonObject(with: forwardedProps)
        var propsContainer = container.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: .forwardedProps)
        try propsContainer.encodeJSONObject(propsObject)
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(threadId)
        hasher.combine(runId)
        hasher.combine(parentRunId)
        hasher.combine(state)
        hasher.combine(tools)
        hasher.combine(context)
        hasher.combine(forwardedProps)
        // Messages not directly hashable due to protocol type
        hasher.combine(messages.count)
    }

    public static func == (lhs: RunAgentInput, rhs: RunAgentInput) -> Bool {
        lhs.threadId == rhs.threadId &&
            lhs.runId == rhs.runId &&
            lhs.parentRunId == rhs.parentRunId &&
            lhs.state == rhs.state &&
            lhs.messages.count == rhs.messages.count &&
            lhs.tools == rhs.tools &&
            lhs.context == rhs.context &&
            lhs.forwardedProps == rhs.forwardedProps
    }
}

// MARK: - Message Encoding Helpers

/// Encodes a message to JSON data using the appropriate DTO.
private func encodeMessage(_ message: any Message, encoder: Encoder) throws -> Data {
    let jsonEncoder = JSONEncoder()

    // Convert message to DTO and encode
    switch message.role {
    case .developer:
        guard let devMsg = message as? DeveloperMessage else {
            throw EncodingError.invalidValue(message, EncodingError.Context(
                codingPath: encoder.codingPath,
                debugDescription: "Message role is developer but type doesn't match"
            ))
        }
        return try encodeDeveloperMessage(devMsg, encoder: jsonEncoder)

    case .system:
        guard let sysMsg = message as? SystemMessage else {
            throw EncodingError.invalidValue(message, EncodingError.Context(
                codingPath: encoder.codingPath,
                debugDescription: "Message role is system but type doesn't match"
            ))
        }
        return try encodeSystemMessage(sysMsg, encoder: jsonEncoder)

    case .user:
        guard let userMsg = message as? UserMessage else {
            throw EncodingError.invalidValue(message, EncodingError.Context(
                codingPath: encoder.codingPath,
                debugDescription: "Message role is user but type doesn't match"
            ))
        }
        return try encodeUserMessage(userMsg, encoder: jsonEncoder)

    case .assistant:
        guard let assistantMsg = message as? AssistantMessage else {
            throw EncodingError.invalidValue(message, EncodingError.Context(
                codingPath: encoder.codingPath,
                debugDescription: "Message role is assistant but type doesn't match"
            ))
        }
        return try encodeAssistantMessage(assistantMsg, encoder: jsonEncoder)

    case .tool:
        guard let toolMsg = message as? ToolMessage else {
            throw EncodingError.invalidValue(message, EncodingError.Context(
                codingPath: encoder.codingPath,
                debugDescription: "Message role is tool but type doesn't match"
            ))
        }
        return try encodeToolMessage(toolMsg, encoder: jsonEncoder)

    case .activity:
        guard let activityMsg = message as? ActivityMessage else {
            throw EncodingError.invalidValue(message, EncodingError.Context(
                codingPath: encoder.codingPath,
                debugDescription: "Message role is activity but type doesn't match"
            ))
        }
        return try encodeActivityMessage(activityMsg, encoder: jsonEncoder)
    }
}

/// Encodes a DeveloperMessage to JSON
private func encodeDeveloperMessage(_ message: DeveloperMessage, encoder: JSONEncoder) throws -> Data {
    var dict: [String: Any] = [
        "id": message.id,
        "role": message.role.rawValue,
        "content": message.content ?? ""
    ]
    if let name = message.name {
        dict["name"] = name
    }
    return try JSONSerialization.data(withJSONObject: dict)
}

/// Encodes a SystemMessage to JSON
private func encodeSystemMessage(_ message: SystemMessage, encoder: JSONEncoder) throws -> Data {
    var dict: [String: Any] = [
        "id": message.id,
        "role": message.role.rawValue
    ]
    if let content = message.content {
        dict["content"] = content
    }
    if let name = message.name {
        dict["name"] = name
    }
    return try JSONSerialization.data(withJSONObject: dict)
}

/// Encodes a UserMessage to JSON
private func encodeUserMessage(_ message: UserMessage, encoder: JSONEncoder) throws -> Data {
    var dict: [String: Any] = [
        "id": message.id,
        "role": message.role.rawValue
    ]

    // Handle polymorphic content
    if let parts = message.contentParts {
        // Multimodal - encode as array
        var contentArray: [[String: Any]] = []
        for part in parts {
            if let textPart = part as? TextInputContent {
                contentArray.append([
                    "type": "text",
                    "text": textPart.text
                ])
            } else if let binaryPart = part as? BinaryInputContent {
                var binaryDict: [String: Any] = [
                    "type": "binary",
                    "mimeType": binaryPart.mimeType
                ]
                if let id = binaryPart.id {
                    binaryDict["id"] = id
                }
                if let url = binaryPart.url {
                    binaryDict["url"] = url
                }
                if let data = binaryPart.data {
                    binaryDict["data"] = data
                }
                if let filename = binaryPart.filename {
                    binaryDict["filename"] = filename
                }
                contentArray.append(binaryDict)
            }
        }
        dict["content"] = contentArray
    } else {
        // Text-only
        dict["content"] = message.content ?? ""
    }

    if let name = message.name {
        dict["name"] = name
    }
    return try JSONSerialization.data(withJSONObject: dict)
}

/// Encodes an AssistantMessage to JSON
private func encodeAssistantMessage(_ message: AssistantMessage, encoder: JSONEncoder) throws -> Data {
    var dict: [String: Any] = [
        "id": message.id,
        "role": message.role.rawValue
    ]
    if let content = message.content {
        dict["content"] = content
    }
    if let name = message.name {
        dict["name"] = name
    }
    if let toolCalls = message.toolCalls {
        let toolCallsData = try encoder.encode(toolCalls)
        let toolCallsArray = try JSONSerialization.jsonObject(with: toolCallsData)
        dict["toolCalls"] = toolCallsArray
    }
    return try JSONSerialization.data(withJSONObject: dict)
}

/// Encodes a ToolMessage to JSON
private func encodeToolMessage(_ message: ToolMessage, encoder: JSONEncoder) throws -> Data {
    var dict: [String: Any] = [
        "id": message.id,
        "role": message.role.rawValue,
        "toolCallId": message.toolCallId
    ]
    if let content = message.content {
        dict["content"] = content
    }
    if let name = message.name {
        dict["name"] = name
    }
    if let error = message.error {
        dict["error"] = error
    }
    return try JSONSerialization.data(withJSONObject: dict)
}

/// Encodes an ActivityMessage to JSON
private func encodeActivityMessage(_ message: ActivityMessage, encoder: JSONEncoder) throws -> Data {
    let activityContentObj = try JSONSerialization.jsonObject(with: message.activityContent)
    let dict: [String: Any] = [
        "id": message.id,
        "role": message.role.rawValue,
        "activityType": message.activityType,
        "activityContent": activityContentObj
    ]
    return try JSONSerialization.data(withJSONObject: dict)
}

// MARK: - JSON Encoding Helpers

/// Dynamic coding keys for encoding/decoding arbitrary JSON objects.
private struct JSONCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

extension KeyedDecodingContainer where K == JSONCodingKeys {
    /// Decodes an arbitrary JSON object (dictionary or array).
    fileprivate func decodeJSONObject() throws -> Any {
        var result: [String: Any] = [:]

        for key in allKeys {
            if let value = try? decode(String.self, forKey: key) {
                result[key.stringValue] = value
            } else if let value = try? decode(Int.self, forKey: key) {
                result[key.stringValue] = value
            } else if let value = try? decode(Double.self, forKey: key) {
                result[key.stringValue] = value
            } else if let value = try? decode(Bool.self, forKey: key) {
                result[key.stringValue] = value
            } else if let nestedContainer = try? nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key) {
                result[key.stringValue] = try nestedContainer.decodeJSONObject()
            } else if var nestedContainer = try? nestedUnkeyedContainer(forKey: key) {
                result[key.stringValue] = try nestedContainer.decodeJSONArray()
            } else {
                result[key.stringValue] = NSNull()
            }
        }

        return result
    }
}

extension UnkeyedDecodingContainer {
    /// Decodes an arbitrary JSON array.
    fileprivate mutating func decodeJSONArray() throws -> [Any] {
        var result: [Any] = []

        while !isAtEnd {
            if let value = try? decode(String.self) {
                result.append(value)
            } else if let value = try? decode(Int.self) {
                result.append(value)
            } else if let value = try? decode(Double.self) {
                result.append(value)
            } else if let value = try? decode(Bool.self) {
                result.append(value)
            } else if let nestedContainer = try? nestedContainer(keyedBy: JSONCodingKeys.self) {
                result.append(try nestedContainer.decodeJSONObject())
            } else if var nestedContainer = try? nestedUnkeyedContainer() {
                result.append(try nestedContainer.decodeJSONArray())
            } else {
                result.append(NSNull())
            }
        }

        return result
    }
}

extension KeyedEncodingContainer where K == JSONCodingKeys {
    /// Encodes an arbitrary JSON object.
    fileprivate mutating func encodeJSONObject(_ object: Any) throws {
        if let dict = object as? [String: Any] {
            for (key, value) in dict {
                let codingKey = JSONCodingKeys(stringValue: key)

                if let stringValue = value as? String {
                    try encode(stringValue, forKey: codingKey)
                } else if let intValue = value as? Int {
                    try encode(intValue, forKey: codingKey)
                } else if let doubleValue = value as? Double {
                    try encode(doubleValue, forKey: codingKey)
                } else if let boolValue = value as? Bool {
                    try encode(boolValue, forKey: codingKey)
                } else if value is NSNull {
                    try encodeNil(forKey: codingKey)
                } else if let nestedDict = value as? [String: Any] {
                    var nestedContainer = nestedContainer(keyedBy: JSONCodingKeys.self, forKey: codingKey)
                    try nestedContainer.encodeJSONObject(nestedDict)
                } else if let nestedArray = value as? [Any] {
                    var nestedContainer = nestedUnkeyedContainer(forKey: codingKey)
                    try nestedContainer.encodeJSONArray(nestedArray)
                }
            }
        }
    }
}

extension UnkeyedEncodingContainer {
    /// Encodes an arbitrary JSON array.
    fileprivate mutating func encodeJSONArray(_ array: [Any]) throws {
        for value in array {
            if let stringValue = value as? String {
                try encode(stringValue)
            } else if let intValue = value as? Int {
                try encode(intValue)
            } else if let doubleValue = value as? Double {
                try encode(doubleValue)
            } else if let boolValue = value as? Bool {
                try encode(boolValue)
            } else if value is NSNull {
                try encodeNil()
            } else if let nestedDict = value as? [String: Any] {
                var nestedContainer = nestedContainer(keyedBy: JSONCodingKeys.self)
                try nestedContainer.encodeJSONObject(nestedDict)
            } else if let nestedArray = value as? [Any] {
                var nestedContainer = nestedUnkeyedContainer()
                try nestedContainer.encodeJSONArray(nestedArray)
            }
        }
    }
}
