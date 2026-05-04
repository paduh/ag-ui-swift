// Copyright (c) 2025 Perfect Aduh. MIT License. See LICENSE for details.

import Foundation

/// A message containing system-level instructions and configuration.
///
/// Developer messages provide system-level instructions, configuration, and
/// administrative communication that differs from regular system prompts. They
/// typically contain meta-instructions about how the agent should behave or
/// technical configuration details.
///
public struct DeveloperMessage: Message, Sendable, Hashable {
    /// Unique identifier for this message.
    public let id: String

    /// The role of this message (always `.developer`).
    public let role: Role

    /// The developer's message content.
    ///
    /// This typically contains system-level instructions, configuration details,
    /// or meta-instructions about agent behavior.
    ///
    /// While the protocol allows optional content, developer messages in practice
    /// always contain content, so the initializer requires a non-nil value.
    public let content: String?

    /// Optional identifier for the developer or system.
    ///
    /// This can be used to identify which developer, system component, or
    /// configuration module generated the message.
    public let name: String?

    /// Optional encrypted value associated with this message.
    ///
    /// When present, carries a cryptographic value produced by the agent's
    /// reasoning process.
    public let encryptedValue: String?

    /// Creates a new developer message.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for this message
    ///   - content: The developer's message content
    ///   - name: Optional identifier for the developer or system
    ///   - encryptedValue: Optional encrypted reasoning value
    public init(
        id: String,
        content: String,
        name: String? = nil,
        encryptedValue: String? = nil
    ) {
        self.id = id
        self.role = .developer
        self.content = content
        self.name = name
        self.encryptedValue = encryptedValue
    }
}

// MARK: - Decodable

extension DeveloperMessage: Decodable {
    private enum CodingKeys: String, CodingKey {
        case id
        case content
        case name
        case encryptedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        role = .developer
        content = try container.decode(String.self, forKey: .content)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        encryptedValue = try container.decodeIfPresent(String.self, forKey: .encryptedValue)
    }
}
