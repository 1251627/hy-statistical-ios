// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HyStatistical",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "HyStatistical", targets: ["HyStatistical"]),
    ],
    targets: [
        .target(name: "HyStatistical", path: "Sources/HyStatistical"),
        .testTarget(name: "HyStatisticalTests", dependencies: ["HyStatistical"], path: "Tests/HyStatisticalTests"),
    ]
)
