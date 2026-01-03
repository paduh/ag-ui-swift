//
//  TextMessageEventRegistry.swift
//  AGUISwift
//
//  Created by Perfect Aduh on 2026-01-02.
//

import Foundation

enum TextMessageEventRegistry {
    typealias DecodeHandler = AGUIEventDecoder.DecodeHandler

    static func registry() -> [EventType: DecodeHandler] {
        [
            .textMessageStart: { data, decoder in
                try decoder.decode(TextMessageStartEventDTO.self, from: data).toDomain(rawEvent: data)
            }
            // Add more: textMessageContent, textMessageEnd, textMessageChunk...
        ]
    }
}

