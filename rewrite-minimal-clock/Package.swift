// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FloatingClockMac",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "FloatingClockMac",
            targets: ["FloatingClockMac"]
        )
    ],
    targets: [
        .executableTarget(
            name: "FloatingClockMac",
            path: "Sources/FloatingClockApp"
        )
    ]
)
