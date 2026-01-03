//
//  ToolCallEventRegistry.swift
//  AGUISwift
//
//  Created by Perfect Aduh on 2026-01-02.
//

import Foundation

enum ToolCallEventRegistry {
    typealias DecodeHandler = AGUIEventDecoder.DecodeHandler

    static func registry() -> [EventType: DecodeHandler] {
        [
            .toolCallStart: { data, decoder in
                try decoder.decode(ToolCallStartEventDTO.self, from: data).toDomain(rawEvent: data)
            }
            // Add more: toolCallArgs, toolCallEnd, toolCallResult, toolCallChunk...
        ]
    }
}

