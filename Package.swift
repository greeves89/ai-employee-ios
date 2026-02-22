// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AIEmployee",
    platforms: [
        .iOS(.v26)
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
            path: "Sources/AIEmployee"
        )
    ]
)
