// ToolCallEventRegistry.swift
// AGUISwift

import Foundation

enum ToolCallEventRegistry {
    typealias DecodeHandler = AGUIEventDecoder.DecodeHandler

    static func registry() -> [EventType: DecodeHandler] {
        [
            .toolCallStart: { data, decoder in
                try decoder.decode(ToolCallStartEventDTO.self, from: data).toDomain(rawEvent: data)
            },
            .toolCallArgs: { data, decoder in
                try decoder.decode(ToolCallArgsEventDTO.self, from: data).toDomain(rawEvent: data)
            },
            .toolCallEnd: { data, decoder in
                try decoder.decode(ToolCallEndEventDTO.self, from: data).toDomain(rawEvent: data)
            },
            .toolCallResult: { data, decoder in
                try decoder.decode(ToolCallResultEventDTO.self, from: data).toDomain(rawEvent: data)
            }
            // Add more: toolCallChunk...
        ]
    }
}
