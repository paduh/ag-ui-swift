// AGUITools.swift
// AGUISwift

import AGUICore
import Foundation

/// AGUITools provides utility tools and helpers
public struct AGUITools {
    private let core: AGUICore

    public init() {
        self.core = AGUICore()
    }

    /// Tools functionality example
    public func toolsFunction() -> String {
        "AGUITools is working with \(core.coreFunction())"
    }
}
