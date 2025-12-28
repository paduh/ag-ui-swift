import Foundation
import AGUICore

/// AGUIClient provides client-side functionality
public struct AGUIClient {
    private let core: AGUICore
    
    public init() {
        self.core = AGUICore()
    }
    
    /// Client functionality example
    public func clientFunction() -> String {
        return "AGUIClient is working with \(core.coreFunction())"
    }
}

