import Foundation

/// Adapter for converting between domain value objects and infrastructure serializable versions.
///
/// This provides a clean separation between domain and infrastructure layers,
/// allowing easy conversion between pure domain objects and their serializable
/// infrastructure counterparts.
///
/// This is an internal implementation detail used by the infrastructure layer.
enum ValueObjectAdapter {
    // MARK: - ThreadId Conversions
    
    /// Converts a domain `ThreadId` to a serializable version.
    static func toSerializable(_ domainValue: ThreadId) -> SerializableThreadId {
        return SerializableThreadId(domainValue)
    }
    
    /// Converts a serializable `ThreadId` to a domain version.
    static func toDomain(_ serializable: SerializableThreadId) -> ThreadId {
        return serializable.domainValue
    }
    
    // MARK: - RunId Conversions
    
    /// Converts a domain `RunId` to a serializable version.
    static func toSerializable(_ domainValue: RunId) -> SerializableRunId {
        return SerializableRunId(domainValue)
    }
    
    /// Converts a serializable `RunId` to a domain version.
    static func toDomain(_ serializable: SerializableRunId) -> RunId {
        return serializable.domainValue
    }
    
    // MARK: - EventTimestamp Conversions
    
    /// Converts a domain `EventTimestamp` to a serializable version.
    static func toSerializable(_ domainValue: EventTimestamp) -> SerializableEventTimestamp {
        return SerializableEventTimestamp(domainValue)
    }
    
    /// Converts a serializable `EventTimestamp` to a domain version.
    static func toDomain(_ serializable: SerializableEventTimestamp) -> EventTimestamp {
        return serializable.domainValue
    }
    
    /// Converts an optional domain `EventTimestamp` to an optional serializable version.
    static func toSerializable(_ domainValue: EventTimestamp?) -> SerializableEventTimestamp? {
        return domainValue.map { SerializableEventTimestamp($0) }
    }
    
    /// Converts an optional serializable `EventTimestamp` to an optional domain version.
    static func toDomain(_ serializable: SerializableEventTimestamp?) -> EventTimestamp? {
        return serializable.map { $0.domainValue }
    }
}
