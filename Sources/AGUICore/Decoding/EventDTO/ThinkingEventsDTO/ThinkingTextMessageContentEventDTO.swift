// ThinkingTextMessageContentEventDTO.swift
// AGUISwift

import Foundation

struct ThinkingTextMessageContentEventDTO: Decodable {
    let delta: String
    let timestamp: Int64?

    func toDomain(rawEvent: Data? = nil) -> ThinkingTextMessageContentEvent {
        ThinkingTextMessageContentEvent(
            delta: delta,
            timestamp: timestamp,
            rawEvent: rawEvent
        )
    }
}
