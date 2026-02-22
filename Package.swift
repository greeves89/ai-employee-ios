// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AIEmployee",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .executable(
            name: "AIEmployee",
            targets: ["AIEmployee"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "AIEmployee",
            path: "Sources/AIEmployee",
            resources: []
        )
    ]
)
