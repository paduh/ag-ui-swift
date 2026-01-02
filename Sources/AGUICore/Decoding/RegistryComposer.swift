//
//  RegistryComposer.swift
//  AGUISwift
//
//  Created by Perfect Aduh on 2026-01-02.
//

import Foundation

enum RegistryComposer {
    typealias DecodeHandler = AGUIEventDecoder.DecodeHandler

    static func compose(_ registries: [EventType: DecodeHandler]...) -> [EventType: DecodeHandler] {
        registries.reduce(into: [:]) { result, next in
            for (k, v) in next {
                // If you want "last one wins" override behavior:
                result[k] = v
            }
        }
    }
}
