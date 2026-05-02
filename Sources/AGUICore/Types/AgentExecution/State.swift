// Copyright (c) 2025 Perfect Aduh. MIT License. See LICENSE for details.

import Foundation

/// Represents agent state as JSON data.
///
/// State is a type alias for `Data` that represents arbitrary JSON-formatted state
/// information passed to and from agents during execution. The state can contain
/// any JSON-serializable data structure including objects, arrays, primitives, and null.
///
public typealias State = Data
