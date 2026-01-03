//
//  StateEventRegistry.swift
//  AGUISwift
//
//  Created by Perfect Aduh on 2026-01-02.
//

import Foundation

enum StateEventRegistry {
    typealias DecodeHandler = AGUIEventDecoder.DecodeHandler

    static func registry() -> [EventType: DecodeHandler] {
        [
            .stateSnapshot: { data, decoder in
                try StateSnapshotEventDTO.decode(from: data, decoder: decoder).toDomain(rawEvent: data)
            }
            // Add more: stateDelta, messagesSnapshot...
        ]
    }
}

