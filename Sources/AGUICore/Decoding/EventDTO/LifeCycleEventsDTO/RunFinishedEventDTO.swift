import Foundation

struct RunFinishedEventDTO: Decodable {
    let threadId: String
    let runId: String
    let timestamp: Int64?

    func toDomain(rawEvent: Data? = nil) -> RunFinishedEvent {
        RunFinishedEvent(threadId: threadId, runId: runId, timestamp: timestamp, rawEvent: rawEvent)
    }
}
