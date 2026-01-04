// InputContent.swift
// AGUISwift

import Foundation

/// Base protocol for multimodal content in user messages.
///
/// `InputContent` enables users to send rich, multimodal input to agents beyond
/// simple text. The protocol supports polymorphic content types distinguished by
/// a `type` discriminator field.
///
/// ## Content Types
///
/// The AG-UI protocol defines two concrete content types:
/// - ``TextInputContent``: Plain text fragments
/// - ``BinaryInputContent``: Binary data (images, audio, documents) with MIME types
///
/// ## Polymorphic Serialization
///
/// Content types use the `type` field as a discriminator for JSON serialization:
/// - `"text"`: Deserializes to ``TextInputContent``
/// - `"binary"`: Deserializes to ``BinaryInputContent``
///
/// ## Usage in UserMessage
///
/// User messages can contain:
/// 1. **Simple text**: Single string content field
/// 2. **Multimodal**: Array of InputContent mixing text and binary data
///
/// ```swift
/// // Multimodal message with text and image
/// let contents: [any InputContent] = [
///     TextInputContent(text: "What's in this image?"),
///     BinaryInputContent(
///         mimeType: "image/png",
///         url: "https://example.com/photo.png"
///     )
/// ]
/// ```
///
/// ## Type Discrimination
///
/// The `type` property identifies the concrete content type during deserialization,
/// enabling the protocol to route JSON to the appropriate Swift type.
///
/// - SeeAlso: ``TextInputContent``, ``BinaryInputContent``, ``UserMessage``
public protocol InputContent: Sendable, Codable, Hashable {
    /// The content type discriminator.
    ///
    /// This field identifies the concrete content type:
    /// - `"text"` for ``TextInputContent``
    /// - `"binary"` for ``BinaryInputContent``
    ///
    /// The type field enables polymorphic deserialization, allowing mixed
    /// content arrays to contain different concrete types.
    var type: String { get }
}
