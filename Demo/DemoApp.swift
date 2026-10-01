import SwiftUI
import JudgmentSplit

@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
    }
}

/// Launch arguments used by CI to capture screenshots without UI scripting.
/// `-showAudit` opens the second tab; `-autorunOracle <0|1>` selects an
/// implementation and runs the same code path as the Run button.
enum LaunchOptions {
    static let arguments = ProcessInfo.processInfo.arguments

    static var showAudit: Bool { arguments.contains("-showAudit") }

    static var autorunImplementation: Int? {
        guard let index = arguments.firstIndex(of: "-autorunOracle") else { return nil }
        let valueIndex = arguments.index(after: index)
        guard arguments.indices.contains(valueIndex), let value = Int(arguments[valueIndex]) else { return 0 }
        return value
    }
}

struct RootView: View {
    @State private var tab = LaunchOptions.showAudit ? 1 : 0

    var body: some View {
        TabView(selection: $tab) {
            OracleScreen()
                .tabItem { Label("Oracle", systemImage: "checkmark.shield") }
                .tag(0)
            AuditScreen()
                .tabItem { Label("Role audit", systemImage: "person.3") }
                .tag(1)
        }
    }
}

// MARK: - Oracle tab

struct OracleScreen: View {
    private let reducers: [any CheckoutReducing] = [FirstDraftReducer(), ReviewedReducer()]
    @State private var selected = 0
    @State private var depth = 5
    @State private var report: OracleReport?
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Implementation", selection: $selected) {
                        Text("Agent first draft").tag(0)
                        Text("After oracle feedback").tag(1)
                    }
                    .pickerStyle(.segmented)
                    Stepper("Depth: \(depth) events", value: $depth, in: Oracle.depthRange)
                    Button("Run lead-authored oracle", action: run)
                        .accessibilityIdentifier("runOracle")
                } footer: {
                    Text("The lead wrote the seam, the four invariants and this oracle. The agent wrote the reducer.")
                }

                if let errorText {
                    Section { Text(errorText).foregroundStyle(.red) }
                }

                if let report {
                    Section("Result") {
                        LabeledContent("Traces explored", value: report.tracesExplored.formatted())
                        LabeledContent("Verdict", value: report.passed ? "PASS" : "FAIL")
                            .foregroundStyle(report.passed ? Color.green : Color.red)
                    }
                    ForEach(report.violations, id: \.invariantID) { violation in
                        Section(violation.invariantID) {
                            Text(violation.summary).font(.footnote)
                            Text(violation.readableTrace)
                                .font(.system(.caption, design: .monospaced))
                        }
                    }
                }
            }
            .navigationTitle("Judgment split")
            .onChange(of: selected) {
                // Clear a stale result, but keep one that matches the new selection.
                if reducers.indices.contains(selected), report?.implementation != reducers[selected].name {
                    report = nil
                }
            }
            .onAppear {
                if report == nil, let index = LaunchOptions.autorunImplementation,
                   reducers.indices.contains(index) {
                    selected = index
                    run()
                }
            }
        }
    }

    private func run() {
        guard reducers.indices.contains(selected) else { return }
        do {
            report = try Oracle().check(reducers[selected], depth: depth)
            errorText = nil
        } catch {
            report = nil
            errorText = "Oracle error: \(error)"
        }
    }
}

// MARK: - Role audit tab

struct AuditScreen: View {
    private let report = RoleAudit.run(SampleTeam.contributions)

    var body: some View {
        NavigationStack {
            List {
                Section("Engineers (constructed sprint)") {
                    ForEach(report.engineers, id: \.name) { e in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(e.name).bold()
                                Text("designed \(e.judgmentAuthored) · wrote \(e.otherAuthored) · reviewed \(e.reviews)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if e.reviewerOnly {
                                Text("REVIEWER-ONLY")
                                    .font(.caption2.bold())
                                    .padding(4)
                                    .background(.orange.opacity(0.2), in: Capsule())
                            }
                        }
                    }
                }
                Section("Modules") {
                    ForEach(report.modules, id: \.module) { m in
                        HStack {
                            Text(m.module).bold()
                            Spacer()
                            Text(shareText(m))
                                .font(.caption)
                                .foregroundStyle(m.designDelegated ? Color.red : Color.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Who still designs?")
        }
    }

    private func shareText(_ m: ModuleSummary) -> String {
        guard let share = m.agentJudgmentShare else { return "no design artefacts" }
        let pct = Int((share * 100).rounded())
        return m.designDelegated ? "\(pct)% of design by agent: DELEGATED" : "\(pct)% of design by agent"
    }
}
