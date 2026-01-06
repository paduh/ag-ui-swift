// HttpAgentConfiguration.swift
// AGUISwift

import Foundation

/// Configuration for HTTP agent client.
public struct HttpAgentConfiguration: Sendable {
    /// Base URL for the agent endpoint.
    public var baseURL: URL

    /// Timeout interval for requests in seconds.
    public var timeout: TimeInterval

    /// Retry policy for failed requests.
    public var retryPolicy: RetryPolicy

    /// Additional HTTP headers to include in requests.
    public var headers: [String: String]

    /// Retry policy options.
    public enum RetryPolicy: Sendable {
        /// No retry on failure.
        case none

        /// Fixed retry with maximum attempts and delay.
        case fixed(maxAttempts: Int, delay: TimeInterval)

        /// Exponential backoff retry.
        case exponentialBackoff(maxAttempts: Int, baseDelay: TimeInterval)
    }

    /// Creates a new HTTP agent configuration.
    ///
    /// - Parameters:
    ///   - baseURL: The base URL for the agent endpoint
    ///   - timeout: Request timeout in seconds (default: 120.0)
    ///   - retryPolicy: Retry policy for failures (default: .none)
    ///   - headers: Additional HTTP headers (default: empty)
    public init(
        baseURL: URL,
        timeout: TimeInterval = 120.0,
        retryPolicy: RetryPolicy = .none,
        headers: [String: String] = [:]
    ) {
        self.baseURL = baseURL
        self.timeout = timeout
        self.retryPolicy = retryPolicy
        self.headers = headers
    }
}

extension HttpAgentConfiguration {
    /// Creates a configuration with the specified base URL string.
    ///
    /// - Parameter baseURLString: The base URL string
    /// - Throws: `ClientError.invalidURL` if the URL string is invalid
    /// - Returns: A new configuration instance
    public static func create(baseURLString: String) throws -> HttpAgentConfiguration {
        guard let url = URL(string: baseURLString) else {
            throw ClientError.invalidURL
        }
        return HttpAgentConfiguration(baseURL: url)
    }
}
