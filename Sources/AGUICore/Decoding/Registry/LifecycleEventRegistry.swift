// LifecycleEventRegistry.swift
// AGUISwift

import Foundation

enum LifecycleEventRegistry {
    typealias DecodeHandler = AGUIEventDecoder.DecodeHandler

    static func registry() -> [EventType: DecodeHandler] {
        [
            .runStarted: { data, decoder in
                try decoder.decode(RunStartedEventDTO.self, from: data).toDomain(rawEvent: data)
            },
            .runFinished: { data, decoder in
                try decoder.decode(RunFinishedEventDTO.self, from: data).toDomain(rawEvent: data)
            },
            .runError: { data, decoder in
                try decoder.decode(RunErrorEventDTO.self, from: data).toDomain(rawEvent: data)
            },
            .stepStarted: { data, decoder in
                try decoder.decode(StepStartedEventDTO.self, from: data).toDomain(rawEvent: data)
            },
            .stepFinished: { data, decoder in
                try decoder.decode(StepFinishedEventDTO.self, from: data).toDomain(rawEvent: data)
            }
        ]
    }
}
