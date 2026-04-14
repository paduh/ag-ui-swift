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

/// Protocol for HTTP client operations.
///
/// `HTTPClient` abstracts HTTP networking, enabling dependency injection
/// and testability. Implementations can use URLSession, mock responses,
/// or custom networking stacks.
///
/// ## Example Implementation
///
/// ```swift
/// actor URLSessionHTTPClient: HTTPClient {
///     private let session: URLSession
///
///     init(session: URLSession) {
///         self.session = session
///     }
///
///     func execute(_ request: URLRequest) async throws -> HTTPResponse {
///         let (bytes, urlResponse) = try await session.bytes(for: request)
///         guard let httpResponse = urlResponse as? HTTPURLResponse else {
///             throw ClientError.invalidResponse
///         }
///         return HTTPResponse(bytes: bytes, httpResponse: httpResponse)
///     }
/// }
/// ```
public protocol HTTPClient: Sendable {
    /// Executes an HTTP request and returns the response.
    ///
    /// - Parameter request: The URL request to execute
    /// - Returns: An HTTP response containing streaming bytes and metadata
    /// - Throws: `ClientError` if the request fails
    func execute(_ request: URLRequest) async throws -> HTTPResponse
}

/// HTTP response containing streaming bytes and metadata.
///
/// `bytes` is typed as `AsyncThrowingStream<UInt8, Error>` rather than
/// `URLSession.AsyncBytes` so that:
/// - Mock `HTTPClient` implementations can produce byte streams without a live URLSession
/// - The transport layer is testable in isolation
/// - Consumers of `HTTPClient` are decoupled from URLSession internals
public struct HTTPResponse: Sendable {
    /// Streaming response bytes.
    ///
    /// Conforms to `AsyncSequence` producing `UInt8` values, allowing
    /// incremental consumption of the response body.
    public let bytes: AsyncThrowingStream<UInt8, Error>

    /// HTTP response metadata.
    public let httpResponse: HTTPURLResponse

    /// HTTP status code.
    public var statusCode: Int {
        httpResponse.statusCode
    }

    /// Response headers.
    public var headers: [AnyHashable: Any] {
        httpResponse.allHeaderFields
    }

    /// Creates a new HTTP response.
    ///
    /// - Parameters:
    ///   - bytes: Streaming response bytes as an `AsyncThrowingStream<UInt8, Error>`
    ///   - httpResponse: HTTP response metadata
    public init(bytes: AsyncThrowingStream<UInt8, Error>, httpResponse: HTTPURLResponse) {
        self.bytes = bytes
        self.httpResponse = httpResponse
    }
}
