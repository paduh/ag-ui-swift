import Foundation

/// Infrastructure wrapper for `EventTimestamp` that adds serialization and Date conversion capabilities.
///
/// This bridges the pure domain `EventTimestamp` value object with infrastructure
/// concerns like JSON serialization and Date conversion. The domain layer remains
/// pure while this layer handles infrastructure concerns.
///
/// This is an internal implementation detail and should not be used directly
/// by external integrators. Use the domain `EventTimestamp` type instead.
struct SerializableEventTimestamp: Codable, Equatable, Comparable {
    /// The domain value object.
    let domainValue: EventTimestamp
    
    /// The timestamp value in milliseconds since the Unix epoch.
    var millisecondsSinceEpoch: Int64 {
        return domainValue.millisecondsSinceEpoch
    }
    
    /// Creates a new `SerializableEventTimestamp` from a domain `EventTimestamp`.
    ///
    /// - Parameter domainValue: The domain timestamp
    init(_ domainValue: EventTimestamp) {
        self.domainValue = domainValue
    }
    
    /// Creates a new `SerializableEventTimestamp` from milliseconds since epoch.
    ///
    /// - Parameter millisecondsSinceEpoch: Milliseconds since January 1, 1970
    init(millisecondsSinceEpoch: Int64) {
        self.domainValue = EventTimestamp(millisecondsSinceEpoch: millisecondsSinceEpoch)
    }
    
    /// Creates a new `SerializableEventTimestamp` from a `Date` object.
    ///
    /// - Parameter date: The date to convert to milliseconds since epoch
    init(date: Date) {
        self.domainValue = EventTimestamp(millisecondsSinceEpoch: Int64(date.timeIntervalSince1970 * 1000))
    }
    
    /// Creates a new `SerializableEventTimestamp` representing the current time.
    static func now() -> SerializableEventTimestamp {
        return SerializableEventTimestamp(date: Date())
    }
    
    /// Converts the timestamp to a `Date` object.
    var date: Date {
        return Date(timeIntervalSince1970: TimeInterval(domainValue.millisecondsSinceEpoch) / 1000)
    }
    
    /// Converts the timestamp to seconds since epoch (as `TimeInterval`).
    var timeIntervalSince1970: TimeInterval {
        return TimeInterval(domainValue.millisecondsSinceEpoch) / 1000
    }
    
    // MARK: - Comparable
    
    static func < (lhs: SerializableEventTimestamp, rhs: SerializableEventTimestamp) -> Bool {
        return lhs.domainValue < rhs.domainValue
    }
    
    // MARK: - Codable
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let milliseconds = try container.decode(Int64.self)
        self.domainValue = EventTimestamp(millisecondsSinceEpoch: milliseconds)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(domainValue.millisecondsSinceEpoch)
    }
}

// MARK: - CustomStringConvertible

extension SerializableEventTimestamp: CustomStringConvertible {
    var description: String {
        return "\(domainValue.millisecondsSinceEpoch)ms"
    }
}
