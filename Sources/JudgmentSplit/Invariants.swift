// LEAD-AUTHORED. The failure-mode list, written as checkable predicates over a
// whole trace rather than as review comments. Each one names a bug that a
// reviewer reading a plausible-looking switch statement tends to miss.

/// One step of an explored trace.
public struct Step: Sendable, Hashable {
    public let from: CheckoutState
    public let event: CheckoutEvent
    public let to: CheckoutState
    public let effects: [CheckoutEffect]
}

/// A named rule that must hold for every reachable trace.
public struct Invariant: Sendable {
    public let id: String
    public let summary: String
    /// Returns true when the trace is acceptable.
    public let holds: @Sendable ([Step]) -> Bool

    public init(id: String, summary: String, holds: @escaping @Sendable ([Step]) -> Bool) {
        self.id = id
        self.summary = summary
        self.holds = holds
    }
}

public enum CheckoutInvariants {
    /// The customer never has two live charges at once. A charge stops being
    /// live when the provider declines it or when it is refunded.
    public static let noDoubleCharge = Invariant(
        id: "no-double-charge",
        summary: "At most one live charge: a second .charge needs a decline or a .refund first."
    ) { steps in
        var outstanding = 0
        for step in steps {
            if step.from == .paying && step.event == .paymentFailed && step.to == .failed {
                outstanding = max(0, outstanding - 1)
            }
            for effect in step.effects {
                switch effect {
                case .charge:
                    outstanding += 1
                    if outstanding > 1 { return false }
                case .refund:
                    outstanding = max(0, outstanding - 1)
                }
            }
        }
        return true
    }

    /// While a charge is in flight, only the provider's answer may move the flow.
    public static let payingExitsOnlyOnOutcome = Invariant(
        id: "paying-exits-only-on-outcome",
        summary: "From .paying, only .paymentSucceeded or .paymentFailed may change state."
    ) { steps in
        for step in steps where step.from == .paying && step.to != .paying {
            if step.event != .paymentSucceeded && step.event != .paymentFailed { return false }
        }
        return true
    }

    /// Money only moves from a confirmed cart (or a retry of one that failed).
    public static let chargeOnlyFromConfirmedCart = Invariant(
        id: "charge-only-from-confirmed-cart",
        summary: "A .charge is only emitted from .cartConfirmed or .failed."
    ) { steps in
        for step in steps where step.effects.contains(.charge) {
            if step.from != .cartConfirmed && step.from != .failed { return false }
        }
        return true
    }

    /// A refund is only issued for a payment that actually succeeded.
    public static let refundOnlyAfterPaid = Invariant(
        id: "refund-only-after-paid",
        summary: "A .refund is only emitted from .paid."
    ) { steps in
        for step in steps where step.effects.contains(.refund) {
            if step.from != .paid { return false }
        }
        return true
    }

    public static let all: [Invariant] = [
        noDoubleCharge, payingExitsOnlyOnOutcome, chargeOnlyFromConfirmedCart, refundOnlyAfterPaid
    ]
}
