// swift-tools-version: 5.9
import PackageDescription

// Forked from TelemetryDeck's SwiftSDK 2.14.2 (commit 58f4362); see README.md.
let package = Package(
    name: "Nozoki",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v12),
        .watchOS(.v5),
        .tvOS(.v13),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "Nozoki", targets: ["Nozoki"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Nozoki",
            resources: [.copy("PrivacyInfo.xcprivacy")],
            swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
        ),
        .testTarget(
            name: "NozokiTests",
            dependencies: ["Nozoki"],
            swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
        ),
    ]
)
