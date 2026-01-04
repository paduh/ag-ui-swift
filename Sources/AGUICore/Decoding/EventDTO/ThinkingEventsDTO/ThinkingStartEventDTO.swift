import Foundation

struct ThinkingStartEventDTO: Decodable {
    let title: String?
    let timestamp: Int64?

    func toDomain(rawEvent: Data? = nil) -> ThinkingStartEvent {
        ThinkingStartEvent(title: title, timestamp: timestamp, rawEvent: rawEvent)
    }
}
