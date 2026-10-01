import XCTest
@testable import JudgmentSplit

final class RoleAuditTests: XCTestCase {
    func testSampleTeamFlagsTwoReviewerOnlySeniors() {
        let report = RoleAudit.run(SampleTeam.contributions)
        XCTAssertEqual(Set(report.reviewerOnly), ["Marco (senior)", "Dana (senior)"])
        // Lee reviews once and writes code by hand: not flagged.
        XCTAssertFalse(report.reviewerOnly.contains("Lee"))
    }

    func testSampleTeamFlagsSearchAsDesignDelegated() throws {
        let report = RoleAudit.run(SampleTeam.contributions)
        XCTAssertEqual(report.delegatedModules, ["Search"])
        let checkout = try XCTUnwrap(report.modules.first { $0.module == "Checkout" })
        XCTAssertEqual(checkout.agentJudgmentShare, 0)
        let profile = try XCTUnwrap(report.modules.first { $0.module == "Profile" })
        XCTAssertEqual(profile.judgmentArtifacts, 4)
        XCTAssertEqual(profile.agentAuthoredJudgment, 1)
        XCTAssertEqual(profile.designDelegated, false)
    }

    func testEmptyInputProducesEmptyReport() {
        let report = RoleAudit.run([])
        XCTAssertTrue(report.engineers.isEmpty)
        XCTAssertTrue(report.modules.isEmpty)
    }

    func testModuleWithNoJudgmentArtifactsHasNilShareAndIsNotFlagged() throws {
        let report = RoleAudit.run([
            Contribution(.agent("a"), module: "Glue", kind: .implementation, action: .authored)
        ])
        let glue = try XCTUnwrap(report.modules.first)
        XCTAssertNil(glue.agentJudgmentShare)
        XCTAssertFalse(glue.designDelegated)
    }

    func testPolicyIsClampedAndThresholdIsInclusive() {
        XCTAssertEqual(AuditPolicy(minReviewsToJudge: 0, maxAgentJudgmentShare: 3).minReviewsToJudge, 1)
        XCTAssertEqual(AuditPolicy(minReviewsToJudge: 0, maxAgentJudgmentShare: 3).maxAgentJudgmentShare, 1)
        let reviews = (0..<3).map { _ in
            Contribution(.human("R"), module: "M", kind: .implementation, action: .reviewed)
        }
        XCTAssertEqual(RoleAudit.run(reviews, policy: AuditPolicy(minReviewsToJudge: 3)).reviewerOnly, ["R"])
        XCTAssertEqual(RoleAudit.run(reviews, policy: AuditPolicy(minReviewsToJudge: 4)).reviewerOnly, [])
    }

    func testAgentsAreNeverListedAsEngineers() {
        let report = RoleAudit.run(SampleTeam.contributions)
        XCTAssertFalse(report.engineers.contains { $0.name == "coding-agent" })
    }
}
