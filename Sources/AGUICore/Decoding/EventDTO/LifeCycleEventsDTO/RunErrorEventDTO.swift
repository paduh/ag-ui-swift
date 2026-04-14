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

struct RunErrorEventDTO {
    let message: String
    let code: String?
    let timestamp: Int64?

    static func decode(from data: Data, decoder: JSONDecoder = JSONDecoder()) throws -> RunErrorEventDTO {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [], debugDescription: "Expected JSON object at root")
            )
        }

        guard let message = jsonObject["message"] as? String else {
            throw DecodingError.keyNotFound(
                CodingKeys.message,
                DecodingError.Context(codingPath: [], debugDescription: "Missing required field: message")
            )
        }

        let code = jsonObject["code"] as? String
        let timestamp = try EventDecodingHelpers.extractTimestamp(from: jsonObject)

        return RunErrorEventDTO(message: message, code: code, timestamp: timestamp)
    }

    func toDomain(rawEvent: Data? = nil) -> RunErrorEvent {
        RunErrorEvent(message: message, code: code, timestamp: timestamp, rawEvent: rawEvent)
    }

    private enum CodingKeys: String, CodingKey {
        case message, code, timestamp
    }
}
