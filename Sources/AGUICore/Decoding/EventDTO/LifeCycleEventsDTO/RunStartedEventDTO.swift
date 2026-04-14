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

struct RunStartedEventDTO {
    let threadId: String
    let runId: String
    let parentRunId: String?
    // `input` stored as raw JSON — the full RunAgentInput schema includes messages
    // which are not auto-Decodable, so we preserve the wire bytes and let callers parse.
    let input: Data?
    let timestamp: Int64?

    static func decode(from data: Data, decoder: JSONDecoder = JSONDecoder()) throws -> RunStartedEventDTO {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [], debugDescription: "Expected JSON object at root")
            )
        }

        let threadId: String
        if let raw = jsonObject["threadId"] {
            guard let value = raw as? String else {
                throw DecodingError.typeMismatch(
                    String.self,
                    DecodingError.Context(codingPath: [CodingKeys.threadId], debugDescription: "Type mismatch for 'threadId': expected String")
                )
            }
            threadId = value
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.threadId,
                DecodingError.Context(codingPath: [], debugDescription: "Missing required field: threadId")
            )
        }

        let runId: String
        if let raw = jsonObject["runId"] {
            guard let value = raw as? String else {
                throw DecodingError.typeMismatch(
                    String.self,
                    DecodingError.Context(codingPath: [CodingKeys.runId], debugDescription: "Type mismatch for 'runId': expected String")
                )
            }
            runId = value
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.runId,
                DecodingError.Context(codingPath: [], debugDescription: "Missing required field: runId")
            )
        }

        let parentRunId = jsonObject["parentRunId"] as? String
        let timestamp = try EventDecodingHelpers.extractTimestamp(from: jsonObject)

        var inputData: Data?
        if let inputValue = jsonObject["input"], !(inputValue is NSNull) {
            inputData = try? JSONSerialization.data(withJSONObject: inputValue)
        }

        return RunStartedEventDTO(
            threadId: threadId,
            runId: runId,
            parentRunId: parentRunId,
            input: inputData,
            timestamp: timestamp
        )
    }

    func toDomain(rawEvent: Data? = nil) -> RunStartedEvent {
        RunStartedEvent(
            threadId: threadId,
            runId: runId,
            parentRunId: parentRunId,
            input: input,
            timestamp: timestamp,
            rawEvent: rawEvent
        )
    }

    private enum CodingKeys: String, CodingKey {
        case threadId, runId, parentRunId, timestamp, input
    }
}
