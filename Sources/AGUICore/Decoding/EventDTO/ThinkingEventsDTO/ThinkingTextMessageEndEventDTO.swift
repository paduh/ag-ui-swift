// ThinkingTextMessageEndEventDTO.swift
// AGUISwift

import Foundation

struct ThinkingTextMessageEndEventDTO: Decodable {
    let timestamp: Int64?

    func toDomain(rawEvent: Data? = nil) -> ThinkingTextMessageEndEvent {
        ThinkingTextMessageEndEvent(timestamp: timestamp, rawEvent: rawEvent)
    }
}
