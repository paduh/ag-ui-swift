// ActivityMessage.swift
// AGUISwift

import Foundation

/// Represents a structured activity update in the conversation.
///
/// `ActivityMessage` enables agents to stream dynamic UI elements, progress indicators,
/// A2UI surfaces, and other structured content beyond simple text messages.
///
/// ## Activity Types
///
/// The `activityType` field identifies the kind of activity:
/// - **Progress**: Progress indicators and status updates
/// - **Visualization**: Charts, graphs, and data visualizations
/// - **A2UI Surface**: Interactive UI components (forms, buttons, etc.)
/// - **Status**: System status and state updates
/// - **Custom**: Application-specific activity types
///
/// ## Activity Content
///
/// The `activityContent` field stores flexible JSON data as a `Data` object,
/// allowing each activity type to define its own content structure.
///
/// ## Usage Examples
///
/// ```swift
/// // Progress indicator
/// let progressContent = Data("""
/// {
///     "percent": 75,
///     "message": "Processing files...",
///     "current": 15,
///     "total": 20
/// }
/// """.utf8)
///
/// let progress = ActivityMessage(
///     id: "progress-1",
///     activityType: "progress",
///     activityContent: progressContent
/// )
///
/// // Chart visualization
/// let chartContent = Data("""
/// {
///     "chartType": "bar",
///     "data": {
///         "labels": ["Q1", "Q2", "Q3", "Q4"],
///         "datasets": [
///             {"label": "Sales", "values": [100, 150, 120, 180]}
///         ]
///     }
/// }
/// """.utf8)
///
/// let chart = ActivityMessage(
///     id: "viz-1",
///     activityType: "chart",
///     activityContent: chartContent
/// )
///
/// // A2UI form surface
/// let formContent = Data("""
/// {
///     "surfaceType": "form",
///     "fields": [
///         {"name": "email", "type": "text"},
///         {"name": "submit", "type": "button"}
///     ]
/// }
/// """.utf8)
///
/// let form = ActivityMessage(
///     id: "surface-1",
///     activityType: "a2ui-form",
///     activityContent: formContent
/// )
/// ```
///
/// ## Message Protocol
///
/// ActivityMessage conforms to the Message protocol, but `content` and `name`
/// are always `nil` since activities use structured `activityContent` instead.
///
/// - SeeAlso: ``Message``, ``Role``
public struct ActivityMessage: Message, Sendable, Hashable {
    /// The unique identifier for this message.
    public let id: String

    /// The message role (always `.activity`).
    public let role: Role

    /// The type of activity being reported.
    ///
    /// Common activity types:
    /// - `"progress"`: Progress indicators and completion status
    /// - `"chart"`: Data visualizations and charts
    /// - `"a2ui-form"`: Interactive form surfaces
    /// - `"status"`: System status updates
    /// - Custom application-specific types
    public let activityType: String

    /// The structured activity content as JSON data.
    ///
    /// This field contains a JSON object with activity-specific data.
    /// The structure varies based on the `activityType`.
    public let activityContent: Data

    /// Text content (always `nil` for activity messages).
    ///
    /// ActivityMessage uses `activityContent` for structured data
    /// instead of text content.
    public let content: String? = nil

    /// Optional sender name (always `nil` for activity messages).
    public let name: String? = nil

    /// Creates a new activity message.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the message
    ///   - activityType: The type of activity
    ///   - activityContent: JSON data representing the activity content
    public init(
        id: String,
        activityType: String,
        activityContent: Data
    ) {
        self.id = id
        self.role = .activity
        self.activityType = activityType
        self.activityContent = activityContent
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case id
        case role
        case activityType
        case activityContent
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        role = try container.decode(Role.self, forKey: .role)
        activityType = try container.decode(String.self, forKey: .activityType)

        // Decode activityContent as a JSON object and store as Data
        let contentContainer = try container.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: .activityContent)
        let jsonObject = try contentContainer.decodeJSONObject()
        activityContent = try JSONSerialization.data(withJSONObject: jsonObject)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(role, forKey: .role)
        try container.encode(activityType, forKey: .activityType)

        // Encode activityContent as a JSON object
        let jsonObject = try JSONSerialization.jsonObject(with: activityContent)
        var contentContainer = container.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: .activityContent)
        try contentContainer.encodeJSONObject(jsonObject)
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(role)
        hasher.combine(activityType)
        hasher.combine(activityContent)
    }

    public static func == (lhs: ActivityMessage, rhs: ActivityMessage) -> Bool {
        lhs.id == rhs.id &&
            lhs.role == rhs.role &&
            lhs.activityType == rhs.activityType &&
            lhs.activityContent == rhs.activityContent
    }
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
