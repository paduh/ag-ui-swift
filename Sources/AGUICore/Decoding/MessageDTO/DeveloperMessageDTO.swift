// DeveloperMessageDTO.swift
// AGUISwift

import Foundation

/// Data Transfer Object for DeveloperMessage decoding.
struct DeveloperMessageDTO {
    let id: String
    let content: String
    let name: String?

    static func decode(from data: Data, decoder: JSONDecoder = JSONDecoder()) throws -> DeveloperMessageDTO {
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [], debugDescription: "Expected JSON object at root")
            )
        }

        // Validate role
        let role = try MessageDecodingHelpers.extractRole(from: jsonObject)
        try MessageDecodingHelpers.validateRole(role, expected: .developer)

        // Extract required fields
        let id = try MessageDecodingHelpers.extractRequiredString(from: jsonObject, key: "id")
        let content = try MessageDecodingHelpers.extractRequiredString(from: jsonObject, key: "content")

        // Extract optional fields
        let name = MessageDecodingHelpers.extractOptionalString(from: jsonObject, key: "name")

        return DeveloperMessageDTO(id: id, content: content, name: name)
    }

    func toDomain() -> DeveloperMessage {
        DeveloperMessage(id: id, content: content, name: name)
    }
}
