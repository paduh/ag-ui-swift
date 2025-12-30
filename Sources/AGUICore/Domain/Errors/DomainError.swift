/// Domain errors for AG-UI protocol value objects and entities.
///
/// These errors represent violations of domain rules and invariants.
enum DomainError: Error, Equatable {
    /// Invalid thread identifier.
    case invalidThreadId(String)
    
    /// Invalid run identifier.
    case invalidRunId(String)
    
    /// Invalid timestamp value.
    case invalidTimestamp(String)
    
    /// Invalid event creation.
    case invalidEventCreation(String)
    
    /// Event does not belong to the expected stream.
    case eventDoesNotBelongToStream(String)
}
