import Foundation

struct StateSnapshotEventDTO {
    let snapshot: Data
    let timestamp: Int64?

    static func decode(from data: Data, decoder: JSONDecoder) throws -> StateSnapshotEventDTO {
        // Parse the entire JSON to extract the snapshot field
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        
        guard let snapshotValue = jsonObject["snapshot"] else {
            throw DecodingError.keyNotFound(
                CodingKeys.snapshot,
                DecodingError.Context(codingPath: [], debugDescription: "Missing snapshot field")
            )
        }
        
        // Extract timestamp using standard decoding
        let timestamp: Int64?
        if let timestampValue = jsonObject["timestamp"] {
            if timestampValue is NSNull {
                timestamp = nil
            } else if let timestampValue = timestampValue as? Int64 {
                timestamp = timestampValue
            } else if let timestampValue = timestampValue as? Int {
                timestamp = Int64(timestampValue)
            } else {
                // Wrong type for timestamp - this will be caught by the test
                throw DecodingError.typeMismatch(
                    Int64.self,
                    DecodingError.Context(codingPath: [CodingKeys.timestamp], debugDescription: "Expected Int64 for timestamp, got \(type(of: timestampValue))")
                )
            }
        } else {
            timestamp = nil
        }
        
        // Convert snapshot value to JSON data
        // Use JSONEncoder for primitives, JSONSerialization for collections
        let snapshotData: Data
        if snapshotValue is NSNull {
            // NSNull needs special handling - encode as null JSON
            snapshotData = "null".data(using: .utf8)!
        } else if snapshotValue is [Any] || snapshotValue is [String: Any] {
            // Collections can use JSONSerialization
            snapshotData = try JSONSerialization.data(withJSONObject: snapshotValue, options: [])
        } else {
            // Primitives need JSONEncoder
            let encoder = JSONEncoder()
            snapshotData = try encoder.encode(JSONPrimitiveWrapper(value: snapshotValue))
        }
        
        return StateSnapshotEventDTO(snapshot: snapshotData, timestamp: timestamp)
    }

    enum CodingKeys: String, CodingKey {
        case snapshot
        case timestamp
    }

    func toDomain(rawEvent: Data? = nil) -> StateSnapshotEvent {
        StateSnapshotEvent(
            snapshot: snapshot,
            timestamp: timestamp,
            rawEvent: rawEvent
        )
    }
}

// Helper type to encode primitive JSON values
private struct JSONPrimitiveWrapper: Encodable {
    let value: Any

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let int64 as Int64:
            try container.encode(int64)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case is NSNull:
            try container.encodeNil()
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Unsupported primitive type"))
        }
    }
}
