// ToolCallArgsEventDTO.swift
// AGUISwift

import Foundation

struct ToolCallArgsEventDTO: Decodable {
    let toolCallId: String
    let delta: String
    let timestamp: Int64?

    func toDomain(rawEvent: Data? = nil) -> ToolCallArgsEvent {
        ToolCallArgsEvent(
            toolCallId: toolCallId,
            delta: delta,
            timestamp: timestamp,
            rawEvent: rawEvent
        )
    }
}
