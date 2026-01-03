//
//  Extension+AGUIEventDecode.swift
//  AGUISwift
//
//  Created by Perfect Aduh on 2026-01-02.
//

@testable import AGUICore

extension AGUIEventDecoder {
    static var defaultRegistryForTests: [EventType: DecodeHandler] {
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
            .textMessageStart: { data, decoder in
                try decoder.decode(TextMessageStartEventDTO.self, from: data).toDomain(rawEvent: data)
            },
            .textMessageContent: { data, decoder in
                try decoder.decode(TextMessageContentEventDTO.self, from: data).toDomain(rawEvent: data)
            },
            .textMessageEnd: { data, decoder in
                try decoder.decode(TextMessageEndEventDTO.self, from: data).toDomain(rawEvent: data)
            }
        ]
    }
}
