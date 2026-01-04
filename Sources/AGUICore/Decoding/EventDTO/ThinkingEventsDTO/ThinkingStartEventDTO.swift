import Foundation

struct ThinkingStartEventDTO: Decodable {
    let timestamp: Int64?

    func toDomain(rawEvent: Data? = nil) -> ThinkingStartEvent {
        ThinkingStartEvent(timestamp: timestamp, rawEvent: rawEvent)
    }
}
