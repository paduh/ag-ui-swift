// ThinkingTextMessageStartEventDTO.swift
// AGUISwift

import Foundation

struct ThinkingTextMessageStartEventDTO: Decodable {
    let timestamp: Int64?

    func toDomain(rawEvent: Data? = nil) -> ThinkingTextMessageStartEvent {
        ThinkingTextMessageStartEvent(timestamp: timestamp, rawEvent: rawEvent)
    }
}
