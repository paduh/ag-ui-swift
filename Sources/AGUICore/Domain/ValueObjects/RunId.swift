/// Value object representing a run identifier in the AG-UI protocol.
///
/// A run identifier uniquely identifies a specific execution run within
/// a conversation thread. This value object enforces domain rules and
/// provides type safety.
///
/// This is a pure domain value object with no infrastructure dependencies.
public struct RunId: Hashable, Equatable {
    /// The string value of the run identifier.
    public let value: String
    
    /// Creates a new `RunId` value object.
    ///
    /// - Parameter value: The run identifier string
    /// - Throws: `DomainError.invalidRunId` if the value is empty
    public init(_ value: String) throws {
        guard !value.isEmpty else {
            throw DomainError.invalidRunId("Run ID cannot be empty")
        }
        self.value = value
    }
    
    /// Creates a `RunId` from a string value without validation.
    ///
    /// This initializer is intended for use when the value is already
    /// known to be valid (e.g., when deserializing from trusted sources).
    ///
    /// - Parameter value: The run identifier string
    internal init(unvalidated value: String) {
        self.value = value
    }
}
