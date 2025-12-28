import Foundation

/// Protocol extension providing default Codable implementation for BaseEvent.
///
/// This extension handles the common "type" field encoding/decoding pattern,
/// allowing concrete event types to focus on their specific properties.
extension BaseEvent {
    /// Default implementation for encoding the "type" field.
    ///
    /// Concrete types should call this from their `encode(to:)` implementation
    /// after encoding their specific properties.
    internal func encodeType(to container: inout KeyedEncodingContainer<EventCodingKeys>) throws {
        try container.encode(eventType.rawValue, forKey: .type)
    }
    
    /// Generic version that works with any CodingKeys enum that has a "type" case.
    ///
    /// This allows event types to use their own CodingKeys enum while still
    /// benefiting from the type encoding helper.
    internal func encodeType<Keys: CodingKey>(
        to container: inout KeyedEncodingContainer<Keys>,
        typeKey: Keys
    ) throws {
        try container.encode(eventType.rawValue, forKey: typeKey)
    }
    
    /// Default implementation for verifying the "type" field during decoding.
    ///
    /// Concrete types should call this from their `init(from:)` implementation
    /// to verify the type matches before decoding their specific properties.
    internal static func verifyType(
        in container: KeyedDecodingContainer<EventCodingKeys>,
        expected: EventType
    ) throws {
        let typeString = try container.decode(String.self, forKey: .type)
        guard typeString == expected.rawValue else {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Expected type '\(expected.rawValue)', but found '\(typeString)'"
            )
        }
    }
    
    /// Generic version that works with any CodingKeys enum that has a "type" case.
    ///
    /// This allows event types to use their own CodingKeys enum while still
    /// benefiting from the type verification helper.
    internal static func verifyType<Keys: CodingKey>(
        in container: KeyedDecodingContainer<Keys>,
        expected: EventType,
        typeKey: Keys
    ) throws {
        let typeString = try container.decode(String.self, forKey: typeKey)
        guard typeString == expected.rawValue else {
            throw DecodingError.dataCorruptedError(
                forKey: typeKey,
                in: container,
                debugDescription: "Expected type '\(expected.rawValue)', but found '\(typeString)'"
            )
        }
    }
}

/// Common coding keys for event serialization.
internal enum EventCodingKeys: String, CodingKey {
    case type
    case timestamp
}

