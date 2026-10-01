// The team-level half of the argument. Given who authored and who reviewed
// which artefacts over a window, find the engineers whose job has quietly
// become "approve what the agent wrote" and the modules whose design was
// delegated along with the typing.

/// What kind of artefact a contribution touched.
public enum ArtifactKind: String, CaseIterable, Sendable, Hashable {
    case interface, invariant, oracle, failureModes
    case implementation, tests, glue

    /// The four artefacts that encode design judgment. Everything else can be
    /// generated against them and checked by them.
    public var carriesJudgment: Bool {
        switch self {
        case .interface, .invariant, .oracle, .failureModes: return true
        case .implementation, .tests, .glue: return false
        }
    }
}

public enum Contributor: Sendable, Hashable {
    case human(String)
    case agent(String)
}

public enum Action: String, Sendable, Hashable { case authored, reviewed }

public struct Contribution: Sendable, Hashable {
    public let contributor: Contributor
    public let module: String
    public let kind: ArtifactKind
    public let action: Action

    public init(_ contributor: Contributor, module: String, kind: ArtifactKind, action: Action) {
        self.contributor = contributor
        self.module = module
        self.kind = kind
        self.action = action
    }
}

/// Thresholds are data, not code, so a lead can argue about them in a PR.
public struct AuditPolicy: Sendable, Equatable {
    /// An engineer with at least this many reviews and zero judgment artefacts
    /// authored in the window is flagged as reviewer-only.
    public var minReviewsToJudge: Int
    /// A module whose judgment artefacts were more than this fraction
    /// agent-authored is flagged as design-delegated. 0.0...1.0.
    public var maxAgentJudgmentShare: Double

    public init(minReviewsToJudge: Int = 5, maxAgentJudgmentShare: Double = 0.5) {
        self.minReviewsToJudge = max(1, minReviewsToJudge)
        self.maxAgentJudgmentShare = min(1, max(0, maxAgentJudgmentShare))
    }
}

public struct EngineerSummary: Sendable, Hashable {
    public let name: String
    public let judgmentAuthored: Int
    public let otherAuthored: Int
    public let reviews: Int
    public let reviewerOnly: Bool
}

public struct ModuleSummary: Sendable, Hashable {
    public let module: String
    public let judgmentArtifacts: Int
    public let agentAuthoredJudgment: Int
    /// nil when the module has no judgment artefacts at all, which is its own problem.
    public let agentJudgmentShare: Double?
    public let designDelegated: Bool
}

public struct AuditReport: Sendable {
    public let engineers: [EngineerSummary]
    public let modules: [ModuleSummary]
    public var reviewerOnly: [String] { engineers.filter(\.reviewerOnly).map(\.name) }
    public var delegatedModules: [String] { modules.filter(\.designDelegated).map(\.module) }
}

public enum RoleAudit {
    public static func run(_ contributions: [Contribution], policy: AuditPolicy = AuditPolicy()) -> AuditReport {
        var judgment: [String: Int] = [:]
        var other: [String: Int] = [:]
        var reviews: [String: Int] = [:]
        var names: [String] = []

        var moduleJudgment: [String: Int] = [:]
        var moduleAgentJudgment: [String: Int] = [:]
        var modules: [String] = []

        for c in contributions {
            if moduleJudgment[c.module] == nil {
                moduleJudgment[c.module] = 0
                modules.append(c.module)
            }
            if c.action == .authored && c.kind.carriesJudgment {
                moduleJudgment[c.module, default: 0] += 1
                if case .agent = c.contributor { moduleAgentJudgment[c.module, default: 0] += 1 }
            }

            guard case .human(let name) = c.contributor else { continue }
            if judgment[name] == nil && other[name] == nil && reviews[name] == nil { names.append(name) }
            switch (c.action, c.kind.carriesJudgment) {
            case (.authored, true): judgment[name, default: 0] += 1
            case (.authored, false): other[name, default: 0] += 1
            case (.reviewed, _): reviews[name, default: 0] += 1
            }
        }

        let engineers = names.map { name -> EngineerSummary in
            let j = judgment[name] ?? 0
            let r = reviews[name] ?? 0
            return EngineerSummary(name: name, judgmentAuthored: j, otherAuthored: other[name] ?? 0,
                                   reviews: r, reviewerOnly: j == 0 && r >= policy.minReviewsToJudge)
        }

        let moduleSummaries = modules.map { module -> ModuleSummary in
            let total = moduleJudgment[module] ?? 0
            let byAgent = moduleAgentJudgment[module] ?? 0
            let share: Double? = total == 0 ? nil : Double(byAgent) / Double(total)
            let delegated = share.map { $0 > policy.maxAgentJudgmentShare } ?? false
            return ModuleSummary(module: module, judgmentArtifacts: total, agentAuthoredJudgment: byAgent,
                                 agentJudgmentShare: share, designDelegated: delegated)
        }

        return AuditReport(engineers: engineers, modules: moduleSummaries)
    }
}
