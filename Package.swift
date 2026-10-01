// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "JudgmentSplit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "JudgmentSplit", targets: ["JudgmentSplit"])
    ],
    targets: [
        .target(name: "JudgmentSplit"),
        .testTarget(name: "JudgmentSplitTests", dependencies: ["JudgmentSplit"])
    ]
)
