// Copyright (c) 2025 Perfect Aduh. MIT License. See LICENSE for details.

/// Describes why an agent run finished.
///
/// Carried by `RunFinishedEvent` and decoded from the `"outcome"` field in the
/// AG-UI wire format. Raw values match the AG-UI 1.0 wire contract.
///
/// ## Protocol version note
///
/// This SDK targets the AG-UI 1.0 wire format for outcome values (`"success"`,
/// `"cancelled"`). The `"interrupt"` outcome (human-in-the-loop) is not yet
/// modelled; streams carrying it will decode the outcome field as `.completed`
/// via the unknown-value fallback in ``RunFinishedEventDTO``. Full 1.0 interrupt
/// support is planned as a fast-follow.
public enum RunFinishedOutcome: String, Equatable, Hashable, Sendable, Codable {

    /// The run completed normally with a result (or no result).
    /// AG-UI 1.0 wire value: `"success"`.
    case completed = "success"

    /// The run was stopped before it completed, without failing.
    /// AG-UI 1.0 wire value: `"cancelled"`.
    case cancelled = "cancelled"
}
