import Foundation

struct ThinkingEndEventDTO: Decodable {
    let timestamp: Int64?

    func toDomain(rawEvent: Data? = nil) -> ThinkingEndEvent {
        ThinkingEndEvent(timestamp: timestamp, rawEvent: rawEvent)
    }
}
