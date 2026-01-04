// RegistryComposer.swift
// AGUISwift

import Foundation

enum RegistryComposer {
    typealias DecodeHandler = AGUIEventDecoder.DecodeHandler

    static func compose(_ registries: [EventType: DecodeHandler]...) -> [EventType: DecodeHandler] {
        registries.reduce(into: [:]) { result, next in
            for (key, value) in next {
                // If you want "last one wins" override behavior:
                result[key] = value
            }
        }
    }
}
