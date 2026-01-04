// TextMessageStartEventDTO.swift
// AGUISwift

import Foundation

struct TextMessageStartEventDTO: Decodable {
    let messageId: String
    let role: String
    let timestamp: Int64?

    func toDomain(rawEvent: Data? = nil) -> TextMessageStartEvent {
        TextMessageStartEvent(
            messageId: messageId,
            role: role,
            timestamp: timestamp,
            rawEvent: rawEvent
        )
    }
}
