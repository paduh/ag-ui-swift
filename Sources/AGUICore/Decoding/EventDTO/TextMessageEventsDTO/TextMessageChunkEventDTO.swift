// TextMessageChunkEventDTO.swift
// AGUISwift

import Foundation

struct TextMessageChunkEventDTO: Decodable {
    let messageId: String?
    let role: String?
    let delta: String?
    let timestamp: Int64?

    func toDomain(rawEvent: Data? = nil) -> TextMessageChunkEvent {
        TextMessageChunkEvent(
            messageId: messageId,
            role: role,
            delta: delta,
            timestamp: timestamp,
            rawEvent: rawEvent
        )
    }
}
