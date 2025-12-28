/// Value object representing an event timestamp in the AG-UI protocol.
///
/// Timestamps are represented as milliseconds since the Unix epoch (January 1, 1970).
/// This value object provides a domain-focused API for working with timestamps
/// while maintaining protocol compliance.
///
/// This is a pure domain value object with no infrastructure dependencies.
/// Date conversion utilities are provided in the infrastructure layer.
public struct EventTimestamp: Equatable, Comparable {
    /// The timestamp value in milliseconds since the Unix epoch.
    public let millisecondsSinceEpoch: Int64
    
    /// Creates a new `EventTimestamp` from milliseconds since epoch.
    ///
    /// - Parameter millisecondsSinceEpoch: Milliseconds since January 1, 1970
    public init(millisecondsSinceEpoch: Int64) {
        self.millisecondsSinceEpoch = millisecondsSinceEpoch
    }
    
    // MARK: - Comparable
    
    public static func < (lhs: EventTimestamp, rhs: EventTimestamp) -> Bool {
        return lhs.millisecondsSinceEpoch < rhs.millisecondsSinceEpoch
    }
}

