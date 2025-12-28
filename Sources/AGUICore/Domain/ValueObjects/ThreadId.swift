/// Value object representing a thread identifier in the AG-UI protocol.
///
/// A thread identifier uniquely identifies a conversation thread between
/// a client and an agent. This value object enforces domain rules and
/// provides type safety.
///
/// This is a pure domain value object with no infrastructure dependencies.
public struct ThreadId: Hashable, Equatable {
    /// The string value of the thread identifier.
    public let value: String
    
    /// Creates a new `ThreadId` value object.
    ///
    /// - Parameter value: The thread identifier string
    /// - Throws: `DomainError.invalidThreadId` if the value is empty
    public init(_ value: String) throws {
        guard !value.isEmpty else {
            throw DomainError.invalidThreadId("Thread ID cannot be empty")
        }
        self.value = value
    }
    
    /// Creates a `ThreadId` from a string value without validation.
    ///
    /// This initializer is intended for use when the value is already
    /// known to be valid (e.g., when deserializing from trusted sources).
    ///
    /// - Parameter value: The thread identifier string
    internal init(unvalidated value: String) {
        self.value = value
    }
}

