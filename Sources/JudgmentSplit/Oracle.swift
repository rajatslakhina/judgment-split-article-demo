// LEAD-AUTHORED. The pass/fail oracle. It does not read the implementation;
// it drives it through every event sequence up to a bounded depth and checks
// each invariant against each trace. Breadth-first, so the first
// counterexample recorded for an invariant is a shortest one.

public struct Violation: Sendable, Hashable {
    public let invariantID: String
    public let summary: String
    /// The shortest trace found that breaks the invariant.
    public let counterexample: [Step]

    /// e.g. "browsing -confirmCart-> cartConfirmed -tapPay-> paying [charge]"
    public var readableTrace: String {
        guard let first = counterexample.first else { return "(empty trace)" }
        var text = first.from.rawValue
        for step in counterexample {
            text += " -\(step.event.rawValue)-> \(step.to.rawValue)"
            if !step.effects.isEmpty {
                text += " [" + step.effects.map(\.rawValue).joined(separator: ", ") + "]"
            }
        }
        return text
    }
}

public struct OracleReport: Sendable {
    public let implementation: String
    public let depth: Int
    public let tracesExplored: Int
    public let violations: [Violation]
    public var passed: Bool { violations.isEmpty }
}

public enum OracleError: Error, Equatable {
    case depthOutOfRange(Int)
}

public struct Oracle: Sendable {
    public static let depthRange = 1...6

    public let invariants: [Invariant]
    public let events: [CheckoutEvent]
    public let initial: CheckoutState

    public init(
        invariants: [Invariant] = CheckoutInvariants.all,
        events: [CheckoutEvent] = CheckoutEvent.allCases,
        initial: CheckoutState = .browsing
    ) {
        self.invariants = invariants
        self.events = events
        self.initial = initial
    }

    /// Explores every event sequence of length 1...depth.
    /// Depth is capped because the trace count grows as events^depth
    /// (7 events at depth 5 is 19,607 traces; depth 6 is 137,256).
    public func check(_ reducer: any CheckoutReducing, depth: Int = 5) throws -> OracleReport {
        guard Oracle.depthRange.contains(depth) else { throw OracleError.depthOutOfRange(depth) }

        var frontier: [[Step]] = [[]]
        var explored = 0
        var firstFailure: [String: [Step]] = [:]

        for _ in 0..<depth {
            var next: [[Step]] = []
            next.reserveCapacity(frontier.count * events.count)
            for trace in frontier {
                let current = trace.last?.to ?? initial
                for event in events {
                    let transition = reducer.reduce(current, event)
                    let extended = trace + [Step(from: current, event: event,
                                                 to: transition.state, effects: transition.effects)]
                    explored += 1
                    for invariant in invariants where firstFailure[invariant.id] == nil {
                        if !invariant.holds(extended) { firstFailure[invariant.id] = extended }
                    }
                    next.append(extended)
                }
            }
            frontier = next
        }

        let violations = invariants.compactMap { invariant -> Violation? in
            guard let trace = firstFailure[invariant.id] else { return nil }
            return Violation(invariantID: invariant.id, summary: invariant.summary, counterexample: trace)
        }
        return OracleReport(implementation: reducer.name, depth: depth,
                            tracesExplored: explored, violations: violations)
    }
}
