// SystemMessageDTO.swift
// AGUISwift

import Foundation

/// Data Transfer Object for SystemMessage decoding.
struct SystemMessageDTO {
    let id: String
    let content: String?
    let name: String?

    static func decode(from data: Data, decoder: JSONDecoder = JSONDecoder()) throws -> SystemMessageDTO {
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [], debugDescription: "Expected JSON object at root")
            )
        }

        // Validate role
        let role = try MessageDecodingHelpers.extractRole(from: jsonObject)
        try MessageDecodingHelpers.validateRole(role, expected: .system)

        // Extract required fields
        let id = try MessageDecodingHelpers.extractRequiredString(from: jsonObject, key: "id")

        // Extract optional fields
        let content = MessageDecodingHelpers.extractOptionalString(from: jsonObject, key: "content")
        let name = MessageDecodingHelpers.extractOptionalString(from: jsonObject, key: "name")

        return SystemMessageDTO(id: id, content: content, name: name)
    }

    func toDomain() -> SystemMessage {
        SystemMessage(id: id, content: content, name: name)
    }
}
