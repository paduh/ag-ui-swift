// AssistantMessageDTO.swift
// AGUISwift

import Foundation

/// Data Transfer Object for AssistantMessage decoding.
struct AssistantMessageDTO {
    let id: String
    let content: String?
    let name: String?
    let toolCalls: [ToolCall]?

    static func decode(from data: Data, decoder: JSONDecoder = JSONDecoder()) throws -> AssistantMessageDTO {
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [], debugDescription: "Expected JSON object at root")
            )
        }

        // Validate role
        let role = try MessageDecodingHelpers.extractRole(from: jsonObject)
        try MessageDecodingHelpers.validateRole(role, expected: .assistant)

        // Extract required fields
        let id = try MessageDecodingHelpers.extractRequiredString(from: jsonObject, key: "id")

        // Extract optional fields
        let content = MessageDecodingHelpers.extractOptionalString(from: jsonObject, key: "content")
        let name = MessageDecodingHelpers.extractOptionalString(from: jsonObject, key: "name")

        // Extract optional toolCalls array
        let toolCalls: [ToolCall]?
        if let toolCallsArray = jsonObject["toolCalls"] as? [[String: Any]], !toolCallsArray.isEmpty {
            let toolCallsData = try JSONSerialization.data(withJSONObject: toolCallsArray)
            toolCalls = try decoder.decode([ToolCall].self, from: toolCallsData)
        } else {
            toolCalls = nil
        }

        return AssistantMessageDTO(id: id, content: content, name: name, toolCalls: toolCalls)
    }

    func toDomain() -> AssistantMessage {
        AssistantMessage(id: id, content: content, name: name, toolCalls: toolCalls)
    }
}
