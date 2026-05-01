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

/// Represents an image in multimodal user input.
///
/// `ImageInputContent` carries image data either as a URL reference or as
/// base64-encoded bytes. The optional `detail` field controls how agents
/// with vision capabilities process the image (e.g., `"high"`, `"low"`, `"auto"`).
///
/// - SeeAlso: ``InputContent``, ``UserMessage``
public struct ImageInputContent: InputContent, Hashable, Sendable {

    /// The content type discriminator (always `"image"`).
    public let type: String

    /// Optional URL pointing to the image.
    public let url: String?

    /// Optional base64-encoded image data.
    public let data: String?

    /// Optional detail level hint for vision-capable agents.
    ///
    /// Common values: `"high"`, `"low"`, `"auto"`.
    public let detail: String?

    /// Optional MIME type of the image (e.g., `"image/png"`, `"image/jpeg"`).
    public let mimeType: String?

    /// Creates an image content from a URL.
    ///
    /// - Parameters:
    ///   - url: URL pointing to the image
    ///   - detail: Optional detail level (`"high"`, `"low"`, `"auto"`)
    ///   - mimeType: Optional MIME type (e.g., `"image/png"`)
    public init(url: String, detail: String? = nil, mimeType: String? = nil) {
        self.type = "image"
        self.url = url
        self.data = nil
        self.detail = detail
        self.mimeType = mimeType
    }

    /// Creates an image content from base64-encoded data.
    ///
    /// - Parameters:
    ///   - data: Base64-encoded image bytes
    ///   - detail: Optional detail level (`"high"`, `"low"`, `"auto"`)
    ///   - mimeType: Optional MIME type (e.g., `"image/jpeg"`)
    public init(data: String, detail: String? = nil, mimeType: String? = nil) {
        self.type = "image"
        self.url = nil
        self.data = data
        self.detail = detail
        self.mimeType = mimeType
    }
}
