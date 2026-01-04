import Foundation

enum ThinkingEventRegistry {
    typealias DecodeHandler = AGUIEventDecoder.DecodeHandler

    static func registry() -> [EventType: DecodeHandler] {
        [
            .thinkingStart: { data, decoder in
                try decoder.decode(ThinkingStartEventDTO.self, from: data).toDomain(rawEvent: data)
            }
        ]
    }
}
