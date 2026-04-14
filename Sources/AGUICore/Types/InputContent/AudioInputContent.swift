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

/// Represents audio content in multimodal user input.
///
/// `AudioInputContent` carries audio data either as a URL reference or as
/// base64-encoded bytes. The optional `format` field identifies the audio codec
/// (e.g., `"mp3"`, `"wav"`, `"ogg"`).
///
/// - SeeAlso: ``InputContent``, ``UserMessage``
public struct AudioInputContent: InputContent, Hashable, Sendable {

    /// The content type discriminator (always `"audio"`).
    public let type: String

    /// Optional URL pointing to the audio file.
    public let url: String?

    /// Optional base64-encoded audio data.
    public let data: String?

    /// Optional audio format identifier.
    ///
    /// Common values: `"mp3"`, `"wav"`, `"ogg"`, `"flac"`.
    public let format: String?

    /// Creates audio content from a URL.
    ///
    /// - Parameters:
    ///   - url: URL pointing to the audio file
    ///   - format: Optional format identifier (e.g., `"mp3"`)
    public init(url: String, format: String? = nil) {
        self.type = "audio"
        self.url = url
        self.data = nil
        self.format = format
    }

    /// Creates audio content from base64-encoded data.
    ///
    /// - Parameters:
    ///   - data: Base64-encoded audio bytes
    ///   - format: Optional format identifier (e.g., `"wav"`)
    public init(data: String, format: String? = nil) {
        self.type = "audio"
        self.url = nil
        self.data = data
        self.format = format
    }
}
