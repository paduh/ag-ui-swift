import Foundation

enum ThinkingEventRegistry {
    typealias DecodeHandler = AGUIEventDecoder.DecodeHandler

    static func registry() -> [EventType: DecodeHandler] {
        [
            .thinkingStart: { data, decoder in
                try decoder.decode(ThinkingStartEventDTO.self, from: data).toDomain(rawEvent: data)
            },
            .thinkingEnd: { data, decoder in
                try decoder.decode(ThinkingEndEventDTO.self, from: data).toDomain(rawEvent: data)
            },
            .thinkingTextMessageStart: { data, decoder in
                try decoder.decode(ThinkingTextMessageStartEventDTO.self, from: data).toDomain(rawEvent: data)
            }
        ]
    }
}
