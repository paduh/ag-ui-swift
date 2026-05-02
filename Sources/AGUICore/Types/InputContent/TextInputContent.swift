// Copyright (c) 2025 Perfect Aduh. MIT License. See LICENSE for details.

import Foundation

/// Represents a text fragment in multimodal user input.
///
/// `TextInputContent` is the simplest form of user input content, containing
/// plain text. It is used alongside ``BinaryInputContent`` to build multimodal
/// messages that combine text and binary data.
///
/// ## Type Discrimination
///
/// The `type` field is always `"text"`, enabling polymorphic deserialization
/// when InputContent arrays are decoded from JSON.
///
/// - SeeAlso: ``InputContent``, ``BinaryInputContent``, ``UserMessage``
public struct TextInputContent: InputContent {
    /// The content type discriminator (always "text").
    public let type: String

    /// The text content.
    ///
    /// This can contain:
    /// - Simple questions or statements
    /// - Multi-line text with formatting
    /// - Code snippets
    /// - Markdown
    /// - Unicode characters and emoji
    public let text: String

    /// Creates a new text content instance.
    ///
    /// - Parameter text: The text content
    public init(text: String) {
        self.type = "text"
        self.text = text
    }
}
