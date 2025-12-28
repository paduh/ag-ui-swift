import Foundation
import AGUICore

/// AGUITools provides utility tools and helpers
public struct AGUITools {
    private let core: AGUICore
    
    public init() {
        self.core = AGUICore()
    }
    
    /// Tools functionality example
    public func toolsFunction() -> String {
        return "AGUITools is working with \(core.coreFunction())"
    }
}

