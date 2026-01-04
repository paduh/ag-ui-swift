// RunErrorEventDTO.swift
// AGUISwift

import Foundation

struct RunErrorEventDTO: Decodable {
    let threadId: String
    let runId: String
    let error: RunErrorEvent.ErrorInfo
    let timestamp: Int64?

    func toDomain(rawEvent: Data? = nil) -> RunErrorEvent {
        RunErrorEvent(threadId: threadId, runId: runId, error: error, timestamp: timestamp, rawEvent: rawEvent)
    }
}
