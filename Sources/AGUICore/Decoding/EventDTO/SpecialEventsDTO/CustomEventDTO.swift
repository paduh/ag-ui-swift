// CustomEventDTO.swift
// AGUISwift

import Foundation

struct CustomEventDTO {
    let customType: String
    let data: Data
    let timestamp: Int64?

    static func decode(from data: Data, decoder: JSONDecoder) throws -> CustomEventDTO {
        // Parse the entire JSON to extract the customType and data fields
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [], debugDescription: "Expected JSON object at root")
            )
        }

        guard let customType = jsonObject["customType"] as? String else {
            if jsonObject["customType"] == nil {
                throw DecodingError.keyNotFound(
                    CodingKeys.customType,
                    DecodingError.Context(codingPath: [], debugDescription: "Missing customType field")
                )
            } else {
                throw DecodingError.typeMismatch(
                    String.self,
                    DecodingError.Context(codingPath: [CodingKeys.customType], debugDescription: "Expected String for customType")
                )
            }
        }

        guard let dataValue = jsonObject["data"] else {
            throw DecodingError.keyNotFound(
                CodingKeys.data,
                DecodingError.Context(codingPath: [], debugDescription: "Missing data field")
            )
        }

        // Extract timestamp using shared helper
        let timestamp = try EventDecodingHelpers.extractTimestamp(from: jsonObject)

        // Convert data value to JSON data
        // Use JSONEncoder for primitives, JSONSerialization for collections
        let eventData: Data
        if dataValue is NSNull {
            // NSNull needs special handling - encode as null JSON
            eventData = Data("null".utf8)
        } else if dataValue is [Any] || dataValue is [String: Any] {
            // Collections can use JSONSerialization
            eventData = try JSONSerialization.data(withJSONObject: dataValue, options: [])
        } else {
            // Primitives need JSONEncoder
            let encoder = JSONEncoder()
            eventData = try encoder.encode(JSONPrimitiveWrapper(value: dataValue))
        }

        return CustomEventDTO(customType: customType, data: eventData, timestamp: timestamp)
    }

    enum CodingKeys: String, CodingKey {
        case customType
        case data
        case timestamp
    }

    func toDomain(rawEvent: Data? = nil) -> CustomEvent {
        CustomEvent(
            customType: customType,
            data: data,
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
