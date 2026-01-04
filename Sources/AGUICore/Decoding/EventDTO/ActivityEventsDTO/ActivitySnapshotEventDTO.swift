// ActivitySnapshotEventDTO.swift
// AGUISwift

import Foundation

struct ActivitySnapshotEventDTO {
    let messageId: String
    let activityType: String
    let content: Data
    let replace: Bool
    let timestamp: Int64?

    static func decode(from data: Data, decoder: JSONDecoder) throws -> ActivitySnapshotEventDTO {
        // Parse the entire JSON to extract fields
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [], debugDescription: "Expected JSON object at root")
            )
        }

        guard let messageId = jsonObject["messageId"] as? String else {
            throw DecodingError.keyNotFound(
                CodingKeys.messageId,
                DecodingError.Context(codingPath: [], debugDescription: "Missing messageId field")
            )
        }

        guard let activityType = jsonObject["activityType"] as? String else {
            throw DecodingError.keyNotFound(
                CodingKeys.activityType,
                DecodingError.Context(codingPath: [], debugDescription: "Missing activityType field")
            )
        }

        guard let contentValue = jsonObject["content"] else {
            throw DecodingError.keyNotFound(
                CodingKeys.content,
                DecodingError.Context(codingPath: [], debugDescription: "Missing content field")
            )
        }

        // Extract replace field (defaults to true if not present)
        let replace = (jsonObject["replace"] as? Bool) ?? true

        // Extract timestamp using shared helper
        let timestamp = try EventDecodingHelpers.extractTimestamp(from: jsonObject)

        // Convert content value to JSON data
        let contentData: Data
        if contentValue is NSNull {
            contentData = Data("null".utf8)
        } else if contentValue is [Any] || contentValue is [String: Any] {
            contentData = try JSONSerialization.data(withJSONObject: contentValue, options: [])
        } else {
            let encoder = JSONEncoder()
            contentData = try encoder.encode(JSONPrimitiveWrapper(value: contentValue))
        }

        return ActivitySnapshotEventDTO(
            messageId: messageId,
            activityType: activityType,
            content: contentData,
            replace: replace,
            timestamp: timestamp
        )
    }

    enum CodingKeys: String, CodingKey {
        case messageId
        case activityType
        case content
        case replace
        case timestamp
    }

    func toDomain(rawEvent: Data? = nil) -> ActivitySnapshotEvent {
        ActivitySnapshotEvent(
            messageId: messageId,
            activityType: activityType,
            content: content,
            replace: replace,
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
