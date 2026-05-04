// Copyright (c) 2025 Perfect Aduh. MIT License. See LICENSE for details.

import Foundation

/// Represents a structured activity update in the conversation.
///
/// `ActivityMessage` enables agents to stream dynamic UI elements, progress indicators,
/// A2UI surfaces, and other structured content beyond simple text messages.
///
/// ## Activity Types
///
/// The `activityType` field identifies the kind of activity:
/// - **Progress**: Progress indicators and status updates
/// - **Visualization**: Charts, graphs, and data visualizations
/// - **A2UI Surface**: Interactive UI components (forms, buttons, etc.)
/// - **Status**: System status and state updates
/// - **Custom**: Application-specific activity types
///
/// ## Content
///
/// The `content` field stores flexible JSON data as a `Data` object,
/// allowing each activity type to define its own content structure.
///
public struct ActivityMessage: Message, Sendable, Hashable {
    /// The unique identifier for this message.
    public let id: String

    /// The message role (always `.activity`).
    public let role: Role

    /// The type of activity being reported.
    ///
    /// Common activity types:
    /// - `"progress"`: Progress indicators and completion status
    /// - `"chart"`: Data visualizations and charts
    /// - `"a2ui-form"`: Interactive form surfaces
    /// - `"status"`: System status updates
    /// - Custom application-specific types
    public let activityType: String

    /// The structured activity content as JSON data.
    ///
    /// This field contains a JSON object with activity-specific data.
    /// The structure varies based on the `activityType`.
    public let content: Data

    /// Optional sender name (always `nil` for activity messages).
    public let name: String? = nil

    /// Encrypted value (always `nil` for activity messages).
    ///
    /// The AG-UI protocol does not define `encryptedValue` for activity messages.
    public let encryptedValue: String? = nil

    /// Creates a new activity message.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the message
    ///   - activityType: The type of activity
    ///   - content: JSON data representing the activity content
    public init(
        id: String,
        activityType: String,
        content: Data
    ) {
        self.id = id
        self.role = .activity
        self.activityType = activityType
        self.content = content
    }
}
