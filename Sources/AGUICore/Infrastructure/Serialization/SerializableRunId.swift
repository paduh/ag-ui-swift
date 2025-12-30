import Foundation

/// Infrastructure wrapper for `RunId` that adds serialization capabilities.
///
/// This bridges the pure domain `RunId` value object with infrastructure
/// concerns like JSON serialization. The domain layer remains pure while
/// this layer handles serialization.
///
/// This is an internal implementation detail and should not be used directly
/// by external integrators. Use the domain `RunId` type instead.
struct SerializableRunId: Codable, Hashable, Equatable {
    /// The domain value object.
    let domainValue: RunId
    
    /// The string value of the run identifier.
    var value: String {
        return domainValue.value
    }
    
    /// Creates a new `SerializableRunId` from a domain `RunId`.
    ///
    /// - Parameter domainValue: The domain run identifier
    init(_ domainValue: RunId) {
        self.domainValue = domainValue
    }
    
    /// Creates a new `SerializableRunId` from a string value.
    ///
    /// - Parameter value: The run identifier string
    /// - Throws: `DomainError.invalidRunId` if the value is invalid
    init(_ value: String) throws {
        self.domainValue = try RunId(value)
    }
    
    // MARK: - Codable
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        self.domainValue = try RunId(stringValue)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(domainValue.value)
    }
}

// MARK: - CustomStringConvertible

extension SerializableRunId: CustomStringConvertible {
    var description: String {
        return domainValue.value
    }
}
