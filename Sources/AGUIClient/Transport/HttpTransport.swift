// HttpTransport.swift
// AGUISwift

import AGUICore
import Foundation

/// Low-level HTTP transport using URLSession.
///
/// `HttpTransport` is an actor that provides thread-safe access to URLSession
/// and handles the HTTP communication with AG-UI agents.
///
/// ## Example
///
/// ```swift
/// let config = HttpAgentConfiguration(baseURL: agentURL)
/// let transport = HttpTransport(configuration: config)
///
/// let bytes = try await transport.execute(endpoint: "/run", input: input)
/// for try await byte in bytes {
///     // Process streaming response
/// }
/// ```
public actor HttpTransport {
    private let session: URLSession
    private let configuration: HttpAgentConfiguration

    /// Creates a new HTTP transport with the specified configuration.
    ///
    /// - Parameter configuration: The HTTP agent configuration
    public init(configuration: HttpAgentConfiguration) {
        self.configuration = configuration

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeout
        sessionConfig.timeoutIntervalForResource = configuration.timeout

        // Set additional headers
        var headers = configuration.headers
        headers["User-Agent"] = "AGUISwift/1.0"
        sessionConfig.httpAdditionalHeaders = headers

        self.session = URLSession(configuration: sessionConfig)
    }

    /// Executes an HTTP request and returns streaming bytes.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint path (e.g., "/run")
    ///   - input: The run agent input to send
    /// - Returns: An async sequence of bytes from the server
    /// - Throws: `ClientError` if the request fails
    public func execute(
        endpoint: String,
        input: RunAgentInput
    ) async throws -> URLSession.AsyncBytes {
        // Construct URL
        let url = configuration.baseURL.appendingPathComponent(endpoint)

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

        // Encode RunAgentInput to JSON
        let encoder = JSONEncoder()
        do {
            request.httpBody = try encoder.encode(input)
        } catch {
            throw ClientError.decodingError(error)
        }

        // Execute request
        let (bytes, response): (URLSession.AsyncBytes, URLResponse)
        do {
            (bytes, response) = try await session.bytes(for: request)
        } catch let error as URLError {
            throw mapURLError(error)
        } catch {
            throw ClientError.networkError(error)
        }

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClientError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw ClientError.httpError(statusCode: httpResponse.statusCode)
        }

        return bytes
    }

    /// Maps URLError to ClientError.
    private func mapURLError(_ error: URLError) -> ClientError {
        switch error.code {
        case .timedOut:
            return .timeout
        case .cancelled:
            return .cancelled
        default:
            return .networkError(error)
        }
    }
}
