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

/// Represents video content in multimodal user input.
///
/// `VideoInputContent` carries video data either as a URL reference or as
/// base64-encoded bytes.
///
/// - SeeAlso: ``InputContent``, ``UserMessage``
public struct VideoInputContent: InputContent, Hashable, Sendable {

    /// The content type discriminator (always `"video"`).
    public let type: String

    /// Optional URL pointing to the video file.
    public let url: String?

    /// Optional base64-encoded video data.
    public let data: String?

    /// Optional MIME type of the video (e.g., `"video/mp4"`, `"video/webm"`).
    public let mimeType: String?

    /// Creates video content from a URL.
    ///
    /// - Parameters:
    ///   - url: URL pointing to the video file
    ///   - mimeType: Optional MIME type (e.g., `"video/mp4"`)
    public init(url: String, mimeType: String? = nil) {
        self.type = "video"
        self.url = url
        self.data = nil
        self.mimeType = mimeType
    }

    /// Creates video content from base64-encoded data.
    ///
    /// - Parameters:
    ///   - data: Base64-encoded video bytes
    ///   - mimeType: Optional MIME type (e.g., `"video/webm"`)
    public init(data: String, mimeType: String? = nil) {
        self.type = "video"
        self.url = nil
        self.data = data
        self.mimeType = mimeType
    }
}
