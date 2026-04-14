/*
 * MIT License
 *
 * Copyright (c) 2025 Perfect Aduh
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import Foundation

enum ReasoningEventRegistry {
    typealias DecodeHandler = AGUIEventDecoder.DecodeHandler

    static func registry() -> [EventType: DecodeHandler] {
        [
            .reasoningStart: { data, decoder in
                try decoder.decode(ReasoningStartEventDTO.self, from: data).toDomain(rawEvent: data)
            },
            .reasoningMessageStart: { data, decoder in
                try decoder.decode(ReasoningMessageStartEventDTO.self, from: data).toDomain(rawEvent: data)
            },
            .reasoningMessageContent: { data, decoder in
                try decoder.decode(ReasoningMessageContentEventDTO.self, from: data).toDomain(rawEvent: data)
            },
            .reasoningMessageEnd: { data, decoder in
                try decoder.decode(ReasoningMessageEndEventDTO.self, from: data).toDomain(rawEvent: data)
            },
            .reasoningMessageChunk: { data, decoder in
                try decoder.decode(ReasoningMessageChunkEventDTO.self, from: data).toDomain(rawEvent: data)
            },
            .reasoningEnd: { data, decoder in
                try decoder.decode(ReasoningEndEventDTO.self, from: data).toDomain(rawEvent: data)
            },
            .reasoningEncryptedValue: { data, decoder in
                try decoder.decode(ReasoningEncryptedValueEventDTO.self, from: data).toDomain(rawEvent: data)
            }
        ]
    }
}
