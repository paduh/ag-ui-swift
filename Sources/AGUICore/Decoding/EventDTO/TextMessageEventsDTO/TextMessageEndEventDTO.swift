// TextMessageEndEventDTO.swift
// AGUISwift

import Foundation

struct TextMessageEndEventDTO: Decodable {
    let messageId: String
    let timestamp: Int64?

    func toDomain(rawEvent: Data? = nil) -> TextMessageEndEvent {
        TextMessageEndEvent(
            messageId: messageId,
            timestamp: timestamp,
            rawEvent: rawEvent
        )
    }
}
