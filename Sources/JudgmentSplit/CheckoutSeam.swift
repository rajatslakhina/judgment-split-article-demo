// LEAD-AUTHORED. This file is the seam: the vocabulary of the checkout flow
// and the one protocol an implementation must satisfy. An agent may write a
// reducer against it; it does not get to change it.

/// Where the checkout flow is.
public enum CheckoutState: String, CaseIterable, Sendable, Hashable {
    case browsing, cartConfirmed, paying, paid, failed, refunded
}

/// What can happen to the flow: user taps and payment-provider callbacks.
public enum CheckoutEvent: String, CaseIterable, Sendable, Hashable {
    case confirmCart, editCart, tapPay, paymentSucceeded, paymentFailed, retry, requestRefund
}

/// Side effects the reducer asks the app to perform.
public enum CheckoutEffect: String, Sendable, Hashable {
    case charge, refund
}

/// The result of applying one event.
public struct Transition: Sendable, Hashable {
    public let state: CheckoutState
    public let effects: [CheckoutEffect]

    public init(_ state: CheckoutState, effects: [CheckoutEffect] = []) {
        self.state = state
        self.effects = effects
    }
}

/// The contract every checkout implementation is written against.
public protocol CheckoutReducing: Sendable {
    var name: String { get }
    func reduce(_ state: CheckoutState, _ event: CheckoutEvent) -> Transition
}
