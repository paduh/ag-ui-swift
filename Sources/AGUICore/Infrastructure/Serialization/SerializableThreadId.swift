import Foundation

/// Infrastructure wrapper for `ThreadId` that adds serialization capabilities.
///
/// This bridges the pure domain `ThreadId` value object with infrastructure
/// concerns like JSON serialization. The domain layer remains pure while
/// this layer handles serialization.
///
/// This is an internal implementation detail and should not be used directly
/// by external consumers. Use the domain `ThreadId` type instead.
struct SerializableThreadId: Codable, Hashable, Equatable {
    /// The domain value object.
    let domainValue: ThreadId
    
    /// The string value of the thread identifier.
    var value: String {
        return domainValue.value
    }
    
    /// Creates a new `SerializableThreadId` from a domain `ThreadId`.
    ///
    /// - Parameter domainValue: The domain thread identifier
    init(_ domainValue: ThreadId) {
        self.domainValue = domainValue
    }
    
    /// Creates a new `SerializableThreadId` from a string value.
    ///
    /// - Parameter value: The thread identifier string
    /// - Throws: `DomainError.invalidThreadId` if the value is invalid
    init(_ value: String) throws {
        self.domainValue = try ThreadId(value)
    }
    
    // MARK: - Codable
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        self.domainValue = try ThreadId(stringValue)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(domainValue.value)
    }
}

// MARK: - CustomStringConvertible

extension SerializableThreadId: CustomStringConvertible {
    var description: String {
        return domainValue.value
    }
}

