// AGENT-AUTHORED (constructed for the demo). Two implementations of the seam.
// FirstDraftReducer reads well in review: every case is handled, nothing
// force-unwraps, the happy path is right. It still has two bugs that only
// show up as sequences, which is exactly what the oracle checks.

public struct FirstDraftReducer: CheckoutReducing {
    public let name = "Agent first draft"
    public init() {}

    public func reduce(_ state: CheckoutState, _ event: CheckoutEvent) -> Transition {
        switch (state, event) {
        case (.browsing, .confirmCart): return Transition(.cartConfirmed)
        case (.cartConfirmed, .editCart): return Transition(.browsing)
        case (.cartConfirmed, .tapPay): return Transition(.paying, effects: [.charge])
        // Bug 1: a second tap while the charge is in flight charges again.
        case (.paying, .tapPay): return Transition(.paying, effects: [.charge])
        // Bug 2: editing the cart abandons an in-flight charge.
        case (.paying, .editCart): return Transition(.browsing)
        case (.paying, .paymentSucceeded): return Transition(.paid)
        case (.paying, .paymentFailed): return Transition(.failed)
        case (.failed, .retry): return Transition(.paying, effects: [.charge])
        case (.failed, .editCart): return Transition(.browsing)
        case (.paid, .requestRefund): return Transition(.refunded, effects: [.refund])
        default: return Transition(state)
        }
    }
}

public struct ReviewedReducer: CheckoutReducing {
    public let name = "Agent after oracle feedback"
    public init() {}

    public func reduce(_ state: CheckoutState, _ event: CheckoutEvent) -> Transition {
        switch (state, event) {
        case (.browsing, .confirmCart): return Transition(.cartConfirmed)
        case (.cartConfirmed, .editCart): return Transition(.browsing)
        case (.cartConfirmed, .tapPay): return Transition(.paying, effects: [.charge])
        case (.paying, .paymentSucceeded): return Transition(.paid)
        case (.paying, .paymentFailed): return Transition(.failed)
        case (.failed, .retry): return Transition(.paying, effects: [.charge])
        case (.failed, .editCart): return Transition(.browsing)
        case (.paid, .requestRefund): return Transition(.refunded, effects: [.refund])
        default: return Transition(state)
        }
    }
}
