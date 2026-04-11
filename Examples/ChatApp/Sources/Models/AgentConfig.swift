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

import AGUIAgentSDK
import Foundation

// MARK: - AgentConfig

struct AgentConfig: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var name: String
    var url: String
    var description: String?
    var systemPrompt: String?
    var authMethod: AuthMethod
    var customHeaders: [HeaderEntry]

    init(
        id: String = UUID().uuidString,
        name: String,
        url: String,
        description: String? = nil,
        systemPrompt: String? = nil,
        authMethod: AuthMethod = .none,
        customHeaders: [HeaderEntry] = []
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.description = description
        self.systemPrompt = systemPrompt
        self.authMethod = authMethod
        self.customHeaders = customHeaders
    }
}

// MARK: - HeaderEntry

struct HeaderEntry: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var key: String
    var value: String

    init(id: String = UUID().uuidString, key: String, value: String) {
        self.id = id
        self.key = key
        self.value = value
    }
}

// MARK: - AuthMethod

enum AuthMethod: Codable, Hashable, Sendable {
    case none
    case apiKey(key: String, headerName: String)
    case bearerToken(String)
    case basicAuth(username: String, password: String)
    case custom(type: String, entries: [HeaderEntry])
}

// MARK: - SDK Bridge

extension AgentConfig {
    /// Builds HTTP headers from the agent's auth method and custom headers.
    func buildHeaders() -> [String: String] {
        var headers: [String: String] = [:]
        for entry in customHeaders {
            let k = entry.key.trimmingCharacters(in: .whitespacesAndNewlines)
            let v = entry.value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !k.isEmpty { headers[k] = v }
        }
        switch authMethod {
        case .none:
            break
        case .apiKey(let key, let headerName):
            headers[headerName] = key
        case .bearerToken(let token):
            headers["Authorization"] = "Bearer \(token)"
        case .basicAuth(let username, let password):
            let credential = "\(username):\(password)"
            let encoded = Data(credential.utf8).base64EncodedString()
            headers["Authorization"] = "Basic \(encoded)"
        case .custom(_, let entries):
            for entry in entries {
                let k = entry.key.trimmingCharacters(in: .whitespacesAndNewlines)
                let v = entry.value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !k.isEmpty { headers[k] = v }
            }
        }
        return headers
    }

    /// Converts this config into a `StatefulAgUiAgentConfig`.
    /// - Throws: `AgentConfigError.invalidURL` when the URL string is malformed.
    func toStatefulAgentConfig() throws -> StatefulAgUiAgentConfig {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let agentURL = URL(string: trimmed) else {
            throw AgentConfigError.invalidURL(url)
        }
        var config = StatefulAgUiAgentConfig(baseURL: agentURL)
        config.systemPrompt = systemPrompt
        config.headers = buildHeaders()
        return config
    }
}

// MARK: - AgentConfigError

enum AgentConfigError: LocalizedError {
    case invalidURL(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid agent URL: \"\(url)\""
        }
    }
}
