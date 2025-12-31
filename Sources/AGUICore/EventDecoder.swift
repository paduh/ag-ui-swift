import Foundation

/// Helper for polymorphic decoding of AG-UI events.
///
/// This decoder reads the "type" field from JSON and routes to the appropriate
/// event type decoder. This enables type-safe decoding of heterogeneous event arrays.
///
/// Note: Specific event type implementations should register themselves with this
/// decoder to enable proper polymorphic deserialization.
public enum EventDecoder {
    /// Decodes a single event from JSON data.
    ///
    /// - Parameter data: The JSON data to decode
    /// - Returns: An `AGUIEvent` instance decoded from the data
    /// - Throws: `DecodingError` if the data cannot be decoded
    public static func decodeEvent(from data: Data) throws -> AGUIEvent {
        // First, parse the JSON to extract the type field
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let typeString = json?["type"] as? String,
              let eventType = EventType(rawValue: typeString) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Missing or invalid 'type' field in event JSON"
                )
            )
        }
        
        // For now, return a generic event wrapper
        // Specific event types will be implemented separately and registered here
        return GenericEvent(
            eventType: eventType,
            timestamp: (json?["timestamp"] as? NSNumber)?.int64Value
        )
    }
    
    /// Decodes an array of events from JSON data.
    ///
    /// - Parameter data: The JSON data containing an array of events
    /// - Returns: An array of `AGUIEvent` instances
    /// - Throws: `DecodingError` if the data cannot be decoded
    public static func decodeEvents(from data: Data) throws -> [AGUIEvent] {
        let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        
        return try jsonArray?.compactMap { json -> AGUIEvent? in
            let jsonData = try JSONSerialization.data(withJSONObject: json)
            return try? decodeEvent(from: jsonData)
        } ?? []
    }
}

/// Generic event implementation for polymorphic decoding.
///
/// This is a concrete implementation of `AGUIEvent` that can represent any
/// event type. Specific event types should be implemented as separate structs
/// conforming to `AGUIEvent` for better type safety and functionality.
internal struct GenericEvent: AGUIEvent {
    let eventType: EventType
    let timestamp: Int64?
    
    enum CodingKeys: String, CodingKey {
        case type
        case timestamp
    }
    
    init(eventType: EventType, timestamp: Int64?) {
        self.eventType = eventType
        self.timestamp = timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeString = try container.decode(String.self, forKey: .type)
        
        guard let eventType = EventType(rawValue: typeString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Invalid event type: \(typeString)"
            )
        }
        
        self.eventType = eventType
        self.timestamp = try container.decodeIfPresent(Int64.self, forKey: .timestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(eventType.rawValue, forKey: .type)
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
    }
}
