// HTTPClient.swift
// AGUISwift

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
public struct HTTPResponse: Sendable {
    /// Streaming response bytes.
    public let bytes: URLSession.AsyncBytes

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
    ///   - bytes: Streaming response bytes
    ///   - httpResponse: HTTP response metadata
    public init(bytes: URLSession.AsyncBytes, httpResponse: HTTPURLResponse) {
        self.bytes = bytes
        self.httpResponse = httpResponse
    }
}
