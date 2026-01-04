// RunStartedEventDTO.swift
// AGUISwift

import Foundation

struct RunStartedEventDTO: Decodable {
    let threadId: String
    let runId: String
    let timestamp: Int64?

    func toDomain(rawEvent: Data? = nil) -> RunStartedEvent {
        RunStartedEvent(threadId: threadId, runId: runId, timestamp: timestamp, rawEvent: rawEvent)
    }
}
