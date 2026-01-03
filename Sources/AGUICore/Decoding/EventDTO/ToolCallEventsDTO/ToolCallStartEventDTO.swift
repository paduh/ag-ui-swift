import Foundation

struct ToolCallStartEventDTO: Decodable {
    let toolCallId: String
    let toolCallName: String
    let parentMessageId: String?
    let timestamp: Int64?

    func toDomain(rawEvent: Data? = nil) -> ToolCallStartEvent {
        ToolCallStartEvent(
            toolCallId: toolCallId,
            toolCallName: toolCallName,
            parentMessageId: parentMessageId,
            timestamp: timestamp,
            rawEvent: rawEvent
        )
    }
}

