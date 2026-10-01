import XCTest
@testable import JudgmentSplit

final class OracleTests: XCTestCase {
    func testFirstDraftBreaksThreeInvariantsWithShortestCounterexamples() throws {
        // Two bugs, three broken rules: the double tap breaks both
        // no-double-charge and charge-only-from-confirmed-cart.
        let report = try Oracle().check(FirstDraftReducer(), depth: 5)
        XCTAssertFalse(report.passed)
        XCTAssertEqual(Set(report.violations.map(\.invariantID)),
                       ["no-double-charge", "paying-exits-only-on-outcome", "charge-only-from-confirmed-cart"])
        XCTAssertFalse(report.violations.contains { $0.invariantID == "refund-only-after-paid" })

        let source = try XCTUnwrap(report.violations.first { $0.invariantID == "charge-only-from-confirmed-cart" })
        XCTAssertEqual(source.counterexample.map(\.event), [.confirmCart, .tapPay, .tapPay])

        let double = try XCTUnwrap(report.violations.first { $0.invariantID == "no-double-charge" })
        XCTAssertEqual(double.counterexample.map(\.event), [.confirmCart, .tapPay, .tapPay])
        XCTAssertEqual(double.readableTrace,
                       "browsing -confirmCart-> cartConfirmed -tapPay-> paying [charge] -tapPay-> paying [charge]")

        let abandon = try XCTUnwrap(report.violations.first { $0.invariantID == "paying-exits-only-on-outcome" })
        XCTAssertEqual(abandon.counterexample.map(\.event), [.confirmCart, .tapPay, .editCart])
    }

    func testReviewedReducerPassesEveryInvariantAtMaxDepth() throws {
        let report = try Oracle().check(ReviewedReducer(), depth: Oracle.depthRange.upperBound)
        XCTAssertTrue(report.passed, "\(report.violations.map(\.readableTrace))")
    }

    func testTraceCountIsSumOfPowers() throws {
        let report = try Oracle().check(ReviewedReducer(), depth: 5)
        // 7 + 49 + 343 + 2401 + 16807
        XCTAssertEqual(report.tracesExplored, 19_607)
        let six = try Oracle().check(ReviewedReducer(), depth: 6)
        XCTAssertEqual(six.tracesExplored, 137_256)
    }

    func testDeclinedChargeThenRetryIsNotADoubleCharge() {
        let steps = [
            Step(from: .cartConfirmed, event: .tapPay, to: .paying, effects: [.charge]),
            Step(from: .paying, event: .paymentFailed, to: .failed, effects: []),
            Step(from: .failed, event: .retry, to: .paying, effects: [.charge])
        ]
        XCTAssertTrue(CheckoutInvariants.noDoubleCharge.holds(steps))
    }

    func testDepthBoundsAreEnforced() {
        XCTAssertThrowsError(try Oracle().check(ReviewedReducer(), depth: 0)) {
            XCTAssertEqual($0 as? OracleError, .depthOutOfRange(0))
        }
        XCTAssertThrowsError(try Oracle().check(ReviewedReducer(), depth: 7)) {
            XCTAssertEqual($0 as? OracleError, .depthOutOfRange(7))
        }
    }

    func testDepthTwoIsTooShallowToSeeEitherBug() throws {
        // Both bugs need three events. A shallow oracle is a false sense of safety.
        let report = try Oracle().check(FirstDraftReducer(), depth: 2)
        XCTAssertTrue(report.passed)
    }

    func testEmptyTraceRendersSafely() {
        let v = Violation(invariantID: "x", summary: "", counterexample: [])
        XCTAssertEqual(v.readableTrace, "(empty trace)")
    }
}
