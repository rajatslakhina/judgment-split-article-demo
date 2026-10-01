// A constructed two-week window for a five-person iOS team, used by the demo
// app and the tests. Not real data. Shaped on the pattern described in this
// week's HN threads: agents were given whole tickets, so the agents authored
// the seams too, and two seniors ended up approving rather than designing.

public enum SampleTeam {
    public static var contributions: [Contribution] {
        var c: [Contribution] = []
        func add(_ who: Contributor, _ module: String, _ kind: ArtifactKind, _ action: Action, _ n: Int = 1) {
            for _ in 0..<n { c.append(Contribution(who, module: module, kind: kind, action: action)) }
        }
        let agent = Contributor.agent("coding-agent")
        let priya = Contributor.human("Priya (lead)")
        let marco = Contributor.human("Marco (senior)")
        let dana = Contributor.human("Dana (senior)")
        let sam = Contributor.human("Sam")
        let lee = Contributor.human("Lee")

        // Checkout: the lead kept the seam, invariants and oracle.
        add(priya, "Checkout", .interface, .authored)
        add(priya, "Checkout", .invariant, .authored, 4)
        add(priya, "Checkout", .oracle, .authored)
        add(priya, "Checkout", .failureModes, .authored)
        add(agent, "Checkout", .implementation, .authored, 6)
        add(agent, "Checkout", .tests, .authored, 4)
        add(priya, "Checkout", .implementation, .reviewed, 3)

        // Search: whole tickets handed to the agent, seams included.
        add(agent, "Search", .interface, .authored, 2)
        add(agent, "Search", .failureModes, .authored)
        add(agent, "Search", .implementation, .authored, 9)
        add(agent, "Search", .tests, .authored, 5)
        add(marco, "Search", .implementation, .reviewed, 7)
        add(marco, "Search", .tests, .reviewed, 3)

        // Profile: mixed. One senior designs, the other only approves.
        add(dana, "Profile", .interface, .reviewed, 2)
        add(dana, "Profile", .implementation, .reviewed, 6)
        add(agent, "Profile", .interface, .authored)
        add(sam, "Profile", .interface, .authored)
        add(sam, "Profile", .invariant, .authored, 2)
        add(agent, "Profile", .implementation, .authored, 5)
        add(sam, "Profile", .implementation, .reviewed, 2)

        // A junior who is still writing code by hand.
        add(lee, "Profile", .implementation, .authored, 3)
        add(lee, "Profile", .tests, .authored, 2)
        add(lee, "Search", .implementation, .reviewed, 1)
        return c
    }
}
