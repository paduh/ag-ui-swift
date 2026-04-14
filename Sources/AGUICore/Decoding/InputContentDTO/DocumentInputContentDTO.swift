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

/// Data Transfer Object for DocumentInputContent decoding.
struct DocumentInputContentDTO {
    let url: String?
    let data: String?
    let mimeType: String?
    let title: String?

    static func decode(from data: Data, decoder: JSONDecoder = JSONDecoder()) throws -> DocumentInputContentDTO {
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [], debugDescription: "Expected JSON object at root")
            )
        }

        if let type = jsonObject["type"] as? String, type != "document" {
            throw DecodingError.typeMismatch(
                DocumentInputContent.self,
                DecodingError.Context(
                    codingPath: [CodingKeys.type],
                    debugDescription: "Expected type 'document' but got '\(type)'"
                )
            )
        }

        let url = jsonObject["url"] as? String
        let dataStr = jsonObject["data"] as? String

        guard url != nil || dataStr != nil else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "DocumentInputContent requires at least one of: url or data"
                )
            )
        }

        return DocumentInputContentDTO(
            url: url,
            data: dataStr,
            mimeType: jsonObject["mimeType"] as? String,
            title: jsonObject["title"] as? String
        )
    }

    func toDomain() -> DocumentInputContent {
        if let url = url {
            return DocumentInputContent(url: url, mimeType: mimeType, title: title)
        } else {
            return DocumentInputContent(data: data!, mimeType: mimeType, title: title)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type, url, data, mimeType, title
    }
}
