import Foundation

struct TextMessageContentEventDTO: Decodable {
    let messageId: String
    let delta: String
    let timestamp: Int64?

    func toDomain(rawEvent: Data? = nil) -> TextMessageContentEvent {
        TextMessageContentEvent(
            messageId: messageId,
            delta: delta,
            timestamp: timestamp,
            rawEvent: rawEvent
        )
    }
}
