// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "LifeDashboard",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "LifeDashboard",
            path: "LifeDashboard"
        ),
        .testTarget(
            name: "LifeDashboardTests",
            dependencies: ["LifeDashboard"],
            path: "LifeDashboardTests"
        ),
    ]
)
